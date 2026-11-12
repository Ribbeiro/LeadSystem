import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificações do sistema (barra de notificações do Android/iOS).
///
/// Os avisos são gerados quando o app sincroniza com a API e percebe uma
/// mudança (status do pedido, resposta de orçamento, novo pedido para o
/// admin). Com o app fechado, a entrega exige push remoto (Firebase Cloud
/// Messaging), que depende de um projeto Firebase da SantiGrill.
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _nextId = 0;

  static const _channel = AndroidNotificationDetails(
    'pedidos',
    'Pedidos e atendimento',
    channelDescription: 'Mudanças de status, orçamentos e avisos da loja.',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFFD10D0D),
  );

  Future<void> init({bool requestPermission = true}) async {
    if (_ready || kIsWeb) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      if (requestPermission) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
      _ready = true;
    } catch (error) {
      debugPrint('Notificações indisponíveis: $error');
    }
  }

  Future<void> show(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _nextId++,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (error) {
      debugPrint('Falha ao exibir notificação: $error');
    }
  }
}
