import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/core/app_theme.dart';
import 'package:leadsystem/screens/admin_flows.dart';
import 'package:leadsystem/screens/app_shell.dart';
import 'package:leadsystem/screens/auth_admin.dart';
import 'package:leadsystem/screens/detail_flows.dart';
import 'package:leadsystem/screens/company_screen.dart';
import 'package:leadsystem/screens/profile_flows.dart';
import 'package:leadsystem/screens/settings_screens.dart';

import 'test_helpers.dart';

/// Abre cada tela do app em um celular pequeno e em um grande e falha
/// se qualquer exceção (incluindo overflow de layout) for lançada.
void main() {
  const sizes = <String, Size>{
    'pequeno 320x568': Size(320, 568),
    'grande 430x932': Size(430, 932),
    'escuro 390x844': Size(390, 844),
  };

  final screens = <String, Widget Function(AppState)>{
    'AppShell': (_) => const AppShell(),
    'Home': (_) => const Scaffold(body: HomeScreen()),
    'Catálogo': (_) => const Scaffold(body: CatalogScreen()),
    'Pedidos': (_) => const Scaffold(body: OrdersScreen()),
    'Ajuda': (_) => const Scaffold(body: HelpScreen()),
    'Perfil': (_) => const Scaffold(body: ProfileScreen()),
    'Login': (_) => const LoginScreen(),
    'Cadastro': (_) => const RegisterScreen(),
    'Recuperar senha': (_) =>
        const Scaffold(body: PasswordResetDialog(initialEmail: '')),
    'Painel admin': (_) => const AdminDashboardScreen(),
    'Detalhe produto': (s) => ProductDetailScreen(product: s.products.first),
    'Carrinho': (_) => const CartScreen(),
    'Checkout': (_) => const CheckoutScreen(),
    'Pedido confirmado': (s) => OrderSuccessScreen(order: s.orders.first),
    'Rastreio': (s) => TrackingScreen(order: s.orders.first),
    'Orçamento': (s) => QuoteScreen(product: s.products.first),
    'Favoritos': (_) => const FavoritesScreen(),
    'Endereços': (_) => const AddressesScreen(),
    'Notificações': (_) => const NotificationsScreen(),
    'Conta e segurança': (_) => const AccountSecurityScreen(),
    'Privacidade': (_) => const PrivacyPolicyScreen(),
    'Fale com a SantiGrill': (_) => const CompanyScreen(),
    'Servidor': (_) => const ServerSettingsScreen(),
    'Admin produtos': (_) => const ProductManagementScreen(),
    'Form produto novo': (_) => const ProductFormScreen(),
    'Form produto edição': (s) => ProductFormScreen(product: s.products.first),
    'Admin cupons': (_) => const CouponManagementScreen(),
    'Form cupom': (_) => const CouponFormScreen(),
    'Admin campanhas': (_) => const CampaignManagementScreen(),
    'Form campanha': (_) => const CampaignFormScreen(),
    'Relatórios': (_) => const AdminReportsScreen(),
    'Admin pedidos': (_) => const AdminOrdersScreen(),
    'Admin pedido detalhe': (s) =>
        AdminOrderDetailScreen(orderId: s.orders.first.id),
    'Admin categorias': (_) => const CategoryManagementScreen(),
    'Admin usuários': (_) => const UserManagementScreen(),
    'Admin orçamentos': (_) => const QuoteManagementScreen(),
  };

  for (final size in sizes.entries) {
    for (final screen in screens.entries) {
      testWidgets('${screen.key} abre sem erro (${size.key})', (tester) async {
        tester.view.physicalSize = size.value * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        final dark = size.key.startsWith('escuro');
        AppColors.usePalette(dark ? AppPalette.dark : AppPalette.light);
        addTearDown(() => AppColors.usePalette(AppPalette.light));
        final state = buildTestState();
        addTearDown(state.dispose);
        await state.login(email: 'leandro@email.com', password: 'Santi@2026');
        state.addToCart(state.products.first);

        await tester.pumpWidget(
          AppScope(
            notifier: state,
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: Builder(builder: (_) => screen.value(state)),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        // Qualquer exceção não tratada faz o teste falhar com o stack completo.
      });
    }
  }
}
