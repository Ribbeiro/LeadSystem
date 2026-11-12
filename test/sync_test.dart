import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/models/app_models.dart';

import 'test_helpers.dart';

/// Servidor falso com o mesmo contrato da API em server/src/app.js.
class FakeServer {
  bool online = true;
  bool rejectOrders = false;
  final orders = <Map<String, Object?>>[];
  final quotes = <Map<String, Object?>>[];
  final sentCodes = <String>[];
  var passwords = {'carlos@email.com': 'Cliente@2026'};
  int _seq = 0;

  Map<String, Object?> user(String email) => {
    'id': 'srv-${email.split('@').first}',
    'name': email.startsWith('carlos') ? 'Carlos Silva' : 'Leandro Gonçalves',
    'email': email,
    'phone': '(11) 98888-1111',
    'role': email.startsWith('leandro') ? 'admin' : 'client',
    'blocked': false,
  };

  late final client = MockClient((request) async {
    if (!online) throw http.ClientException('offline');
    final path = request.url.path;
    final body = request.body.isEmpty
        ? <String, Object?>{}
        : (jsonDecode(request.body) as Map).cast<String, Object?>();
    http.Response json(Object data, [int status = 200]) => http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

    if (path == '/health') return json({'status': 'ok'});
    if (path == '/api/auth/login') {
      final email = body['email'];
      if (passwords[email] != body['password']) {
        return json({'message': 'E-mail ou senha incorretos.'}, 401);
      }
      return json({'token': 'tok-$email', 'user': user('$email')});
    }
    if (path == '/api/auth/me') {
      return json({'user': user('carlos@email.com')});
    }
    if (path == '/api/auth/password/forgot') {
      sentCodes.add('123456');
      return json({'message': 'Se o e-mail estiver cadastrado, enviaremos.'});
    }
    if (path == '/api/auth/password/reset') {
      if (body['code'] != '123456') {
        return json({'message': 'Código inválido ou expirado.'}, 400);
      }
      passwords['${body['email']}'] = '${body['newPassword']}';
      return json({'token': 'tok-new', 'user': user('${body['email']}')});
    }
    if (path == '/api/products') return json({'data': <Object>[]});
    if (path == '/api/users') {
      return json({
        'data': [user('carlos@email.com'), user('leandro@email.com')],
      });
    }
    if (path == '/api/shipping/quote') {
      return json({
        'source': 'correios',
        'options': [
          {'service': 'PAC', 'price': 31.5, 'days': 5},
          {'service': 'SEDEX', 'price': 52.0, 'days': 2},
        ],
      });
    }
    if (path == '/api/orders' && request.method == 'POST') {
      if (rejectOrders) {
        return json({'message': 'Estoque insuficiente.'}, 409);
      }
      final order = {
        ...body,
        'id': '#SG-2026-${(++_seq).toString().padLeft(4, '0')}',
        'createdAt': DateTime.now().toIso8601String(),
        'customerEmail': 'carlos@email.com',
        'customerName': 'Carlos Silva',
        'subtotal': 100,
        'discount': 0,
        'total': 124.9,
        'status': 'received',
        'items': [
          for (final item in body['items'] as List)
            {
              ...(item as Map).cast<String, Object?>(),
              'name': 'Produto',
              'unitPrice': 100,
            },
        ],
        'timeline': <Object>[],
      };
      orders.add(order);
      return json({'data': order}, 201);
    }
    if (path == '/api/orders') return json({'data': orders});
    if (path.startsWith('/api/orders/') && path.endsWith('/status')) {
      return json({'data': orders.first});
    }
    if (path == '/api/quotes' && request.method == 'POST') {
      final quote = {
        ...body,
        'id': '#ORC-2026-${(++_seq).toString().padLeft(4, '0')}',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };
      quotes.add(quote);
      return json({'data': quote}, 201);
    }
    if (path == '/api/quotes') return json({'data': quotes});
    return json({'message': 'Rota não encontrada.'}, 404);
  });
}

Future<AppState> onlineState(FakeServer server) async {
  final state = AppState(null, loadTestCatalog(), server.client);
  addTearDown(state.dispose);
  expect(await state.configureServer('localhost:3000'), isTrue);
  return state;
}

