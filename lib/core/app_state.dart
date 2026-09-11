import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';
import '../models/product.dart';

class AppState extends ChangeNotifier {
  AppState([this._preferences]) {
    _seed();
  }

  static const _storageKey = 'leadsystem_state_v2';
  static const _storageVersion = 2;

  final SharedPreferences? _preferences;
  Future<void> _writeQueue = Future<void>.value();
  int _serial = 0;

  final Map<String, int> _cart = {};
  final Set<String> _favorites = {};
  final List<Product> _products = [];
  final List<String> _categories = [];
  final List<AppUser> _users = [];
  final List<Address> _addresses = [];
  final List<CustomerOrder> _orders = [];
  final List<QuoteRequest> _quotes = [];
  final List<Coupon> _coupons = [];
  final List<Campaign> _campaigns = [];
  final List<ChatMessage> _messages = [];
  final List<AppNotification> _notificationEvents = [];

  int navigationIndex = 0;
  String searchQuery = '';
  String category = 'Todos';
  ProductSort productSort = ProductSort.relevance;
  String? _appliedCouponCode;
  String? _currentUserId;
  bool _rememberSession = false;
  bool _orderPlaced = false;
  double _shippingCost = 24.90;
  NotificationPreferences _notificationPreferences =
      const NotificationPreferences();
  String? lastAuthMessage;
  String? lastPersistenceError;

