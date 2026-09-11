import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppState', () {
    test('limita o carrinho ao estoque e aplica cupom ativo', () {
      final state = AppState();
      addTearDown(state.dispose);
      final product = state.productById('KIT-008');

      state.addToCart(product, quantity: product.stock + 20);

      expect(state.cart[product.id], product.stock);
      expect(state.applyCoupon('primeiracompra'), isTrue);
      expect(state.discount, closeTo(state.subtotal * .10, .001));
    });

    test('autentica somente uma credencial local válida', () async {
      final state = AppState();
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
      final state = AppState();
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

    test('checkout cria pedido completo e baixa o estoque', () {
      final state = AppState();
      addTearDown(state.dispose);
      final product = state.productById('ESP-004');
      final previousStock = product.stock;
      state.addToCart(product, quantity: 2);

      final order = state.placeOrder(
        address: state.defaultAddress,
        paymentMethod: 'Pix',
      );

      expect(order.items, hasLength(1));
      expect(order.items.single.quantity, 2);
      expect(order.paymentMethod, 'Pix');
      expect(order.status, OrderStatus.received);
      expect(state.orders.first.id, order.id);
      expect(state.cart, isEmpty);
      expect(state.productById(product.id).stock, previousStock - 2);
    });

    test('orçamento fica disponível e recebe resposta administrativa', () {
      final state = AppState();
      addTearDown(state.dispose);
      final product = state.productById('CHU-001');

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
      final state = AppState();
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

    test('restaura sessão, carrinho e favoritos após reiniciar', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await AppState.initialize();
      final product = first.productById('GRE-002');
      await first.login(
        email: 'leandro@email.com',
        password: 'Santi@2026',
        remember: true,
      );
      first.addToCart(product, quantity: 2);
      first.toggleFavorite(product.id);
      await first.flush();
      first.dispose();

      final restored = await AppState.initialize();
      addTearDown(restored.dispose);

      expect(restored.loggedIn, isTrue);
      expect(restored.userEmail, 'leandro@email.com');
      expect(restored.cart[product.id], 2);
      expect(restored.favorites, contains(product.id));
    });
  });
}
