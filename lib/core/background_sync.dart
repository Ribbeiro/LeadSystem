import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/app_models.dart';
import 'api_client.dart';
import 'notification_service.dart';

/// Notificação com o app fechado, sem Firebase: o Android (WorkManager)
/// acorda o app a cada ~15 minutos, com internet, para consultar a API e
/// avisar se algum pedido mudou de status ou se chegou pedido novo (admin).
///
/// O intervalo mínimo do Android é 15 minutos e pode atrasar em modo de
/// economia de bateria. Push instantâneo exigiria Firebase Cloud Messaging.
abstract final class BackgroundSync {
  static const taskName = 'leadsystem-order-status';

  /// Status já avisados (compartilhado com a sincronização em primeiro plano
  /// para não notificar duas vezes a mesma mudança).
  static const seenKey = 'leadsystem_seen_order_status';
  static const stateKey = 'leadsystem_state_v2';

  static Future<void> register() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().initialize(backgroundDispatcher);
      await Workmanager().registerPeriodicTask(
        taskName,
        taskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (error) {
      debugPrint('Verificação em segundo plano indisponível: $error');
    }
  }

  /// Compara os pedidos do servidor com os status já vistos e devolve os
  /// avisos (título, texto). Na primeira execução só registra, sem avisar.
  static List<(String, String)> detectChanges({
    required Map<String, String> seen,
    required List<Map<String, Object?>> orders,
    required bool admin,
  }) {
    final notices = <(String, String)>[];
    if (seen.isEmpty) return notices;
    for (final order in orders) {
      final id = order['id']?.toString();
      final status = order['status']?.toString();
      if (id == null || status == null) continue;
      final previous = seen[id];
      if (previous == null) {
        if (admin) {
          notices.add((
            'Novo pedido',
            '$id de ${order['customerName'] ?? order['customerEmail'] ?? 'cliente'}',
          ));
        }
      } else if (previous != status && !admin) {
        final label = OrderStatus.values
            .firstWhere(
              (value) => value.name == status,
              orElse: () => OrderStatus.received,
            )
            .label;
        notices.add((label, 'Seu pedido $id está: $label.'));
      }
    }
    return notices;
  }

  static Map<String, String> readSeen(SharedPreferences preferences) {
    final raw = preferences.getString(seenKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', '$value'));
      }
    } on FormatException {
      return {};
    }
    return {};
  }

  static Future<void> writeSeen(
    SharedPreferences preferences,
    Iterable<Map<String, Object?>> orders,
  ) => preferences.setString(
    seenKey,
    jsonEncode({
      for (final order in orders)
        if (order['id'] != null) '${order['id']}': '${order['status']}',
    }),
  );
}

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final raw = preferences.getString(BackgroundSync.stateKey);
      if (raw == null) return true;
      final state = jsonDecode(raw);
      if (state is! Map) return true;
      final url = state['apiUrl']?.toString();
      final token = state['apiToken']?.toString();
      if (url == null || url.isEmpty || token == null) return true;

      final api = ApiClient(url)..token = token;
      final me = await api.get('/api/auth/me');
      final user = me['user'];
      final admin = user is Map && user['role'] == 'admin';
      final data = await api.get(
        '/api/orders',
        query: admin ? {'scope': 'all'} : null,
      );
      final orders = [
        for (final item in (data['data'] as List? ?? const []))
          if (item is Map) item.map((key, value) => MapEntry('$key', value)),
      ];
      final notices = BackgroundSync.detectChanges(
        seen: BackgroundSync.readSeen(preferences),
        orders: orders,
        admin: admin,
      );
      if (notices.isNotEmpty) {
        await NotificationService.instance.init(requestPermission: false);
        for (final (title, body) in notices) {
          await NotificationService.instance.show(title, body);
        }
      }
      await BackgroundSync.writeSeen(preferences, orders);
      api.close();
      return true;
    } on ApiException catch (error) {
      // Falha de rede: o Android tenta de novo no próximo ciclo.
      return !error.isNetwork;
    } catch (_) {
      return true;
    }
  });
}
