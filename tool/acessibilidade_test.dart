// Auditoria de acessibilidade das telas principais com as diretrizes do
// flutter_test (área de toque, rótulos para leitor de tela e contraste).
// Uso: flutter test tool/acessibilidade_test.dart
// O resultado de cada tela e diretriz é impresso como "A11Y|tela|diretriz|ok|motivo".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/core/app_theme.dart';
import 'package:leadsystem/screens/app_shell.dart';
import 'package:leadsystem/screens/auth_admin.dart';
import 'package:leadsystem/screens/detail_flows.dart';

import '../test/test_helpers.dart';

void main() {
  final screens = <String, Widget Function(AppState)>{
    'Início': (_) => const AppShell(),
    'Catálogo': (_) => const Scaffold(body: CatalogScreen()),
    'Detalhe do produto': (s) => ProductDetailScreen(product: s.products.first),
    'Carrinho': (_) => const CartScreen(),
    'Orçamento': (s) => QuoteScreen(product: s.products.first),
    'Login': (_) => const LoginScreen(),
    'Cadastro': (_) => const RegisterScreen(),
    'Pedidos': (_) => const Scaffold(body: OrdersScreen()),
    'Ajuda': (_) => const Scaffold(body: HelpScreen()),
  };
  final guidelines = <String, AccessibilityGuideline>{
    'Área de toque Android (48 dp)': androidTapTargetGuideline,
    'Área de toque iOS (44 pt)': iOSTapTargetGuideline,
    'Rótulo em elementos tocáveis': labeledTapTargetGuideline,
    'Contraste de texto (WCAG AA)': textContrastGuideline,
  };

  for (final entry in screens.entries) {
    testWidgets('acessibilidade – ${entry.key}', (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final state = buildTestState();
      addTearDown(state.dispose);
      if (entry.key == 'Carrinho') {
        state.addToCart(state.products.first, quantity: 2);
      }
      await tester.pumpWidget(
        AppScope(
          notifier: state,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(builder: (_) => entry.value(state)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      for (final g in guidelines.entries) {
        final result = await g.value.evaluate(tester);
        final text = (result.reason ?? '').replaceAll('\n', ' ');
        final reason = result.passed
            ? ''
            : text.substring(0, text.length.clamp(0, 400));
        // ignore: avoid_print
        print('A11Y|${entry.key}|${g.key}|${result.passed}|$reason');
      }
      handle.dispose();
    });
  }
}
