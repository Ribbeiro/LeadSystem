import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/core/background_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final orders = [
    {'id': '#SG-2026-0001', 'status': 'shipped', 'customerName': 'Carlos'},
    {'id': '#SG-2026-0002', 'status': 'received', 'customerName': 'Ana'},
  ];

  test('primeira execução só registra, sem avisar', () {
    expect(
      BackgroundSync.detectChanges(seen: {}, orders: orders, admin: false),
      isEmpty,
    );
  });

  test('cliente é avisado da mudança de status', () {
    final notices = BackgroundSync.detectChanges(
      seen: {'#SG-2026-0001': 'received', '#SG-2026-0002': 'received'},
      orders: orders,
      admin: false,
    );
    expect(notices, [
      ('Em transporte', 'Seu pedido #SG-2026-0001 está: Em transporte.'),
    ]);
  });

  test('admin é avisado de pedido novo', () {
    final notices = BackgroundSync.detectChanges(
      seen: {'#SG-2026-0001': 'shipped'},
      orders: orders,
      admin: true,
    );
    expect(notices.single.$1, 'Novo pedido');
    expect(notices.single.$2, contains('Ana'));
  });

  test('status vistos são salvos e relidos', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await BackgroundSync.writeSeen(preferences, orders);
    expect(BackgroundSync.readSeen(preferences), {
      '#SG-2026-0001': 'shipped',
      '#SG-2026-0002': 'received',
    });
  });
}
