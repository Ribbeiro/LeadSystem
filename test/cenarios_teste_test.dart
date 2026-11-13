// Cenários de teste do relatório (Capítulo 8 – Cenário de Teste).
// Cada teste corresponde a um cenário CT01–CT14 (Dado que / Quando / Então).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/core/app_theme.dart';
import 'package:leadsystem/models/app_models.dart';
import 'package:leadsystem/models/product.dart';
import 'package:leadsystem/screens/admin_flows.dart';
import 'package:leadsystem/screens/detail_flows.dart';

import 'test_helpers.dart';

AppState _state() {
  final state = buildTestState();
  addTearDown(state.dispose);
  return state;
}

Product _produto(String id, {double price = 189.90, int stock = 10}) => Product(
  id: id,
  name: 'Produto de teste $id',
  shortName: 'Produto $id',
  category: 'Grelhas',
  description: 'Produto criado para o cenário de teste.',
  price: price,
  stock: stock,
);

Future<void> _pump(
  WidgetTester tester,
  AppState state,
  Widget screen, {
  double height = 932,
}) async {
  // Tela alta o bastante para os formulários (ListView) montarem tudo.
  tester.view.physicalSize = Size(430 * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppScope(
      notifier: state,
      child: MaterialApp(theme: AppTheme.light, home: screen),
    ),
  );
  await tester.pump();
}

