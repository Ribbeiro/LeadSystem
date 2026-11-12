// Gera capturas das telas principais com fontes e fotos reais, para revisão
// visual e documentação. Não faz parte da suíte padrão.
//
//   flutter test tool/screenshots_test.dart --update-goldens
//
// As imagens são gravadas em docs/screenshots/.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/core/app_theme.dart';
import 'package:leadsystem/screens/app_shell.dart';
import 'package:leadsystem/screens/company_screen.dart';
import 'package:leadsystem/screens/detail_flows.dart';

import '../test/test_helpers.dart';

Future<void> _loadFonts() async {
  final open = FontLoader('OpenSans');
  for (final weight in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
    open.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/OpenSans-$weight.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await open.load();
  final flutterRoot = File(
    Platform.resolvedExecutable,
  ).parent.parent.parent.parent.parent.parent.path;
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File(
            '$flutterRoot/bin/cache/artifacts/material_fonts/'
            'materialicons-regular.otf',
          ).readAsBytesSync(),
        ),
      ),
    );
  await icons.load();
}

void main() {
  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget Function(AppState state) builder, {
    Future<void> Function(AppState state)? prepare,
  }) async {
    tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final state = buildTestState();
    addTearDown(state.dispose);
    await prepare?.call(state);
    await tester.pumpWidget(
      AppScope(
        notifier: state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: RepaintBoundary(child: Builder(builder: (_) => builder(state))),
        ),
      ),
    );
    // Decodifica as imagens de verdade antes da captura.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final widget = element.widget as Image;
        await precacheImage(widget.image, element);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../docs/screenshots/$name.png'),
    );
  }

  testWidgets('inicio', (t) => shoot(t, '01_inicio', (_) => const AppShell()));
  testWidgets(
    'catalogo',
    (t) => shoot(
      t,
      '02_catalogo',
      (_) => const AppShell(),
      prepare: (s) async => s.setNavigationIndex(1),
    ),
  );
  testWidgets(
    'produto',
    (t) => shoot(
      t,
      '03_produto',
      (s) => ProductDetailScreen(
        product: s.products.firstWhere((p) => p.voltageOptions.isNotEmpty),
      ),
    ),
  );
  testWidgets(
    'carrinho',
    (t) => shoot(
      t,
      '04_carrinho',
      (_) => const CartScreen(),
      prepare: (s) async {
        s.addToCart(s.products[0]);
        s.addToCart(s.products[6], quantity: 2);
      },
    ),
  );
  testWidgets(
    'checkout',
    (t) => shoot(
      t,
      '05_checkout',
      (_) => const CheckoutScreen(),
      prepare: (s) async {
        await s.login(email: 'carlos@email.com', password: 'Cliente@2026');
        s.addToCart(s.products[0]);
      },
    ),
  );
  testWidgets(
    'pedidos',
    (t) => shoot(
      t,
      '06_pedidos',
      (_) => const AppShell(),
      prepare: (s) async {
        await s.login(email: 'carlos@email.com', password: 'Cliente@2026');
        s.setNavigationIndex(2);
      },
    ),
  );
  testWidgets(
    'ajuda',
    (t) => shoot(
      t,
      '07_ajuda',
      (_) => const AppShell(),
      prepare: (s) async => s.setNavigationIndex(3),
    ),
  );
  testWidgets(
    'contato',
    (t) => shoot(t, '08_contato', (_) => const CompanyScreen()),
  );
}
