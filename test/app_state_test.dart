import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/models/app_models.dart';
import 'package:leadsystem/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Carrinho e cupom', () {
    test('limita o carrinho ao estoque e aplica cupom ativo', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      final product = state.products.first;

      state.addToCart(product, quantity: product.stock + 20);

      expect(state.cart[product.id], product.stock);
      expect(state.applyCoupon('primeiracompra'), isTrue);
      expect(state.discount, closeTo(state.subtotal * .10, .001));
    });

    test('recalcula subtotal ao alterar e remover itens', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      final a = state.products[0];
      final b = state.products[1];

      state.addToCart(a, quantity: 2);
      state.addToCart(b);
      expect(state.subtotal, closeTo(a.salePrice * 2 + b.salePrice, .001));
      expect(state.cartCount, 3);

      state.setQuantity(a.id, 1);
      expect(state.subtotal, closeTo(a.salePrice + b.salePrice, .001));

      state.setQuantity(b.id, 0);
      expect(state.cart.containsKey(b.id), isFalse);
      expect(state.subtotal, closeTo(a.salePrice, .001));
    });

    test('não adiciona produto esgotado', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      final product = state.products.first.copyWith(stock: 0);
      state.upsertProduct(product);

      expect(state.addToCart(state.productById(product.id)), 0);
      expect(state.cart, isEmpty);
    });

    test('rejeita cupom inexistente', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      state.addToCart(state.products.first);

      expect(state.applyCoupon('NAOEXISTE'), isFalse);
      expect(state.discount, 0);
    });

    test('guarda a voltagem escolhida e grava no pedido', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      final product = state.products.firstWhere(
        (item) => item.voltageOptions.length > 1,
      );

      state.addToCart(product, option: product.voltageOptions.last);
      final order = state.placeOrder(
        address: state.defaultAddress,
        paymentMethod: 'Cartão',
      );

      expect(order.items.single.option, product.voltageOptions.last);
    });
  });

  group('Pagamento', () {
    test('Pix aplica o preço à vista publicado no site', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      final product = state.products.firstWhere(
        (item) => item.pixPrice != null,
      );
      state.addToCart(product, quantity: 2);

      final expected = (product.price - product.pixPrice!) * 2;
      expect(state.pixDiscount, closeTo(expected, .001));
      expect(state.totalFor('Pix'), closeTo(state.total - expected, .001));
      expect(state.totalFor('Cartão'), closeTo(state.total, .001));

      final order = state.placeOrder(
        address: state.defaultAddress,
        paymentMethod: 'Pix',
      );
      expect(
        order.total,
        closeTo(product.pixPrice! * 2 + order.shipping, .001),
      );
    });

    test('checkout cria pedido completo e baixa o estoque', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      final product = state.products[2];
      final previousStock = product.stock;
      state.addToCart(product, quantity: 2);

      final order = state.placeOrder(
        address: state.defaultAddress,
        paymentMethod: 'Pix',
      );

      expect(order.items, hasLength(1));
      expect(order.items.single.quantity, 2);
      expect(order.items.single.image, product.coverImage);
      expect(order.paymentMethod, 'Pix');
      expect(order.status, OrderStatus.received);
      expect(state.orders.first.id, order.id);
      expect(state.cart, isEmpty);
      expect(state.productById(product.id).stock, previousStock - 2);
    });

    test('checkout falha com carrinho vazio', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      expect(
        () => state.placeOrder(address: state.defaultAddress),
        throwsStateError,
      );
    });
  });

  group('Busca e filtros', () {
    test('busca ignora acentos e maiúsculas', () {
      final state = buildTestState();
      addTearDown(state.dispose);

      state.setSearch('GIRATORIO');
      final semAcento = state.filteredProducts.length;
      state.setSearch('giratório');

      expect(semAcento, greaterThan(0));
      expect(state.filteredProducts.length, semAcento);
    });

    test('busca com vários termos exige todos', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      state.setSearch('grelha parrilheira');

      expect(state.filteredProducts, isNotEmpty);
      for (final product in state.filteredProducts) {
        final text = foldText('${product.name} ${product.description}');
        expect(text, contains('grelha'));
        expect(text, contains('parrilheira'));
      }
    });

    test('filtra por categoria e ordena por preço', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      state.setCategory('Espetos');
      state.setProductSort(ProductSort.priceLowToHigh);

      final prices = state.filteredProducts.map((p) => p.salePrice).toList();
      expect(prices, isNotEmpty);
      expect(
        state.filteredProducts.every((p) => p.category == 'Espetos'),
        isTrue,
      );
      expect(prices, [...prices]..sort());
    });

    test('categoria inexistente volta para Todos', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      state.setCategory('Categoria fantasma');
      expect(state.category, 'Todos');
    });
  });

  group('Conta e privacidade', () {
    test('autentica somente uma credencial local válida', () async {
      final state = buildTestState();
      addTearDown(state.dispose);

      expect(
        await state.login(
          email: 'leandro@email.com',
          password: 'senha-incorreta',
        ),
        isFalse,
      );
      expect(state.loggedIn, isFalse);
      expect(
        await state.login(email: 'leandro@email.com', password: 'Santi@2026'),
        isTrue,
      );
      expect(state.isAdmin, isTrue);
    });

    test('cadastra usuário e permite redefinir sua senha', () async {
      final state = buildTestState();
      addTearDown(state.dispose);

      expect(
        await state.registerUser(
          name: 'Maria da Silva',
          email: 'maria@email.com',
          phone: '(11) 98888-7777',
          password: 'Maria@2026',
        ),
        isTrue,
      );
      expect(state.userEmail, 'maria@email.com');
      state.logout();

      expect(
        await state.resetPassword(
          email: 'maria@email.com',
          newPassword: 'Nova@2026',
        ),
        isTrue,
      );
      expect(
        await state.login(email: 'maria@email.com', password: 'Nova@2026'),
        isTrue,
      );
    });

    test('cliente vê apenas os próprios pedidos', () async {
      final state = buildTestState();
      addTearDown(state.dispose);

      await state.login(email: 'carlos@email.com', password: 'Cliente@2026');
      final carlosOrders = state.myOrders.length;
      expect(carlosOrders, greaterThan(0));
      state.logout();

      await state.registerUser(
        name: 'Maria da Silva',
        email: 'maria@email.com',
        phone: '(11) 98888-7777',
        password: 'Maria@2026',
      );
      expect(state.myOrders, isEmpty);
      state.addToCart(state.products.first);
      final order = state.placeOrder(address: state.defaultAddress);

      expect(state.myOrders.map((item) => item.id), [order.id]);
      expect(state.orders.length, carlosOrders + 1);
    });
  });

  group('Administração', () {
    test('orçamento fica disponível e recebe resposta administrativa', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      final product = state.products.first;

      final quote = state.submitQuote(
        product: product,
        customerName: 'João Pereira',
        email: 'joao@email.com',
        phone: '(11) 97777-1111',
        details: 'Preciso de duas unidades para um evento corporativo.',
      );
      state.updateQuoteStatus(
        quote.id,
        QuoteStatus.approved,
        response: 'Proposta aprovada e enviada ao cliente.',
      );

      final saved = state.quotes.firstWhere((item) => item.id == quote.id);
      expect(saved.status, QuoteStatus.approved);
      expect(saved.response, contains('aprovada'));
    });

    test('atualização administrativa registra etapa no pedido', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      final order = state.orders.first;
      final previousEvents = order.timeline.length;

      state.updateOrderStatus(
        order.id,
        OrderStatus.delivered,
        note: 'Recebido pelo cliente.',
      );

      final updated = state.orders.firstWhere((item) => item.id == order.id);
      expect(updated.status, OrderStatus.delivered);
      expect(updated.timeline, hasLength(previousEvents + 1));
      expect(updated.timeline.last.note, 'Recebido pelo cliente.');
    });

    test('não remove categoria com produtos vinculados', () {
      final state = buildTestState();
      addTearDown(state.dispose);
      expect(state.removeCategory(state.products.first.category), isFalse);
    });
  });

  group('Persistência', () {
    test('restaura sessão, carrinho, voltagem e favoritos', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await AppState.initialize();
      final product = first.products.firstWhere(
        (item) => item.voltageOptions.length > 1,
      );
      await first.login(
        email: 'leandro@email.com',
        password: 'Santi@2026',
        remember: true,
      );
      first.addToCart(product, quantity: 2, option: '220V');
      first.toggleFavorite(product.id);
      await first.flush();
      first.dispose();

      final restored = await AppState.initialize();
      addTearDown(restored.dispose);

      expect(restored.loggedIn, isTrue);
      expect(restored.userEmail, 'leandro@email.com');
      expect(restored.cart[product.id], 2);
      expect(restored.cartOption(product.id), '220V');
      expect(restored.favorites, contains(product.id));
    });

    test('dados de versão antiga são migrados para o catálogo real', () async {
      // Estado salvo pela versão anterior do app (catálogo fictício).
      SharedPreferences.setMockInitialValues({
        'leadsystem_state_v2': jsonEncode({
          'version': 2,
          'products': [
            {
              'id': 'KIT-008',
              'name': 'Kit Churrasco Profissional',
              'price': 189.9,
              'stock': 8,
              'imageQuadrant': 3,
            },
          ],
          'categories': ['Kits'],
          'cart': {'KIT-008': 2},
          'favorites': ['KIT-008'],
        }),
      });

      final state = await AppState.initialize();
      addTearDown(state.dispose);

      expect(state.products.length, loadTestCatalog().products.length);
      expect(state.findProductById('KIT-008'), isNull);
      expect(state.cart, isEmpty);
      expect(state.favorites, isEmpty);
      expect(state.categories, isNot(contains('Kits')));
    });

    test('dados corrompidos são restaurados sem travar o app', () async {
      SharedPreferences.setMockInitialValues({
        'leadsystem_state_v2': '{json inválido',
      });
      final state = await AppState.initialize();
      addTearDown(state.dispose);

      expect(state.products, isNotEmpty);
      expect(state.consumeStartupNotice(), contains('restaurados'));
      expect(state.consumeStartupNotice(), isNull);
    });
  });

  group('Formatação', () {
    test('formata moeda em reais', () {
      expect(money(1234.5), r'R$ 1.234,50');
      expect(money(55), r'R$ 55,00');
    });
  });
}
