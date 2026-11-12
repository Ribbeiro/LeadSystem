part of 'app_state.dart';

/// Opção de frete (PAC/SEDEX). [estimated] = valor estimado por região,
/// sem cotação oficial dos Correios.
class ShippingOption {
  const ShippingOption({
    required this.service,
    required this.price,
    required this.days,
    this.estimated = true,
  });

  final String service;
  final double price;
  final int days;
  final bool estimated;
}

/// Sincronização com a API (server/). O app é "offline first": tudo é
/// gravado localmente e as alterações entram numa fila (outbox) enviada
/// quando há conexão. Sem servidor configurado, o app funciona só no
/// aparelho, como antes.
extension AppStateSync on AppState {
  bool get onlineMode => _api != null;
  bool get hasPendingSync => _outbox.isNotEmpty;
  int get pendingSyncCount => _outbox.length;

  // ------------------------------------------------------------ servidor

  /// Define (ou remove, com url vazia) o endereço da API. Devolve false se o
  /// servidor não respondeu ao /health.
  Future<bool> configureServer(String? url) async {
    final value = ApiClient.normalizeUrl(url ?? '');
    if (value.isEmpty) {
      _stopAutoSync();
      _api?.close();
      _api = null;
      apiUrl = null;
      _apiToken = null;
      syncMessage = null;
      _changed();
      return true;
    }
    final client = ApiClient(value, client: _httpClient);
    if (!await client.health()) {
      syncMessage = 'Servidor não respondeu em $value.';
      _notify();
      return false;
    }
    _api = client..token = _apiToken;
    apiUrl = value;
    syncMessage = 'Conectado a $value.';
    _changed();
    await syncNow();
    _startAutoSync();
    return true;
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    if (_api == null) return;
    _syncTimer = Timer.periodic(AppState.syncInterval, (_) => syncNow());
  }

  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Retoma/pausa a sincronização automática (app em primeiro/segundo plano).
  void setForeground(bool foreground) {
    if (foreground) {
      _startAutoSync();
      unawaited(syncNow());
    } else {
      _stopAutoSync();
    }
  }

  /// Envia a fila de alterações e busca dados novos do servidor. Chamadas
  /// durante uma sincronização em andamento aguardam e disparam mais uma
  /// rodada, para que nada criado nesse meio-tempo fique para trás.
  Future<void> syncNow() {
    if (_api == null || _disposed) return Future.value();
    final running = _syncRun;
    if (running != null) {
      _syncAgain = true;
      return running;
    }
    final run = _runSyncLoop().whenComplete(() => _syncRun = null);
    _syncRun = run;
    return run;
  }

  Future<void> _runSyncLoop() async {
    do {
      _syncAgain = false;
      await _syncOnce();
    } while (_syncAgain && !_disposed);
  }

  Future<void> _syncOnce() async {
    final api = _api;
    if (api == null || _disposed) return;
    syncing = true;
    _notify();
    try {
      await _flushOutbox(api);
      await _pull(api);
      lastSyncAt = DateTime.now();
      syncMessage = null;
    } on ApiException catch (error) {
      syncMessage = error.isNetwork
          ? 'Sem conexão com o servidor. Alterações ficam salvas no aparelho.'
          : error.message;
      if (error.statusCode == 401) {
        // Token expirado: mantém os dados e pede novo login.
        _apiToken = null;
        api.token = null;
        syncMessage = 'Sessão expirada. Entre novamente para sincronizar.';
      }
    } finally {
      syncing = false;
      _changed();
    }
  }

  // ------------------------------------------------------------ autenticação

  /// Login na API. Devolve null quando o servidor está inacessível (o
  /// chamador tenta o login local).
  Future<bool?> _remoteLogin(String email, String password, bool remember) =>
      _remoteAuth(
        () => _api!.post('/api/auth/login', {
          'email': email,
          'password': password,
        }),
        password,
        remember,
      );