  static Future<AppState> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final state = AppState(preferences);
    await state._hydrate();
    await state.flush();
    return state;
  }

  Map<String, int> get cart => Map.unmodifiable(_cart);
  Set<String> get favorites => Set.unmodifiable(_favorites);
  List<Product> get products => List.unmodifiable(_products);
  List<String> get categories => List.unmodifiable(_categories);
  List<AppUser> get users => List.unmodifiable(_users);
  List<Address> get addresses => List.unmodifiable(_addresses);
  List<CustomerOrder> get orders => List.unmodifiable(_orders);
  List<QuoteRequest> get quotes => List.unmodifiable(_quotes);
  List<Coupon> get coupons => List.unmodifiable(_coupons);
  List<Campaign> get campaigns => List.unmodifiable(_campaigns);
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<AppNotification> get notificationEvents =>
      List.unmodifiable(_notificationEvents);

  AppUser? get currentUser => _findUser(_currentUserId);
  bool get loggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;
  bool get rememberSession => _rememberSession;
  String get userName => currentUser?.name ?? 'Visitante';
  String get userEmail => currentUser?.email ?? '';
  String get userPhone => currentUser?.phone ?? '';
  bool get orderPlaced => _orderPlaced;
  CustomerOrder? get lastOrder => _orders.isEmpty ? null : _orders.first;
  Address? get defaultAddress {
    for (final address in _addresses) {
      if (address.isDefault) return address;
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

  NotificationPreferences get notificationPreferences =>
      _notificationPreferences;
  bool get orderNotifications => _notificationPreferences.orderUpdates;
  bool get offersNotifications => _notificationPreferences.offers;
  bool get supportNotifications => _notificationPreferences.support;
  int get unreadNotificationCount =>
      _notificationEvents.where((event) => !event.read).length;

  List<Product> get favoriteProducts => _products
      .where((product) => _favorites.contains(product.id) && product.active)
      .toList(growable: false);
  List<Product> get lowStockProducts => _products
      .where((product) => product.active && product.stock <= 5)
      .toList(growable: false);
  int get pendingOrderCount => _orders
      .where(
        (order) =>
            order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled,
      )
      .length;
  int get pendingQuoteCount => _quotes
      .where(
        (quote) =>
            quote.status == QuoteStatus.pending ||
            quote.status == QuoteStatus.reviewing,
      )
      .length;
  double get totalRevenue => _orders
      .where((order) => order.status != OrderStatus.cancelled)
      .fold(0, (sum, order) => sum + order.total);

  int get cartCount => _cart.values.fold(0, (sum, value) => sum + value);
  double get subtotal => _cart.entries.fold(0, (sum, entry) {
    final product = findProductById(entry.key);
    return sum + (product?.price ?? 0) * entry.value;
  });
  Coupon? get appliedCoupon {
    final code = _appliedCouponCode;
    if (code == null) return null;
    for (final coupon in _coupons) {
      if (coupon.code == code) return coupon;
    }
    return null;
  }

  bool get couponApplied => appliedCoupon != null;
  double get discount =>
      subtotal * ((appliedCoupon?.discountPercent ?? 0) / 100);
  double get shipping => _cart.isEmpty ? 0 : _shippingCost;
  double get total => subtotal - discount + shipping;

  List<Product> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();
    final result = _products.where((product) {
      final matchesCategory =
          category == 'Todos' || product.category == category;
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.shortName.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      return product.active && matchesCategory && matchesQuery;
    }).toList();
    switch (productSort) {
      case ProductSort.relevance:
        break;
      case ProductSort.name:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSort.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSort.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSort.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return result;
  }

  Product? findProductById(String? id) {
    if (id == null) return null;
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Product productById(String id) {
    final product = findProductById(id);
    if (product == null) throw StateError('Produto $id não encontrado.');
    return product;
  }

  void setNavigationIndex(int value) {
    navigationIndex = value.clamp(0, 4);
    _changed(persist: false);
  }

  void setSearch(String value) {
    searchQuery = value;
    _changed(persist: false);
  }

  void setCategory(String value) {
    category = value == 'Todos' || _categories.contains(value)
        ? value
        : 'Todos';
    _changed(persist: false);
  }

  void setProductSort(ProductSort value) {
    productSort = value;
    _changed(persist: false);
  }

  int addToCart(Product product, {int quantity = 1}) {
    final current = _cart[product.id] ?? 0;
    if (!product.active || product.stock <= 0 || quantity <= 0) return current;
    final next = (current + quantity).clamp(0, product.stock);
    if (next == current) return current;
    _cart[product.id] = next;
    _changed();
    return next;
  }

  void setQuantity(String productId, int quantity) {
    final product = findProductById(productId);
    if (product == null || quantity <= 0 || product.stock <= 0) {
      if (_cart.remove(productId) != null) _changed();
      return;
    }
    final next = quantity.clamp(1, product.stock);
    if (_cart[productId] == next) return;
    _cart[productId] = next;
    _changed();
  }

  void clearCart() {
    if (_cart.isEmpty && _appliedCouponCode == null) return;
    _cart.clear();
    _appliedCouponCode = null;
    _changed();
  }

  bool applyCoupon(String code) {
    final normalized = code.trim().toUpperCase();
    Coupon? match;
    for (final coupon in _coupons) {
      if (coupon.code == normalized) {
        match = coupon;
        break;
      }
    }
    if (match == null || !match.isAvailable(subtotal: subtotal)) {
      _appliedCouponCode = null;
      _changed();
      return false;
    }
    _appliedCouponCode = match.code;
    _changed();
    return true;
  }

  void toggleFavorite(String productId) {
    if (findProductById(productId) == null) return;
    if (!_favorites.add(productId)) _favorites.remove(productId);
    _changed();
  }

  Future<bool> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    final normalized = _normalizeEmail(email);
    AppUser? user;
    for (final candidate in _users) {
      if (_normalizeEmail(candidate.email) == normalized) {
        user = candidate;
        break;
      }
    }
    if (user == null ||
        user.passwordHash != _hashPassword(normalized, password)) {
      lastAuthMessage = 'E-mail ou senha incorretos.';
      notifyListeners();
      return false;
    }
    if (user.blocked) {
      lastAuthMessage = 'Esta conta está bloqueada. Fale com o administrador.';
      notifyListeners();
      return false;
    }
    _currentUserId = user.id;
    _rememberSession = remember;
    lastAuthMessage = null;
    _changed();
    await flush();
    return true;
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool remember = true,
  }) async {
    final normalized = _normalizeEmail(email);
    if (name.trim().split(RegExp(r'\s+')).length < 2) {
      lastAuthMessage = 'Informe nome e sobrenome.';
      notifyListeners();
      return false;
    }
    if (!_validEmail(normalized)) {
      lastAuthMessage = 'Informe um e-mail válido.';
      notifyListeners();
      return false;
    }
    if (_users.any((user) => _normalizeEmail(user.email) == normalized)) {
      lastAuthMessage = 'Já existe uma conta com este e-mail.';
      notifyListeners();
      return false;
    }
    if (!_validPassword(password)) {
      lastAuthMessage =
          'A senha deve ter 8 caracteres, uma letra maiúscula e um número.';
      notifyListeners();
      return false;
    }
    final user = AppUser(
      id: _nextSimpleId('USR'),
      name: name.trim(),
      email: normalized,
      phone: phone.trim(),
      role: 'customer',
      passwordHash: _hashPassword(normalized, password),
      createdAt: DateTime.now(),
    );
    _users.add(user);
    _currentUserId = user.id;
    _rememberSession = remember;
    lastAuthMessage = null;
    _addNotification(
      title: 'Conta criada',
      message: 'Bem-vindo à SantiGrill, ${user.name.split(' ').first}!',
      category: 'system',
    );
    _changed();
    await flush();
    return true;
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final normalized = _normalizeEmail(email);
    final index = _users.indexWhere(
      (user) => _normalizeEmail(user.email) == normalized,
    );
    if (index < 0) {
      lastAuthMessage = 'Nenhuma conta foi encontrada para este e-mail.';
      notifyListeners();
      return false;
    }
    if (!_validPassword(newPassword)) {
      lastAuthMessage = 'A nova senha deve ter 8 caracteres, uma letra maiúscula e um número.';
      notifyListeners();
      return false;
    }
    _users[index] = _users[index].copyWith(
      passwordHash: _hashPassword(normalized, newPassword),
    );
    lastAuthMessage = 'Senha atualizada com sucesso.';
    _changed();
    await flush();
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null) {
      lastAuthMessage = 'Entre na conta para alterar a senha.';
      notifyListeners();
      return false;
    }
    if (user.passwordHash != _hashPassword(user.email, currentPassword)) {
      lastAuthMessage = 'A senha atual está incorreta.';
      notifyListeners();
      return false;
    }
    return resetPassword(email: user.email, newPassword: newPassword);
  }

  void updateProfile({
    required String name,
    required String email,
    required String phone,
  }) {
    final user = currentUser;
    if (user == null) return;
    final normalized = _normalizeEmail(email);
    if (!_validEmail(normalized) || name.trim().isEmpty) {
      lastAuthMessage = 'Revise o nome e o e-mail informados.';
      notifyListeners();
      return;
    }
    if (_users.any(
      (item) => item.id != user.id && _normalizeEmail(item.email) == normalized,
    )) {
      lastAuthMessage = 'Este e-mail já pertence a outra conta.';
      notifyListeners();
      return;
    }
    final index = _users.indexWhere((item) => item.id == user.id);
    _users[index] = user.copyWith(
      name: name.trim(),
      email: normalized,
      phone: phone.trim(),
    );
    lastAuthMessage = null;
    _changed();
  }

  void logout() {
    _currentUserId = null;
    _rememberSession = false;
    lastAuthMessage = null;
    _changed();
  }

  void signOut() => logout();

  @Deprecated('Use login para validar as credenciais locais.')
  void signIn({String? name}) {
    final demo = _users.firstWhere((user) => user.isAdmin);
    _currentUserId = demo.id;
    _rememberSession = true;
    if (name != null && name.trim().isNotEmpty && name != demo.name) {
      final index = _users.indexWhere((user) => user.id == demo.id);
      _users[index] = demo.copyWith(name: name.trim());
    }
    _changed();
  }

  Address addAddress({
    required String label,
    required String street,
    required String number,
    String complement = '',
    required String neighborhood,
    required String city,
    required String state,
    required String postalCode,
    bool makeDefault = false,
  }) {
    final shouldDefault = makeDefault || _addresses.isEmpty;
    if (shouldDefault) {
      for (var index = 0; index < _addresses.length; index++) {
        _addresses[index] = _addresses[index].copyWith(isDefault: false);
      }
    }
    final address = Address(
      id: _nextSimpleId('END'),
      label: label.trim(),
      street: street.trim(),
      number: number.trim(),
      complement: complement.trim(),
      neighborhood: neighborhood.trim(),
      city: city.trim(),
      state: state.trim().toUpperCase(),
      postalCode: postalCode.trim(),
      isDefault: shouldDefault,
    );
    _addresses.add(address);
    _changed();
    return address;
  }

  void updateAddress(Address address) {
    final index = _addresses.indexWhere((item) => item.id == address.id);
    if (index < 0) return;
    if (address.isDefault) {
      for (var item = 0; item < _addresses.length; item++) {
        _addresses[item] = _addresses[item].copyWith(isDefault: false);
      }
    }
    _addresses[index] = address;
    _ensureDefaultAddress();
    _changed();
  }

  void removeAddress(String id) {
    final removedDefault = _addresses.any(
      (address) => address.id == id && address.isDefault,
    );
    if (!_addresses.any((address) => address.id == id)) return;
    _addresses.removeWhere((address) => address.id == id);
    if (removedDefault) _ensureDefaultAddress();
    _changed();
  }

  void setDefaultAddress(String id) {
    if (!_addresses.any((address) => address.id == id)) return;
    for (var index = 0; index < _addresses.length; index++) {
      _addresses[index] = _addresses[index].copyWith(
        isDefault: _addresses[index].id == id,
      );
    }
    _changed();
  }

  void setOrderNotifications(bool value) {
    _notificationPreferences = _notificationPreferences.copyWith(
      orderUpdates: value,
    );
    _changed();
  }

  void setOffersNotifications(bool value) {
    _notificationPreferences = _notificationPreferences.copyWith(offers: value);
    _changed();
  }

  void setSupportNotifications(bool value) {
    _notificationPreferences = _notificationPreferences.copyWith(
      support: value,
    );
    _changed();
  }

  void markNotificationRead(String id) {
    final index = _notificationEvents.indexWhere((event) => event.id == id);
    if (index < 0 || _notificationEvents[index].read) return;
    _notificationEvents[index] = _notificationEvents[index].copyWith(
      read: true,
    );
    _changed();
  }

  void clearNotificationHistory() {
    if (_notificationEvents.isEmpty) return;
    _notificationEvents.clear();
    _changed();
  }

  void upsertProduct(Product product) {
    if (product.id.trim().isEmpty || product.name.trim().isEmpty) return;
    final normalized = product.copyWith(
      id: product.id.trim().toUpperCase(),
      name: product.name.trim(),
      shortName: product.shortName.trim(),
      category: product.category.trim(),
      price: product.price < 0 ? 0 : product.price,
      stock: product.stock < 0 ? 0 : product.stock,
    );
    final index = _products.indexWhere((item) => item.id == normalized.id);
    if (index < 0) {
      _products.add(normalized);
    } else {
      _products[index] = normalized;
    }
    if (!_categories.contains(normalized.category)) {
      _categories.add(normalized.category);
      _categories.sort();
    }
    _clampCartItem(normalized.id);
    _changed();
  }

  bool removeProduct(String id) {
    if (_cart.containsKey(id)) return false;
    final before = _products.length;
    _products.removeWhere((product) => product.id == id);
    if (_products.length == before) return false;
    _favorites.remove(id);
    _changed();
    return true;
  }

  void setProductStock(String id, int stock) {
    final index = _products.indexWhere((product) => product.id == id);
    if (index < 0) return;
    _products[index] = _products[index].copyWith(stock: stock.clamp(0, 999999));
    _clampCartItem(id);
    _changed();
  }

  void adjustProductStock(String id, int delta) {
    final product = findProductById(id);
    if (product == null) return;
    setProductStock(id, product.stock + delta);
  }

  bool addCategory(String name) {
    final value = name.trim();
    if (value.isEmpty || value == 'Todos' || _categories.contains(value)) {
      return false;
    }
    _categories.add(value);
    _categories.sort();
    _changed();
    return true;
  }

  bool renameCategory(String oldName, String newName) {
    final value = newName.trim();
    final index = _categories.indexOf(oldName);
    if (index < 0 || value.isEmpty || value == 'Todos') return false;
    if (_categories.contains(value) && value != oldName) return false;
    _categories[index] = value;
    for (
      var productIndex = 0;
      productIndex < _products.length;
      productIndex++
    ) {
      final product = _products[productIndex];
      if (product.category == oldName) {
        _products[productIndex] = product.copyWith(category: value);
      }
    }
    if (category == oldName) category = value;
    _categories.sort();
    _changed();
    return true;
  }

  bool removeCategory(String name) {
    if (_products.any((product) => product.category == name)) return false;
    final removed = _categories.remove(name);
    if (!removed) return false;
    if (category == name) category = 'Todos';
    _changed();
    return true;
  }

  String nextProductId([String prefix = 'PRO']) {
    final max = _products
        .map((product) => int.tryParse(product.id.split('-').last) ?? 0)
        .fold(0, (current, value) => value > current ? value : current);
    return '${prefix.toUpperCase()}-${(max + 1).toString().padLeft(3, '0')}';
  }

  void upsertCoupon(Coupon coupon) {
    final normalized = coupon.copyWith(code: coupon.code.trim().toUpperCase());
    if (normalized.code.isEmpty || normalized.discountPercent <= 0) return;
    final index = _coupons.indexWhere((item) => item.code == normalized.code);
    if (index < 0) {
      _coupons.add(normalized);
    } else {
      _coupons[index] = normalized;
    }
    _changed();
  }

  bool removeCoupon(String code) {
    final normalized = code.trim().toUpperCase();
    final before = _coupons.length;
    _coupons.removeWhere((coupon) => coupon.code == normalized);
    if (_coupons.length == before) return false;
    if (_appliedCouponCode == normalized) _appliedCouponCode = null;
    _changed();
    return true;
  }

  DeliveryEstimate? calculateShipping(String postalCode) {
    final digits = postalCode.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final prefix = int.tryParse(digits.substring(0, 2)) ?? 0;
    _shippingCost = prefix >= 10 && prefix <= 19 ? 19.90 : 24.90;
    final now = DateTime.now();
    final estimate = DeliveryEstimate(
      postalCode: digits,
      cost: _shippingCost,
      estimatedStart: now.add(const Duration(days: 2)),
      estimatedEnd: now.add(const Duration(days: 4)),
    );
    _changed();
    return estimate;
  }

  CustomerOrder placeOrder({Address? address, String paymentMethod = 'Pix'}) {
    if (_cart.isEmpty) throw StateError('O carrinho está vazio.');
    final deliveryAddress = address ?? defaultAddress;
    if (deliveryAddress == null) {
      throw StateError('Cadastre um endereço de entrega.');
    }
    final items = <OrderItem>[];
    for (final entry in _cart.entries) {
      final product = findProductById(entry.key);
      if (product == null || product.stock < entry.value) {
        throw StateError('Revise o estoque dos itens antes de finalizar.');
      }
      items.add(
        OrderItem(
          productId: product.id,
          name: product.name,
          unitPrice: product.price,
          quantity: entry.value,
          imageQuadrant: product.imageQuadrant,
        ),
      );
    }
    final now = DateTime.now();
    final order = CustomerOrder(
      id: _nextOrderId(),
      createdAt: now,
      items: items,
      subtotal: subtotal,
      discount: discount,
      shipping: shipping,
      total: total,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      timeline: [
        OrderTimelineEntry(
          status: OrderStatus.received,
          title: OrderStatus.received.label,
          note: 'Pedido registrado no aplicativo.',
          createdAt: now,
        ),
      ],
    );
    for (final item in items) {
      final index = _products.indexWhere(
        (product) => product.id == item.productId,
      );
      _products[index] = _products[index].copyWith(
        stock: _products[index].stock - item.quantity,
      );
    }
    final coupon = appliedCoupon;
    if (coupon != null) {
      final index = _coupons.indexWhere((item) => item.code == coupon.code);
      _coupons[index] = coupon.copyWith(usedCount: coupon.usedCount + 1);
    }
    _orders.insert(0, order);
    _cart.clear();
    _appliedCouponCode = null;
    _orderPlaced = true;
    if (orderNotifications) {
      _addNotification(
        title: 'Pedido recebido',
        message: '${order.id} foi registrado e já está em acompanhamento.',
        category: 'order',
      );
    }
    _changed();
    return order;
  }

  void updateOrderStatus(String id, OrderStatus status, {String? note}) {
    final index = _orders.indexWhere((order) => order.id == id);
    if (index < 0 || _orders[index].status == status) return;
    final now = DateTime.now();
    final order = _orders[index];
    _orders[index] = order.copyWith(
      status: status,
      timeline: [
        ...order.timeline,
        OrderTimelineEntry(
          status: status,
          title: status.label,
          note: note?.trim().isNotEmpty == true
              ? note!.trim()
              : 'Status atualizado pela equipe SantiGrill.',
          createdAt: now,
        ),
      ],
    );
    if (orderNotifications) {
      _addNotification(
        title: status.label,
        message: '$id recebeu uma nova atualização.',
        category: 'order',
      );
    }
    _changed();
  }

  QuoteRequest submitQuote({
    required Product product,
    required String customerName,
    required String email,
    required String phone,
    required String details,
  }) {
    final now = DateTime.now();
    final quote = QuoteRequest(
      id: _nextQuoteId(),
      productId: product.id,
      productName: product.name,
      customerName: customerName.trim(),
      email: _normalizeEmail(email),
      phone: phone.trim(),
      details: details.trim(),
      createdAt: now,
    );
    _quotes.insert(0, quote);
    if (supportNotifications) {
      _addNotification(
        title: 'Orçamento enviado',
        message: '${quote.id} está aguardando análise da equipe.',
        category: 'support',
      );
    }
    _changed();
    return quote;
  }

  void updateQuoteStatus(String id, QuoteStatus status, {String? response}) {
    final index = _quotes.indexWhere((quote) => quote.id == id);
    if (index < 0) return;
    _quotes[index] = _quotes[index].copyWith(
      status: status,
      response: response?.trim(),
      updatedAt: DateTime.now(),
    );
    if (supportNotifications) {
      _addNotification(
        title: 'Orçamento atualizado',
        message: '$id agora está com status ${status.label.toLowerCase()}.',
        category: 'support',
      );
    }
    _changed();
  }

  void upsertCampaign(Campaign campaign) {
    final index = _campaigns.indexWhere((item) => item.id == campaign.id);
    if (index < 0) {
      _campaigns.insert(0, campaign);
    } else {
      _campaigns[index] = campaign;
    }
    if (campaign.active && offersNotifications) {
      _addNotification(
        title: campaign.title,
        message: campaign.message,
        category: 'offer',
      );
    }
    _changed();
  }

  bool removeCampaign(String id) {
    final before = _campaigns.length;
    _campaigns.removeWhere((campaign) => campaign.id == id);
    if (_campaigns.length == before) return false;
    _changed();
    return true;
  }

  void toggleCampaign(String id) {
    final index = _campaigns.indexWhere((campaign) => campaign.id == id);
    if (index < 0) return;
    _campaigns[index] = _campaigns[index].copyWith(
      active: !_campaigns[index].active,
    );
    _changed();
  }

  void setUserBlocked(String id, bool blocked) {
    final index = _users.indexWhere((user) => user.id == id);
    if (index < 0) return;
    _users[index] = _users[index].copyWith(blocked: blocked);
    if (blocked && _currentUserId == id) {
      _currentUserId = null;
      _rememberSession = false;
    }
    _changed();
  }

  void setUserRole(String id, String role) {
    final normalized = role.toLowerCase() == 'admin' ? 'admin' : 'customer';
    final index = _users.indexWhere((user) => user.id == id);
    if (index < 0) return;
    _users[index] = _users[index].copyWith(role: normalized);
    _changed();
  }

  void sendMessage(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    final now = DateTime.now();
    _messages.add(
      ChatMessage(
        id: _nextSimpleId('MSG'),
        text: value,
        createdAt: now,
        fromUser: true,
      ),
    );
    _messages.add(
      ChatMessage(
        id: _nextSimpleId('MSG'),
        text: _automaticReply(value),
        createdAt: now.add(const Duration(seconds: 1)),
        fromUser: false,
      ),
    );
    _changed();
  }

  void startSupportForOrder(String orderId) {
    navigationIndex = 3;
    sendMessage('Preciso de ajuda com o pedido $orderId.');
  }

  Future<void> flush() => _writeQueue;

  Future<void> clearPersistedData() async {
    await _preferences?.remove(_storageKey);
    _seed();
    _changed();
    await flush();
  }

  void _seed() {
    _cart.clear();
    _favorites.clear();
    _products
      ..clear()
      ..addAll(demoProducts.map((product) => product.copyWith()));
    _categories
      ..clear()
      ..addAll(['Churrasqueiras', 'Espetos', 'Grelhas', 'Kits']);
    _users
      ..clear()
      ..addAll([
        AppUser(
          id: 'USR-001',
          name: 'Leandro Gonçalves',
          email: 'leandro@email.com',
          phone: '(11) 99999-4321',
          role: 'admin',
          passwordHash: _hashPassword('leandro@email.com', 'Santi@2026'),
          createdAt: DateTime(2026, 9, 10, 9),
        ),
        AppUser(
          id: 'USR-002',
          name: 'Carlos Silva',
          email: 'carlos@email.com',
          phone: '(11) 98888-1111',
          role: 'customer',
          passwordHash: _hashPassword('carlos@email.com', 'Cliente@2026'),
          createdAt: DateTime(2026, 8, 18, 10),
        ),
      ]);
    _addresses
      ..clear()
      ..add(
        const Address(
          id: 'END-001',
          label: 'Casa',
          street: 'Rua Amazonas',
          number: '50',
          neighborhood: 'Centro',
          city: 'São Caetano do Sul',
          state: 'SP',
          postalCode: '09520-070',
          isDefault: true,
        ),
      );
    _orders
      ..clear()
      ..addAll(_seedOrders());
    _quotes
      ..clear()
      ..add(
        QuoteRequest(
          id: '#ORC-2026-0084',
          productId: 'KIT-008',
          productName: 'Kit Churrasco Profissional',
          customerName: 'Carlos Silva',
          email: 'carlos@email.com',
          phone: '(11) 98888-1111',
          details: 'Evento corporativo para 40 pessoas.',
          createdAt: DateTime(2026, 9, 10, 10, 15),
          status: QuoteStatus.reviewing,
        ),
      );
    _coupons
      ..clear()
      ..add(
        Coupon(
          code: 'PRIMEIRACOMPRA',
          description: '10% de desconto na primeira compra',
          discountPercent: 10,
          expiresAt: DateTime(2027, 12, 31, 23, 59),
          usageLimit: 500,
        ),
      );
    _campaigns
      ..clear()
      ..add(
        Campaign(
          id: 'CAM-001',
          title: 'Churrasco de domingo',
          message: 'Use PRIMEIRACOMPRA e ganhe 10% de desconto.',
          createdAt: DateTime(2026, 9, 10, 8),
          startAt: DateTime(2026, 9, 10),
          endAt: DateTime(2026, 12, 31, 23, 59),
        ),
      );
    _messages
      ..clear()
      ..addAll([
        ChatMessage(
          id: 'MSG-001',
          text: 'Olá! Como posso ajudar com seu pedido?',
          createdAt: DateTime(2026, 9, 10, 14, 29),
          fromUser: false,
        ),
        ChatMessage(
          id: 'MSG-002',
          text: 'Quero acompanhar o pedido #SG-2026-0147.',
          createdAt: DateTime(2026, 9, 10, 14, 31),
          fromUser: true,
        ),
      ]);
    _notificationEvents
      ..clear()
      ..add(
        AppNotification(
          id: 'NOT-001',
          title: 'Pedido em transporte',
          message: '#SG-2026-0147 saiu para o centro de distribuição.',
          category: 'order',
          createdAt: DateTime(2026, 9, 11, 9, 10),
        ),
      );
    navigationIndex = 0;
    searchQuery = '';
    category = 'Todos';
    productSort = ProductSort.relevance;
    _appliedCouponCode = null;
    _currentUserId = null;
    _rememberSession = false;
    _orderPlaced = false;
    _shippingCost = 24.90;
    _notificationPreferences = const NotificationPreferences();
    lastAuthMessage = null;
    lastPersistenceError = null;
  }

  List<CustomerOrder> _seedOrders() {
    const address = Address(
      id: 'END-001',
      label: 'Casa',
      street: 'Rua Amazonas',
      number: '50',
      neighborhood: 'Centro',
      city: 'São Caetano do Sul',
      state: 'SP',
      postalCode: '09520-070',
      isDefault: true,
    );
    return [
      CustomerOrder(
        id: '#SG-2026-0147',
        createdAt: DateTime(2026, 9, 10, 14, 32),
        items: const [
          OrderItem(
            productId: 'CHU-001',
            name: 'Churrasqueira Premium Aço',
            unitPrice: 899.90,
            quantity: 1,
            imageQuadrant: 0,
          ),
        ],
        subtotal: 899.90,
        discount: 0,
        shipping: 24.90,
        total: 924.80,
        paymentMethod: 'Pix',
        deliveryAddress: address,
        status: OrderStatus.shipped,
        timeline: [
          OrderTimelineEntry(
            status: OrderStatus.received,
            title: 'Pedido recebido',
            note: 'Pedido registrado.',
            createdAt: DateTime(2026, 9, 10, 14, 32),
          ),
          OrderTimelineEntry(
            status: OrderStatus.paymentApproved,
            title: 'Pagamento aprovado',
            note: 'Pagamento via Pix confirmado.',
            createdAt: DateTime(2026, 9, 10, 14, 35),
          ),
          OrderTimelineEntry(
            status: OrderStatus.shipped,
            title: 'Em transporte',
            note: 'Pedido encaminhado à transportadora.',
            createdAt: DateTime(2026, 9, 11, 9, 10),
          ),
        ],
      ),
      CustomerOrder(
        id: '#SG-2026-0121',
        createdAt: DateTime(2026, 8, 18, 11),
        items: const [
          OrderItem(
            productId: 'ESP-004',
            name: 'Espeto Giratório 4 Hastes',
            unitPrice: 249.90,
            quantity: 1,
            imageQuadrant: 1,
          ),
        ],
        subtotal: 249.90,
        discount: 0,
        shipping: 0,
        total: 249.90,
        paymentMethod: 'Cartão',
        deliveryAddress: address,
        status: OrderStatus.delivered,
        timeline: [
          OrderTimelineEntry(
            status: OrderStatus.delivered,
            title: 'Entregue',
            note: 'Pedido entregue ao destinatário.',
            createdAt: DateTime(2026, 8, 21, 16),
          ),
        ],
      ),
    ];
  }

  Future<void> _hydrate() async {
    final raw = _preferences?.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _schedulePersist();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('Estado inválido.');
      final data = _asMap(decoded);
      _replaceIfPresent(_products, data['products'], Product.fromJson);
      _replaceStringsIfPresent(_categories, data['categories']);
      _replaceIfPresent(_users, data['users'], AppUser.fromJson);
      _replaceIfPresent(_addresses, data['addresses'], Address.fromJson);
      _replaceIfPresent(_orders, data['orders'], CustomerOrder.fromJson);
      _replaceIfPresent(_quotes, data['quotes'], QuoteRequest.fromJson);
      _replaceIfPresent(_coupons, data['coupons'], Coupon.fromJson);
      _replaceIfPresent(_campaigns, data['campaigns'], Campaign.fromJson);
      _replaceIfPresent(_messages, data['messages'], ChatMessage.fromJson);
      _replaceIfPresent(
        _notificationEvents,
        data['notificationEvents'],
        AppNotification.fromJson,
      );
      final rawCart = data['cart'];
      if (rawCart is Map) {
        _cart
          ..clear()
          ..addEntries(
            rawCart.entries.map(
              (entry) => MapEntry(
                entry.key.toString(),
                (entry.value as num?)?.toInt() ?? 0,
              ),
            ),
          );
      }
      final rawFavorites = data['favorites'];
      if (rawFavorites is List) {
        _favorites
          ..clear()
          ..addAll(rawFavorites.map((item) => item.toString()));
      }
      final rawNotificationPreferences = data['notificationPreferences'];
      if (rawNotificationPreferences is Map) {
        _notificationPreferences = NotificationPreferences.fromJson(
          _asMap(rawNotificationPreferences),
        );
      }
      _rememberSession = data['rememberSession'] == true;
      _currentUserId = _rememberSession
          ? data['currentUserId']?.toString()
          : null;
      if (currentUser?.blocked == true) _currentUserId = null;
      _orderPlaced = data['orderPlaced'] == true;
      _shippingCost = (data['shippingCost'] as num?)?.toDouble() ?? 24.90;
      _appliedCouponCode = data['appliedCouponCode']?.toString();
      productSort = _enumValue(
        ProductSort.values,
        data['productSort'],
        ProductSort.relevance,
      );
      _ensureRequiredSeeds();
      _sanitizeState();
      lastPersistenceError = null;
    } catch (_) {
      _seed();
      lastPersistenceError =
          'Os dados locais estavam corrompidos e foram restaurados.';
    }
    _schedulePersist();
  }

  void _ensureRequiredSeeds() {
    if (_products.isEmpty) {
      _products.addAll(demoProducts.map((product) => product.copyWith()));
    }
    if (!_users.any((user) => user.email == 'leandro@email.com')) {
      _users.insert(
        0,
        AppUser(
          id: 'USR-001',
          name: 'Leandro Gonçalves',
          email: 'leandro@email.com',
          phone: '(11) 99999-4321',
          role: 'admin',
          passwordHash: _hashPassword('leandro@email.com', 'Santi@2026'),
          createdAt: DateTime(2026, 9, 10, 9),
        ),
      );
    }
    if (_categories.isEmpty) {
      _categories.addAll(
        _products.map((product) => product.category).toSet().toList()..sort(),
      );
    }
    _ensureDefaultAddress();
  }

  void _sanitizeState() {
    final productIds = _products.map((product) => product.id).toSet();
    _favorites.removeWhere((id) => !productIds.contains(id));
    for (final productId in _cart.keys.toList()) {
      _clampCartItem(productId);
    }
    if (appliedCoupon?.isAvailable(subtotal: subtotal) != true) {
      _appliedCouponCode = null;
    }
  }

  Map<String, Object?> _toJson() => {
    'version': _storageVersion,
    'products': _products.map((item) => item.toJson()).toList(),
    'categories': _categories,
    'users': _users.map((item) => item.toJson()).toList(),
    'addresses': _addresses.map((item) => item.toJson()).toList(),
    'orders': _orders.map((item) => item.toJson()).toList(),
    'quotes': _quotes.map((item) => item.toJson()).toList(),
    'coupons': _coupons.map((item) => item.toJson()).toList(),
    'campaigns': _campaigns.map((item) => item.toJson()).toList(),
    'messages': _messages.map((item) => item.toJson()).toList(),
    'notificationEvents': _notificationEvents
        .map((item) => item.toJson())
        .toList(),
    'notificationPreferences': _notificationPreferences.toJson(),
    'cart': _cart,
    'favorites': _favorites.toList(),
    'rememberSession': _rememberSession,
    'currentUserId': _rememberSession ? _currentUserId : null,
    'orderPlaced': _orderPlaced,
    'shippingCost': _shippingCost,
    'appliedCouponCode': _appliedCouponCode,
    'productSort': productSort.name,
  };

  void _changed({bool persist = true}) {
    notifyListeners();
    if (persist) _schedulePersist();
  }

  void _schedulePersist() {
    final preferences = _preferences;
    if (preferences == null) return;
    final payload = jsonEncode(_toJson());
    _writeQueue = _writeQueue.then((_) async {
      try {
        await preferences.setString(_storageKey, payload);
        lastPersistenceError = null;
      } catch (_) {
        lastPersistenceError =
            'Não foi possível salvar os dados neste momento.';
      }
    });
  }

  void _addNotification({
    required String title,
    required String message,
    required String category,
  }) {
    _notificationEvents.insert(
      0,
      AppNotification(
        id: _nextSimpleId('NOT'),
        title: title,
        message: message,
        category: category,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _clampCartItem(String productId) {
    final quantity = _cart[productId];
    final product = findProductById(productId);
    if (quantity == null) return;
    if (product == null || product.stock <= 0 || !product.active) {
      _cart.remove(productId);
    } else if (quantity > product.stock) {
      _cart[productId] = product.stock;
    }
  }

  void _ensureDefaultAddress() {
    if (_addresses.isEmpty || _addresses.any((address) => address.isDefault)) {
      return;
    }
    _addresses[0] = _addresses[0].copyWith(isDefault: true);
  }

  AppUser? _findUser(String? id) {
    if (id == null) return null;
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  String _nextSimpleId(String prefix) {
    _serial++;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_serial';
  }

  String _nextOrderId() {
    final year = DateTime.now().year;
    final max = _orders
        .where((order) => order.id.contains('-$year-'))
        .map((order) => int.tryParse(order.id.split('-').last) ?? 0)
        .fold(0, (current, value) => value > current ? value : current);
    return '#SG-$year-${(max + 1).toString().padLeft(4, '0')}';
  }

  String _nextQuoteId() {
    final year = DateTime.now().year;
    final max = _quotes
        .where((quote) => quote.id.contains('-$year-'))
        .map((quote) => int.tryParse(quote.id.split('-').last) ?? 0)
        .fold(0, (current, value) => value > current ? value : current);
    return '#ORC-$year-${(max + 1).toString().padLeft(4, '0')}';
  }

  String _automaticReply(String message) {
    final value = message.toLowerCase();
    if (value.contains('pedido') || value.contains('rastre')) {
      return 'Você pode acompanhar o status em Pedidos. Se informar o protocolo, a equipe consegue localizar mais detalhes.';
    }
    if (value.contains('frete') || value.contains('entrega')) {
      return 'O frete é calculado pelo CEP na tela do produto. O prazo estimado aparece antes da finalização.';
    }
    if (value.contains('orçamento') || value.contains('orcamento')) {
      return 'Abra um produto e toque em Solicitar orçamento. A solicitação ficará registrada em Pedidos.';
    }
    if (value.contains('pagamento') || value.contains('pix')) {
      return 'Aceitamos Pix, cartão e boleto. A opção pode ser escolhida na finalização da compra.';
    }
    return 'Mensagem recebida! Registrei sua solicitação e a equipe poderá continuar o atendimento por aqui.';
  }

  static String _normalizeEmail(String value) => value.trim().toLowerCase();
  static bool _validEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  static bool _validPassword(String value) =>
      value.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value);

  static String _hashPassword(String email, String password) {
    return sha256.convert(utf8.encode('leadsystem-v1|$password')).toString();
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, Object?>{};
  }

  static void _replaceIfPresent<T>(
    List<T> target,
    Object? raw,
    T Function(Map<String, Object?>) decode,
  ) {
    if (raw is! List) return;
    target
      ..clear()
      ..addAll(raw.map((item) => decode(_asMap(item))));
  }

  static void _replaceStringsIfPresent(List<String> target, Object? raw) {
    if (raw is! List) return;
    target
      ..clear()
      ..addAll(raw.map((item) => item.toString()));
  }

  static T _enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required AppState notifier, required super.child, super.key})
    : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore de widgets.');
    return scope!.notifier!;
  }
}