void main() {
  test('não conecta quando o servidor não responde', () async {
    final server = FakeServer()..online = false;
    final state = AppState(null, loadTestCatalog(), server.client);
    addTearDown(state.dispose);

    expect(await state.configureServer('localhost:3000'), isFalse);
    expect(state.onlineMode, isFalse);
    expect(state.syncMessage, contains('não respondeu'));
  });

  test('login online usa a conta do servidor', () async {
    final server = FakeServer();
    final state = await onlineState(server);

    expect(
      await state.login(email: 'carlos@email.com', password: 'errada'),
      isFalse,
    );
    expect(state.lastAuthMessage, 'E-mail ou senha incorretos.');

    expect(
      await state.login(email: 'carlos@email.com', password: 'Cliente@2026'),
      isTrue,
    );
    expect(state.currentUser?.id, 'srv-carlos');
  });

  test('sem conexão, entra com a conta salva no aparelho', () async {
    final server = FakeServer();
    final state = await onlineState(server);
    server.online = false;

    expect(
      await state.login(email: 'carlos@email.com', password: 'Cliente@2026'),
      isTrue,
    );
    expect(state.lastAuthMessage, contains('modo offline'));
  });

  test('pedido feito offline é enviado quando a conexão volta', () async {
    final server = FakeServer();
    final state = await onlineState(server);
    await state.login(email: 'carlos@email.com', password: 'Cliente@2026');
    await state.syncNow();

    server.online = false;
    state.addToCart(state.products.first, quantity: 1);
    final local = state.placeOrder(
      address: state.defaultAddress,
      paymentMethod: 'Pix',
    );
    await state.syncNow();
    expect(local.syncState, 'pending');
    expect(state.pendingSyncCount, 1);
    expect(state.syncMessage, contains('Sem conexão'));

    server.online = true;
    await state.syncNow();

    expect(state.pendingSyncCount, 0);
    expect(server.orders, hasLength(1));
    expect(server.orders.single['clientId'], local.id);
    expect(state.myOrders.first.id, '#SG-2026-0001');
    expect(state.myOrders.first.syncState, isNull);
  });

  test('pedido recusado pelo servidor fica marcado e avisa', () async {
    final server = FakeServer()..rejectOrders = true;
    final state = await onlineState(server);
    await state.login(email: 'carlos@email.com', password: 'Cliente@2026');

    state.addToCart(state.products.first);
    final local = state.placeOrder(address: state.defaultAddress);
    await state.syncNow();

    final saved = state.orders.firstWhere((order) => order.id == local.id);
    expect(saved.syncState, 'failed');
    expect(saved.syncError, 'Estoque insuficiente.');
    expect(state.notificationEvents.first.title, 'Pedido não enviado');
  });

  test('mudança de status no servidor gera notificação', () async {
    final server = FakeServer();
    final state = await onlineState(server);
    final shown = <String>[];
    state.onSystemNotification = (title, _) => shown.add(title);
    await state.login(email: 'carlos@email.com', password: 'Cliente@2026');
    state.addToCart(state.products.first);
    state.placeOrder(address: state.defaultAddress);
    await state.syncNow();
    shown.clear();

    server.orders.first['status'] = 'shipped';
    await state.syncNow();

    expect(state.myOrders.first.status, OrderStatus.shipped);
    expect(shown, contains('Em transporte'));
  });

  test('orçamento online é enviado e recebe número do servidor', () async {
    final server = FakeServer();
    final state = await onlineState(server);
    await state.login(email: 'carlos@email.com', password: 'Cliente@2026');

    state.submitQuote(
      product: state.products.first,
      customerName: 'Carlos Silva',
      email: 'carlos@email.com',
      phone: '(11) 98888-1111',
      details: 'Preciso de 5 unidades para um evento.',
    );
    await state.syncNow();

    expect(server.quotes, hasLength(1));
    expect(state.myQuotes.first.id, startsWith('#ORC-'));
  });

  test('recuperação de senha por código', () async {
    final server = FakeServer();
    final state = await onlineState(server);

    expect(await state.requestPasswordCode('carlos@email.com'), isTrue);
    expect(server.sentCodes, hasLength(1));
    expect(
      await state.confirmPasswordCode(
        email: 'carlos@email.com',
        code: '000000',
        newPassword: 'Nova@2026',
      ),
      isFalse,
    );
    expect(state.lastAuthMessage, 'Código inválido ou expirado.');
    expect(
      await state.confirmPasswordCode(
        email: 'carlos@email.com',
        code: '123456',
        newPassword: 'Nova@2026',
      ),
      isTrue,
    );
    expect(state.loggedIn, isTrue);
  });

  test('frete usa a cotação do servidor e cai na estimativa offline', () async {
    final server = FakeServer();
    final state = await onlineState(server);
    state.addToCart(state.products.first);

    final official = await state.quoteShipping('01001-000');
    expect(official.first.price, 31.5);
    expect(official.first.estimated, isFalse);
    expect(state.shipping, 31.5);

    state.selectShipping('SEDEX');
    expect(state.shipping, 52.0);

    server.online = false;
    final estimated = await state.quoteShipping('01001-000');
    expect(estimated.first.estimated, isTrue);
    expect(estimated.map((option) => option.service), ['PAC', 'SEDEX']);
  });

  test('modo offline não usa a fila', () {
    final state = buildTestState();
    addTearDown(state.dispose);
    state.addToCart(state.products.first);
    final order = state.placeOrder(address: state.defaultAddress);

    expect(order.syncState, isNull);
    expect(state.pendingSyncCount, 0);
  });
}