  Future<bool?> _remoteAuth(
    Future<Map<String, Object?>> Function() call,
    String password,
    bool remember,
  ) async {
    try {
      final data = await call();
      final token = data['token']?.toString();
      final user = _userFromServer(
        AppState._asMap(data['user']),
        password: password,
      );
      _apiToken = token;
      _api!.token = token;
      _currentUserId = user.id;
      _rememberSession = remember;
      lastAuthMessage = null;
      _changed();
      unawaited(syncNow());
      _startAutoSync();
      return true;
    } on ApiException catch (error) {
      if (error.isNetwork) return null;
      lastAuthMessage = error.message;
      _notify();
      return false;
    }
  }

  /// Etapa 1 da recuperação: pede o código enviado por e-mail.
  Future<bool> requestPasswordCode(String email) async {
    final api = _api;
    if (api == null) {
      lastAuthMessage = 'Conecte o app ao servidor para receber o código.';
      _notify();
      return false;
    }
    try {
      final data = await api.post('/api/auth/password/forgot', {
        'email': AppState._normalizeEmail(email),
      });
      lastAuthMessage = data['message']?.toString();
      _notify();
      return true;
    } on ApiException catch (error) {
      lastAuthMessage = error.message;
      _notify();
      return false;
    }
  }

  /// Etapa 2: confirma o código e define a nova senha (já entra na conta).
  Future<bool> confirmPasswordCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final api = _api;
    if (api == null) return false;
    final result = await _remoteAuth(
      () => api.post('/api/auth/password/reset', {
        'email': AppState._normalizeEmail(email),
        'code': code.trim(),
        'newPassword': newPassword,
      }),
      newPassword,
      true,
    );
    if (result == null) {
      lastAuthMessage = 'Sem conexão com o servidor. Tente novamente.';
      _notify();
    }
    return result ?? false;
  }

  AppUser _userFromServer(Map<String, Object?> json, {String? password}) {
    final email = AppState._normalizeEmail(json['email']?.toString() ?? '');
    final index = _users.indexWhere(
      (user) => AppState._normalizeEmail(user.email) == email,
    );
    final previous = index < 0 ? null : _users[index];
    final user = AppUser(
      id: json['id']?.toString() ?? previous?.id ?? _nextSimpleId('USR'),
      name: json['name']?.toString() ?? previous?.name ?? '',
      email: email,
      phone: json['phone']?.toString() ?? previous?.phone ?? '',
      role: json['role'] == 'admin' ? 'admin' : 'customer',
      passwordHash: password != null
          ? AppState._hashPassword(email, password)
          : previous?.passwordHash ?? '',
      createdAt: json['createdAt'] == null
          ? previous?.createdAt ?? DateTime.now()
          : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
      blocked: json['blocked'] == true,
    );
    if (previous != null && _currentUserId == previous.id) {
      _currentUserId = user.id;
    }
    if (index < 0) {
      _users.add(user);
    } else {
      _users[index] = user;
    }
    return user;
  }

  // ------------------------------------------------------------ fila

  void _enqueue(String type, Map<String, Object?> payload) {
    if (_api == null) return;
    _outbox.add({'type': type, ...payload});
    unawaited(syncNow());
  }

  Future<void> _flushOutbox(ApiClient api) async {
    if (_apiToken == null) return;
    while (_outbox.isNotEmpty) {
      final op = _outbox.first;
      try {
        await _sendOp(api, op);
        _outbox.removeAt(0);
      } on ApiException catch (error) {
        if (error.isNetwork || error.statusCode == 401) rethrow;
        // Recusado pelo servidor (ex.: estoque acabou): marca e descarta.
        _outbox.removeAt(0);
        _markRejected(op, error.message);
      }
      _changed();
    }
  }

  Future<void> _sendOp(ApiClient api, Map<String, Object?> op) async {
    final id = op['id']?.toString() ?? '';
    switch (op['type']) {
      case 'order':
        final index = _orders.indexWhere((order) => order.id == id);
        if (index < 0) return;
        final order = _orders[index];
        final data = await api.post('/api/orders', {
          'clientId': order.id,
          'items': [
            for (final item in order.items)
              {
                'productId': item.productId,
                'quantity': item.quantity,
                'option': item.option,
              },
          ],
          'paymentMethod': order.paymentMethod,
          'couponCode': order.couponCode,
          'shipping': order.shipping,
          'deliveryAddress': {
            'label': order.deliveryAddress.label,
            'street': order.deliveryAddress.street,
            'number': order.deliveryAddress.number,
            'complement': order.deliveryAddress.complement,
            'neighborhood': order.deliveryAddress.neighborhood,
            'city': order.deliveryAddress.city,
            'state': order.deliveryAddress.state,
            'postalCode': order.deliveryAddress.postalCode,
          },
        });
        final synced = _orderFromServer(AppState._asMap(data['data']));
        final current = _orders.indexWhere((order) => order.id == id);
        if (current >= 0) _orders[current] = synced;
      case 'quote':
        final index = _quotes.indexWhere((quote) => quote.id == id);
        if (index < 0) return;
        final quote = _quotes[index];
        final data = await api.post('/api/quotes', {
          'clientId': quote.id,
          'productId': quote.productId,
          'productName': quote.productName,
          'customerName': quote.customerName,
          'email': quote.email,
          'phone': quote.phone,
          'details': quote.details,
        });
        final synced = _quoteFromServer(AppState._asMap(data['data']));
        final current = _quotes.indexWhere((quote) => quote.id == id);
        if (current >= 0) _quotes[current] = synced;
      case 'orderStatus':
        await api.patch('/api/orders/${ApiClient.encodeId(id)}/status', {
          'status': op['status'],
          'note': op['note'],
        });
      case 'quoteStatus':
        await api.patch('/api/quotes/${ApiClient.encodeId(id)}', {
          'status': op['status'],
          'response': op['response'],
        });
      case 'product':
        final product = findProductById(id);
        if (product == null) return;
        await api.put(
          '/api/products/${ApiClient.encodeId(id)}',
          product.toJson(),
        );
      case 'productDelete':
        await api.delete('/api/products/${ApiClient.encodeId(id)}');
      case 'user':
        await api.patch('/api/users/${ApiClient.encodeId(id)}', {
          'role': ?op['role'],
          'blocked': ?op['blocked'],
        });
      case 'userDelete':
        await api.delete('/api/users/${ApiClient.encodeId(id)}');
      case 'profile':
        await api.patch('/api/auth/me', {
          'name': ?op['name'],
          'phone': ?op['phone'],
          'currentPassword': ?op['currentPassword'],
          'newPassword': ?op['newPassword'],
        });
    }
  }

  void _markRejected(Map<String, Object?> op, String message) {
    final id = op['id']?.toString();
    if (op['type'] == 'order') {
      final index = _orders.indexWhere((order) => order.id == id);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(
          syncState: 'failed',
          syncError: message,
        );
      }
      _addNotification(
        title: 'Pedido não enviado',
        message: '$id: $message',
        category: 'order',
      );
    } else if (op['type'] == 'quote') {
      final index = _quotes.indexWhere((quote) => quote.id == id);
      if (index >= 0) {
        _quotes[index] = _quotes[index].copyWith(
          syncState: 'failed',
          syncError: message,
        );
      }
    } else {
      syncMessage = message;
    }
  }

  /// Reenvia um pedido recusado (ex.: depois de ajustar o estoque).
  void retryOrderSync(String id) {
    final index = _orders.indexWhere((order) => order.id == id);
    if (index < 0 || _orders[index].syncState != 'failed') return;
    _orders[index] = _orders[index].copyWith(syncState: 'pending');
    _enqueue('order', {'id': id});
    _changed();
  }

  // ------------------------------------------------------------ recebimento

  Future<void> _pull(ApiClient api) async {
    final products = await api.get(
      '/api/products',
      query: isAdmin ? {'all': 'true'} : null,
    );
    final remoteProducts = [
      for (final raw in _asList(products['data']))
        Product.fromJson(AppState._asMap(raw)),
    ];
    if (remoteProducts.isNotEmpty) {
      _products
        ..clear()
        ..addAll(remoteProducts);
      for (final product in remoteProducts) {
        if (!_categories.contains(product.category)) {
          _categories.add(product.category);
        }
      }
      for (final id in _cart.keys.toList()) {
        _clampCartItem(id);
      }
      _favorites.removeWhere((id) => findProductById(id) == null);
    }

    if (_apiToken == null || currentUser == null) return;
    final scope = isAdmin ? {'scope': 'all'} : null;
    final remoteOrders = [
      for (final raw in _asList(
        (await api.get('/api/orders', query: scope))['data'],
      ))
        _orderFromServer(AppState._asMap(raw)),
    ];
    _mergeOrders(remoteOrders);

    final remoteQuotes = [
      for (final raw in _asList(
        (await api.get('/api/quotes', query: scope))['data'],
      ))
        _quoteFromServer(AppState._asMap(raw)),
    ];
    _mergeQuotes(remoteQuotes);

    if (isAdmin) {
      final users = await api.get('/api/users');
      for (final raw in _asList(users['data'])) {
        _userFromServer(AppState._asMap(raw));
      }
    } else {
      final me = await api.get('/api/auth/me');
      _userFromServer(AppState._asMap(me['user']));
    }
  }

  void _mergeOrders(List<CustomerOrder> remote) {
    final previous = {for (final order in _orders) order.id: order};
    final remoteClientIds = {
      for (final order in remote)
        if (order.clientId != null) order.clientId!,
    };
    final unsynced = _orders.where(
      (order) => order.syncState != null && !remoteClientIds.contains(order.id),
    );
    final knew = _knownRemoteIds.isNotEmpty;
    for (final order in remote) {
      final old = previous[order.id];
      final mine =
          order.customerEmail != null &&
          order.customerEmail == currentUser?.email;
      if (mine && old != null && old.status != order.status) {
        if (orderNotifications) {
          _addNotification(
            title: order.status.label,
            message: 'Seu pedido ${order.id} está: ${order.status.label}.',
            category: 'order',
          );
        }
      } else if (isAdmin && knew && !_knownRemoteIds.contains(order.id)) {
        if (orderNotifications) {
          _addNotification(
            title: 'Novo pedido',
            message:
                '${order.id} de ${order.customerName ?? order.customerEmail} · '
                '${money(order.total)}',
            category: 'order',
          );
        }
      }
      _knownRemoteIds.add(order.id);
    }
    final merged = [...unsynced, ...remote]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _orders
      ..clear()
      ..addAll(merged);
  }

  void _mergeQuotes(List<QuoteRequest> remote) {
    final previous = {for (final quote in _quotes) quote.id: quote};
    for (final quote in remote) {
      final old = previous[quote.id];
      if (!isAdmin && old != null && old.status != quote.status) {
        if (supportNotifications) {
          _addNotification(
            title: 'Orçamento ${quote.status.label.toLowerCase()}',
            message: quote.response?.isNotEmpty == true
                ? '${quote.id}: ${quote.response}'
                : '${quote.id} foi atualizado pela equipe.',
            category: 'support',
          );
        }
      }
    }
    final unsynced = _quotes.where((quote) => quote.syncState != null).toList();
    _quotes
      ..clear()
      ..addAll([...unsynced, ...remote])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  CustomerOrder _orderFromServer(Map<String, Object?> json) {
    final address = AppState._asMap(json['deliveryAddress']);
    final order = CustomerOrder.fromJson({
      ...json,
      'deliveryAddress': {
        'id': 'END-SRV',
        'label': address['label'] ?? 'Entrega',
        'street': address['street'] ?? '',
        'number': address['number'] ?? '',
        'complement': address['complement'] ?? '',
        'neighborhood': address['neighborhood'] ?? '',
        'city': address['city'] ?? '',
        'state': address['state'] ?? '',
        'postalCode': address['postalCode'] ?? '',
      },
      'syncState': null,
      'syncError': null,
    });
    return order;
  }

  QuoteRequest _quoteFromServer(Map<String, Object?> json) =>
      QuoteRequest.fromJson({...json, 'syncState': null, 'syncError': null});

  // ------------------------------------------------------------ frete

  /// Tabela de estimativa por região do CEP (mesma da API). Usada sem
  /// contrato com os Correios ou sem conexão.
  static List<ShippingOption> estimateShipping(String postalCode) {
    final digits = postalCode.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return const [];
    const table = [
      [24.90, 39.90, 4, 2],
      [29.90, 49.90, 6, 3],
      [39.90, 64.90, 8, 4],
      [39.90, 64.90, 8, 4],
      [54.90, 89.90, 10, 5],
      [59.90, 99.90, 12, 6],
      [69.90, 119.90, 14, 7],
      [54.90, 89.90, 10, 5],
      [34.90, 59.90, 7, 3],
      [39.90, 64.90, 8, 4],
    ];
    final row = table[int.parse(digits[0])];
    return [
      ShippingOption(
        service: 'PAC',
        price: row[0].toDouble(),
        days: row[2].toInt(),
      ),
      ShippingOption(
        service: 'SEDEX',
        price: row[1].toDouble(),
        days: row[3].toInt(),
      ),
    ];
  }

  /// Cota o frete: API (Correios, quando há contrato) ou estimativa local.
  Future<List<ShippingOption>> quoteShipping(String postalCode) async {
    final digits = postalCode.replaceAll(RegExp(r'\D'), '');
    var options = estimateShipping(digits);
    if (options.isEmpty) return options;
    final api = _api;
    if (api != null) {
      try {
        final data = await api.post('/api/shipping/quote', {
          'cep': digits,
          'items': [
            for (final entry in _cart.entries)
              {'productId': entry.key, 'quantity': entry.value},
          ],
        });
        final estimated = data['source'] != 'correios';
        final remote = [
          for (final raw in _asList(data['options']))
            ShippingOption(
              service: AppState._asMap(raw)['service']?.toString() ?? '',
              price: (AppState._asMap(raw)['price'] as num?)?.toDouble() ?? 0,
              days: (AppState._asMap(raw)['days'] as num?)?.toInt() ?? 0,
              estimated: estimated,
            ),
        ];
        if (remote.isNotEmpty) options = remote;
      } on ApiException {
        // Mantém a estimativa local.
      }
    }
    shippingOptions = options;
    shippingPostalCode = digits;
    selectShipping(
      options.any((option) => option.service == shippingService)
          ? shippingService!
          : options.first.service,
    );
    return options;
  }

  void selectShipping(String service) {
    for (final option in shippingOptions) {
      if (option.service == service) {
        shippingService = service;
        _shippingCost = option.price;
        _changed(persist: false);
        return;
      }
    }
  }

  /// Consulta o endereço pelo CEP no ViaCEP (serviço público dos Correios
  /// via viacep.com.br). Devolve null se o CEP não existir ou sem internet.
  Future<Map<String, String>?> lookupPostalCode(String postalCode) async {
    final digits = postalCode.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final client = _httpClient ?? http.Client();
    try {
      final response = await client
          .get(Uri.parse('https://viacep.com.br/ws/$digits/json/'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map || data['erro'] != null) return null;
      return {
        'street': '${data['logradouro'] ?? ''}',
        'neighborhood': '${data['bairro'] ?? ''}',
        'city': '${data['localidade'] ?? ''}',
        'state': '${data['uf'] ?? ''}',
      };
    } catch (_) {
      return null;
    } finally {
      if (_httpClient == null) client.close();
    }
  }

  // ------------------------------------------------------------ fotos

  /// Guarda a foto escolhida no painel: envia para a API (online) ou copia
  /// para a pasta do app (offline). Devolve o caminho/URL para o produto.
  Future<String> storeProductImage(List<int> bytes, String filename) async {
    final api = _api;
    if (api != null && _apiToken != null) {
      return api.uploadImage(bytes, filename);
    }
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}/product_images');
    await folder.create(recursive: true);
    final extension = filename.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final file = File(
      '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

List<Object?> _asList(Object? value) => value is List ? value : const [];
