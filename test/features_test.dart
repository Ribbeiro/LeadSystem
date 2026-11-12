import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/core/app_theme.dart';
import 'package:leadsystem/core/external_links.dart';
import 'package:leadsystem/models/app_models.dart';
import 'package:leadsystem/models/product.dart';

import 'test_helpers.dart';

void main() {
  test('resumo do pedido para o WhatsApp traz itens, voltagem e total', () {
    final state = buildTestState();
    addTearDown(state.dispose);
    final product = state.products.firstWhere(
      (item) => item.voltageOptions.isNotEmpty,
    );
    state.addToCart(product, quantity: 2, option: '220V');
    final order = state.placeOrder(
      address: state.defaultAddress,
      paymentMethod: 'Cartão',
    );

    final text = orderSummary(order);
    expect(text, contains('*Pedido ${order.id}*'));
    expect(text, contains('2x ${product.name} (220V)'));
    expect(text, contains('Total: ${money(order.total)}'));
    expect(text, contains('CEP ${order.deliveryAddress.postalCode}'));
  });

  test('resumo do orçamento para o WhatsApp', () {
    final quote = QuoteRequest(
      id: '#ORC-2026-0001',
      productId: 'x',
      productName: 'Grill giratório',
      customerName: 'Ana',
      email: 'ana@email.com',
      phone: '(11) 90000-0000',
      details: 'Dez unidades',
      createdAt: DateTime(2026, 11, 12),
    );
    final text = quoteSummary(quote);
    expect(text, contains('*Orçamento #ORC-2026-0001*'));
    expect(text, contains('Necessidade: Dez unidades'));
  });

  test('frete estimado por região: PAC mais barato e mais lento', () {
    final saoPaulo = AppStateSync.estimateShipping('01001-000');
    final norte = AppStateSync.estimateShipping('69000-000');
    expect(saoPaulo.map((o) => o.service), ['PAC', 'SEDEX']);
    expect(saoPaulo.first.price, lessThan(saoPaulo.last.price));
    expect(saoPaulo.first.days, greaterThan(saoPaulo.last.days));
    expect(norte.first.price, greaterThan(saoPaulo.first.price));
    expect(AppStateSync.estimateShipping('123'), isEmpty);
  });

  test('tema escuro troca a paleta e é salvo no estado', () {
    final state = buildTestState();
    addTearDown(state.dispose);
    state.setThemeMode(ThemeMode.dark);
    expect(state.themeMode, ThemeMode.dark);

    expect(AppColors.usePalette(AppPalette.dark), isTrue);
    expect(AppColors.isDark, isTrue);
    expect(AppColors.surface, AppPalette.dark.surface);
    expect(AppColors.usePalette(AppPalette.light), isTrue);
    expect(AppColors.usePalette(AppPalette.light), isFalse);
  });

  test('admin não exclui a própria conta, mas exclui outra', () async {
    final state = buildTestState();
    addTearDown(state.dispose);
    await state.login(email: 'leandro@email.com', password: 'Santi@2026');
    final carlos = state.users.firstWhere((u) => u.email == 'carlos@email.com');

    expect(state.deleteUser(state.currentUser!.id), isFalse);
    expect(state.deleteUser(carlos.id), isTrue);
    expect(state.users.any((u) => u.email == 'carlos@email.com'), isFalse);
  });
}
