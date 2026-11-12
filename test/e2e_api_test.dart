// Teste de ponta a ponta: o app conversando com a API real (server/).
// Só roda quando a variável E2E_API_URL está definida:
//
//   cd server && node scripts/e2e-server.js 3999
//   E2E_API_URL=http://127.0.0.1:3999 flutter test test/e2e_api_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/models/app_models.dart';

import 'test_helpers.dart';

void main() {
  final url = Platform.environment['E2E_API_URL'];
  final skip = url == null ? 'Defina E2E_API_URL para rodar' : false;

  test('cliente compra, admin vê o pedido e muda o status', () async {
    final client = AppState(null, loadTestCatalog(), http.Client());
    final admin = AppState(null, loadTestCatalog(), http.Client());
    addTearDown(client.dispose);
    addTearDown(admin.dispose);

    expect(await client.configureServer(url), isTrue);
    expect(await admin.configureServer(url), isTrue);
    expect(client.products, hasLength(24));

    expect(
      await client.login(email: 'carlos@email.com', password: 'Cliente@2026'),
      isTrue,
    );
    final product = client.products.firstWhere((p) => p.pixPrice != null);
    final stockBefore = product.stock;
    client.addToCart(product, quantity: 2);
    client.placeOrder(address: client.defaultAddress, paymentMethod: 'Pix');
    await client.syncNow();

    final order = client.myOrders.first;
    expect(order.syncState, isNull);
    expect(order.id, matches(RegExp(r'^#SG-\d{4}-\d{4}$')));
    expect(order.total, closeTo(product.pixPrice! * 2 + order.shipping, .01));

    expect(
      await admin.login(email: 'leandro@email.com', password: 'Santi@2026'),
      isTrue,
    );
    await admin.syncNow();
    expect(admin.orders.map((o) => o.id), contains(order.id));
    expect(
      admin.products.firstWhere((p) => p.id == product.id).stock,
      stockBefore - 2,
    );

    admin.updateOrderStatus(order.id, OrderStatus.shipped, note: 'Postado.');
    await admin.syncNow();

    final shown = <String>[];
    client.onSystemNotification = (title, _) => shown.add(title);
    await client.syncNow();
    expect(client.myOrders.first.status, OrderStatus.shipped);
    expect(shown, contains('Em transporte'));
  }, skip: skip);

  test('frete da API e cadastro de nova conta', () async {
    final state = AppState(null, loadTestCatalog(), http.Client());
    addTearDown(state.dispose);
    expect(await state.configureServer(url), isTrue);

    final options = await state.quoteShipping('20040-020');
    expect(options.map((o) => o.service), ['PAC', 'SEDEX']);

    final email = 'e2e${DateTime.now().millisecondsSinceEpoch}@email.com';
    expect(
      await state.registerUser(
        name: 'Teste Ponta',
        email: email,
        phone: '(11) 97777-0000',
        password: 'Teste@2026',
      ),
      isTrue,
    );
    expect(state.currentUser?.email, email);
  }, skip: skip);
}