void main() {
  group('UC01 – Cadastrar cliente', () {
    test('CT01 – senha fraca não cria a conta (NF1.4)', () async {
      final state = _state();
      final ok = await state.registerUser(
        name: 'Ana Souza',
        email: 'ana@email.com',
        phone: '(11) 97777-0000',
        password: 'senha123',
      );
      expect(ok, isFalse);
      expect(state.lastAuthMessage, contains('8 caracteres'));
      expect(state.users.any((u) => u.email == 'ana@email.com'), isFalse);
    });

    test('CT02 – e-mail repetido com maiúsculas e espaços (NF1.2)', () async {
      final state = _state();
      await state.registerUser(
        name: 'Cliente Santi',
        email: 'cliente@santigrill.com',
        phone: '(11) 97777-0000',
        password: 'Senha@2026',
      );
      state.logout();
      final ok = await state.registerUser(
        name: 'Outro Cliente',
        email: ' Cliente@SantiGrill.com ',
        phone: '(11) 96666-0000',
        password: 'Senha@2026',
      );
      expect(ok, isFalse);
      expect(state.lastAuthMessage, 'Já existe uma conta com este e-mail.');
    });
  });

  group('UC02 – Autenticar usuário', () {
    test('CT03 – conta bloqueada não entra (NF2.1)', () async {
      final state = _state();
      final carlos = state.users.firstWhere(
        (u) => u.email == 'carlos@email.com',
      );
      state.setUserBlocked(carlos.id, true);
      final ok = await state.login(
        email: 'carlos@email.com',
        password: 'Cliente@2026',
      );
      expect(ok, isFalse);
      expect(state.loggedIn, isFalse);
    });
  });

  group('UC03 – Consultar produtos', () {
    test('CT04 – produto inativo não aparece na busca (NF4.2)', () {
      final state = _state();
      final grelha = state.products.firstWhere((p) => p.category == 'Grelhas');
      state.upsertProduct(grelha.copyWith(active: false));
      state.setSearch('grelha');
      expect(
        state.filteredProducts.map((p) => p.id),
        isNot(contains(grelha.id)),
      );
    });

    test('CT05 – CEP com menos de 8 dígitos é recusado (NF5.2)', () {
      final state = _state();
      expect(state.calculateShipping('0978-000'), isNull);
      expect(AppStateSync.estimateShipping('0978-000'), isEmpty);
    });
  });

  group('UC04 – Carrinho e cupom', () {
    test('CT06 – quantidade limitada ao estoque (NF6.1)', () {
      final state = _state();
      state.upsertProduct(_produto('ct06', stock: 2));
      state.addToCart(state.productById('ct06'), quantity: 3);
      expect(state.cart['ct06'], 2);
    });

    test('CT07 – cupom de 10% e frete de R\$ 24,90 (NF7.2, NF6.2)', () {
      final state = _state();
      state.upsertProduct(_produto('ct07'));
      state.addToCart(state.productById('ct07'), quantity: 3);
      expect(state.applyCoupon('PRIMEIRACOMPRA'), isTrue);
      expect(state.subtotal, closeTo(569.70, .001));
      expect(state.discount, closeTo(56.97, .001));
      expect(state.shipping, closeTo(24.90, .001));
      expect(state.total, closeTo(537.63, .001));
    });
  });

  group('UC05 – Finalizar pedido', () {
    test('CT08 – baixa de estoque e carrinho vazio (NF8.4)', () {
      final state = _state();
      state.upsertProduct(_produto('ct08'));
      state.addToCart(state.productById('ct08'), quantity: 2);
      final order = state.placeOrder(address: state.defaultAddress);
      expect(state.orders.first.id, order.id);
      expect(state.productById('ct08').stock, 8);
      expect(state.cart, isEmpty);
    });
  });

  group('UC06 – Solicitar orçamento', () {
    testWidgets('CT09 – detalhes curtos bloqueiam o envio (NF9.1)', (t) async {
      final state = _state();
      await state.login(email: 'carlos@email.com', password: 'Cliente@2026');
      final before = state.quotes.length;
      await _pump(t, state, QuoteScreen(product: state.products.first));
      await t.enterText(find.byType(TextFormField).last, 'quero');
      await t.ensureVisible(find.text('Enviar orçamento'));
      await t.tap(find.text('Enviar orçamento'));
      await t.pump();
      expect(
        find.text('Descreva a quantidade e a necessidade do orçamento.'),
        findsOneWidget,
      );
      expect(state.quotes.length, before);
    });
  });

  group('UC09 – Manter produtos e categorias', () {
    testWidgets('CT10 – código (SKU) repetido é recusado (NF13.1)', (t) async {
      final state = _state();
      await state.login(email: 'leandro@email.com', password: 'Santi@2026');
      final existing = state.products.first.id;
      await _pump(t, state, const ProductFormScreen(), height: 3200);
      await t.enterText(find.byType(TextFormField).first, existing);
      await t.tap(find.widgetWithText(FilledButton, 'Cadastrar produto'));
      await t.pump();
      expect(find.text('Já existe um produto com este SKU.'), findsOneWidget);
    });

    test('CT11 – categoria com produtos não é removida (NF14.1)', () {
      final state = _state();
      expect(state.removeCategory('Grelhas'), isFalse);
      expect(state.categories, contains('Grelhas'));
    });
  });

  group('UC10 – Gerenciar pedidos e orçamentos', () {
    test('CT12 – nova etapa preserva a linha do tempo (NF15.1)', () {
      final state = _state();
      state.upsertProduct(_produto('ct12'));
      state.addToCart(state.productById('ct12'));
      final order = state.placeOrder(address: state.defaultAddress);
      expect(order.timeline, hasLength(1));
      state.updateOrderStatus(
        order.id,
        OrderStatus.preparing,
        note: 'Separando',
      );
      final updated = state.orders.firstWhere((o) => o.id == order.id);
      expect(updated.timeline, hasLength(2));
      expect(updated.timeline.last.note, 'Separando');
    });
  });

  group('UC11 – Manter cupons e campanhas', () {
    for (final value in ['0', '120']) {
      testWidgets('CT13 – percentual $value% é recusado (NF16.1)', (t) async {
        final state = _state();
        await _pump(t, state, const CouponFormScreen(), height: 2000);
        await t.enterText(
          find.widgetWithText(TextFormField, 'Código'),
          'TESTE10',
        );
        await t.enterText(
          find.widgetWithText(TextFormField, 'Descrição'),
          'Cupom do cenário de teste',
        );
        await t.enterText(
          find.widgetWithText(TextFormField, 'Desconto'),
          value,
        );
        await t.tap(find.widgetWithText(FilledButton, 'Criar cupom'));
        await t.pump();
        expect(find.text('Use 1 a 100.'), findsOneWidget);
        expect(state.coupons.any((c) => c.code == 'TESTE10'), isFalse);
      });
    }
  });

  group('UC12 – Gerenciar usuários', () {
    test('CT14 – bloquear conta conectada encerra a sessão (NF17.2)', () async {
      final state = _state();
      await state.login(email: 'carlos@email.com', password: 'Cliente@2026');
      expect(state.loggedIn, isTrue);
      state.setUserBlocked(state.currentUser!.id, true);
      expect(state.loggedIn, isFalse);
    });
  });
}
