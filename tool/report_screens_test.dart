// Gera as capturas de tela usadas no relatório (docs/relatorio_telas/).
//
//   flutter test tool/report_screens_test.dart --update-goldens
//
// Usa apenas dados de demonstração (contas leandro@email.com e
// carlos@email.com, catálogo real do site).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/core/app_theme.dart';
import 'package:leadsystem/screens/admin_flows.dart';
import 'package:leadsystem/screens/app_shell.dart';
import 'package:leadsystem/screens/auth_admin.dart';
import 'package:leadsystem/screens/company_screen.dart';
import 'package:leadsystem/screens/detail_flows.dart';
import 'package:leadsystem/screens/profile_flows.dart';
import 'package:leadsystem/screens/settings_screens.dart';

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

/// Servidor simulado só para as telas que mostram o modo conectado.
http.Client _fakeServer() => MockClient((request) async {
  final path = request.url.path;
  Map<String, Object?> body = {};
  if (path == '/health') body = {'status': 'ok'};
  if (path == '/api/products') body = {'data': <Object>[]};
  if (path == '/api/auth/password/forgot') {
    body = {
      'message':
          'Se o e-mail estiver cadastrado, enviaremos um código em instantes.',
    };
  }
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
});

void main() {
  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget Function(AppState state) builder, {
    Future<void> Function(AppState state)? prepare,
    Future<void> Function(WidgetTester tester, AppState state)? act,
    bool dark = false,
    bool online = false,
  }) async {
    tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    AppColors.usePalette(dark ? AppPalette.dark : AppPalette.light);
    addTearDown(() => AppColors.usePalette(AppPalette.light));
    final state = online
        ? AppState(null, loadTestCatalog(), _fakeServer())
        : buildTestState();
    addTearDown(state.dispose);
    if (online) {
      await tester.runAsync(() => state.configureServer('192.168.0.10:3000'));
      state.setForeground(false);
    }
    await prepare?.call(state);
    // A fronteira envolve o app inteiro para incluir diálogos (overlay).
    await tester.pumpWidget(
      RepaintBoundary(
        child: AppScope(
          notifier: state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Builder(builder: (_) => builder(state)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    if (act != null) {
      await act(tester, state);
      await tester.pump(const Duration(milliseconds: 600));
    }
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final widget = element.widget as Image;
        await precacheImage(widget.image, element);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../docs/relatorio_telas/$name.png'),
    );
  }

  Future<void> asClient(AppState s) =>
      s.login(email: 'carlos@email.com', password: 'Cliente@2026');
  Future<void> asAdmin(AppState s) =>
      s.login(email: 'leandro@email.com', password: 'Santi@2026');

  Future<void> scrollDown(WidgetTester t, double dy) async {
    await t.drag(find.byType(Scrollable).first, Offset(0, -dy));
    await t.pump(const Duration(milliseconds: 300));
  }

  // ---------------------------------------------------------------- acesso
  testWidgets(
    'login',
    (t) => shoot(t, 'a01_login', (_) => const LoginScreen()),
  );
  testWidgets(
    'cadastro com validação',
    (t) => shoot(
      t,
      'a02_cadastro_validacao',
      (_) => const RegisterScreen(),
      act: (t, _) async {
        await t.enterText(find.byType(TextFormField).at(0), 'Ana');
        await t.enterText(find.byType(TextFormField).at(1), 'ana@email');
        await t.enterText(find.byType(TextFormField).at(3), 'senha');
        await t.ensureVisible(find.text('Criar conta').last);
        await t.tap(find.text('Criar conta').last);
        await t.pump();
        await t.drag(find.byType(Scrollable).first, const Offset(0, 600));
      },
    ),
  );
  testWidgets(
    'senha - pedir código',
    (t) => shoot(
      t,
      'a03_senha_email',
      (_) => const Scaffold(
        body: PasswordResetDialog(initialEmail: 'carlos@email.com'),
      ),
      online: true,
    ),
  );
  testWidgets(
    'senha - informar código',
    (t) => shoot(
      t,
      'a04_senha_codigo',
      (_) => const Scaffold(
        body: PasswordResetDialog(initialEmail: 'carlos@email.com'),
      ),
      online: true,
      act: (t, s) async {
        await t.tap(find.text('Enviar código'));
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump(const Duration(milliseconds: 300));
        await t.enterText(find.byType(TextFormField).at(1), '482915');
      },
    ),
  );

  // ---------------------------------------------------------------- cliente
  testWidgets('inicio', (t) => shoot(t, 'b01_inicio', (_) => const AppShell()));
  testWidgets(
    'catalogo menor preço',
    (t) => shoot(
      t,
      'b02_catalogo',
      (_) => const AppShell(),
      prepare: (s) async {
        s.setNavigationIndex(1);
        s.setCategory('Espetos');
      },
    ),
  );
  testWidgets(
    'produto',
    (t) => shoot(
      t,
      'b03_produto',
      (s) => ProductDetailScreen(
        product: s.products.firstWhere((p) => p.voltageOptions.isNotEmpty),
      ),
    ),
  );
  testWidgets(
    'produto - medidas e frete',
    (t) => shoot(
      t,
      'b04_produto_frete',
      (s) => ProductDetailScreen(
        product: s.products.firstWhere((p) => p.voltageOptions.isNotEmpty),
      ),
      act: (t, _) async {
        await t.scrollUntilVisible(
          find.text('Calcular'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await t.enterText(find.byType(TextField).first, '01001000');
        await t.tap(find.text('Calcular'));
        await t.pump();
        await t.ensureVisible(find.text('Calcule o frete'));
        await t.drag(find.byType(Scrollable).first, const Offset(0, 260));
      },
    ),
  );
  testWidgets(
    'orçamento',
    (t) => shoot(
      t,
      'b05_orcamento',
      (s) => QuoteScreen(product: s.products[4]),
      prepare: asClient,
      act: (t, _) async {
        final fields = find.byType(TextFormField);
        await t.enterText(
          fields.last,
          '10 unidades para um buffet em Santo André, entrega em dezembro.',
        );
      },
    ),
  );
  testWidgets(
    'orçamento enviado',
    (t) => shoot(
      t,
      'b06_orcamento_enviado',
      (s) => QuoteScreen(product: s.products[4]),
      prepare: asClient,
      act: (t, _) async {
        await t.enterText(
          find.byType(TextFormField).last,
          '10 unidades para um buffet em Santo André, entrega em dezembro.',
        );
        await t.ensureVisible(find.text('Enviar orçamento'));
        await t.pump();
        await t.tap(find.widgetWithText(FilledButton, 'Enviar orçamento'));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
        expect(find.text('Orçamento enviado'), findsOneWidget);
      },
    ),
  );
  testWidgets(
    'carrinho com cupom',
    (t) => shoot(
      t,
      'b07_carrinho',
      (_) => const CartScreen(),
      prepare: (s) async {
        s.addToCart(s.products[0]);
        s.addToCart(s.products[6], quantity: 2);
        s.applyCoupon('PRIMEIRACOMPRA');
      },
    ),
  );
  testWidgets(
    'checkout',
    (t) => shoot(
      t,
      'b08_checkout',
      (_) => const CheckoutScreen(),
      prepare: (s) async {
        await asClient(s);
        s.addToCart(s.products[0]);
      },
      act: (t, _) => scrollDown(t, 420),
    ),
  );
  testWidgets(
    'pedido confirmado',
    (t) => shoot(
      t,
      'b09_pedido_confirmado',
      (s) => OrderSuccessScreen(order: s.orders.first),
      prepare: asClient,
    ),
  );
  testWidgets(
    'acompanhamento',
    (t) => shoot(
      t,
      'b10_acompanhamento',
      (s) => TrackingScreen(order: s.orders.first),
      prepare: asClient,
    ),
  );
  testWidgets(
    'pedidos',
    (t) => shoot(
      t,
      'b11_pedidos',
      (_) => const AppShell(),
      prepare: (s) async {
        await asClient(s);
        s.submitQuote(
          product: s.products[4],
          customerName: 'Carlos Silva',
          email: 'carlos@email.com',
          phone: '(11) 98888-1111',
          details: '10 unidades para um buffet em Santo André.',
        );
        s.setNavigationIndex(2);
      },
    ),
  );
  testWidgets(
    'fale conosco',
    (t) => shoot(t, 'b12_fale_conosco', (_) => const CompanyScreen()),
  );
  testWidgets(
    'perfil',
    (t) => shoot(
      t,
      'b13_perfil',
      (_) => const AppShell(),
      prepare: (s) async {
        await asClient(s);
        s.setNavigationIndex(4);
      },
    ),
  );
  testWidgets(
    'endereços',
    (t) => shoot(
      t,
      'b14_enderecos',
      (_) => const AddressesScreen(),
      prepare: asClient,
    ),
  );
  testWidgets(
    'notificações',
    (t) => shoot(
      t,
      'b15_notificacoes',
      (_) => const NotificationsScreen(),
      prepare: asClient,
    ),
  );
  testWidgets(
    'conta',
    (t) => shoot(
      t,
      'b16_conta',
      (_) => const AccountSecurityScreen(),
      prepare: asClient,
    ),
  );
  testWidgets(
    'ajuda',
    (t) => shoot(
      t,
      'b17_ajuda',
      (_) => const AppShell(),
      prepare: (s) async => s.setNavigationIndex(3),
    ),
  );
  testWidgets(
    'assistente',
    (t) => shoot(
      t,
      'b18_assistente',
      (_) => const AppShell(),
      prepare: (s) async {
        s.setNavigationIndex(3);
        s.sendMessage('Qual o prazo para trocar um produto?');
      },
      act: (t, _) async {
        await t.scrollUntilVisible(
          find.textContaining('Digite sua mensagem'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await scrollDown(t, 120);
      },
    ),
  );

  // ---------------------------------------------------------------- admin
  testWidgets(
    'painel',
    (t) => shoot(
      t,
      'c01_painel',
      (_) => const AdminDashboardScreen(),
      prepare: asAdmin,
    ),
  );
  testWidgets(
    'relatórios',
    (t) => shoot(
      t,
      'c02_relatorios',
      (_) => const AdminReportsScreen(),
      prepare: asAdmin,
    ),
  );
  testWidgets(
    'produtos',
    (t) => shoot(
      t,
      'c03_produtos',
      (_) => const ProductManagementScreen(),
      prepare: asAdmin,
    ),
  );
  testWidgets(
    'form produto',
    (t) => shoot(
      t,
      'c04_form_produto',
      (s) => ProductFormScreen(product: s.products[4]),
      prepare: asAdmin,
      act: (t, _) => scrollDown(t, 1150),
    ),
  );
  testWidgets(
    'cupom',
    (t) => shoot(
      t,
      'c05_cupom',
      (_) => const CouponFormScreen(),
      prepare: asAdmin,
    ),
  );
  testWidgets(
    'campanha validação',
    (t) => shoot(
      t,
      'c06_campanha',
      (_) => const CampaignFormScreen(),
      prepare: asAdmin,
      act: (t, _) async {
        final save = find.byType(FilledButton).last;
        await t.ensureVisible(save);
        await t.tap(save);
        await t.pump();
        await t.drag(find.byType(Scrollable).first, const Offset(0, 900));
      },
    ),
  );
  testWidgets(
    'pedido admin',
    (t) => shoot(
      t,
      'c07_pedido_admin',
      (s) => AdminOrderDetailScreen(orderId: s.orders.first.id),
      prepare: asAdmin,
      act: (t, _) => scrollDown(t, 520),
    ),
  );
  testWidgets(
    'orçamento admin',
    (t) => shoot(
      t,
      'c08_orcamento_admin',
      (s) => QuoteDetailScreen(quoteId: s.quotes.first.id),
      prepare: asAdmin,
    ),
  );
  testWidgets(
    'usuários',
    (t) => shoot(
      t,
      'c09_usuarios',
      (_) => const UserManagementScreen(),
      prepare: asAdmin,
    ),
  );
  testWidgets(
    'servidor',
    (t) => shoot(
      t,
      'c10_servidor',
      (_) => const ServerSettingsScreen(),
      online: true,
    ),
  );

  // ---------------------------------------------------------------- escuro
  testWidgets(
    'início escuro',
    (t) => shoot(t, 'd01_inicio_escuro', (_) => const AppShell(), dark: true),
  );
  testWidgets(
    'produto escuro',
    (t) => shoot(
      t,
      'd02_produto_escuro',
      (s) => ProductDetailScreen(product: s.products[16]),
      dark: true,
    ),
  );
}
