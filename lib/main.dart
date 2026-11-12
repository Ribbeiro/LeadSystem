import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'core/background_sync.dart';
import 'core/notification_service.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.initialize();
  await NotificationService.instance.init();
  state.onSystemNotification = NotificationService.instance.show;
  // Avisos com o app fechado (Android): consulta a API a cada ~15 min.
  await BackgroundSync.register();
  runApp(LeadSystemApp(state: state));
}

class LeadSystemApp extends StatefulWidget {
  const LeadSystemApp({super.key, this.state});

  final AppState? state;

  @override
  State<LeadSystemApp> createState() => _LeadSystemAppState();
}

class _LeadSystemAppState extends State<LeadSystemApp> {
  late final AppState _state = widget.state ?? AppState();
  late final bool _ownsState = widget.state == null;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Sincroniza ao voltar para o app e pausa em segundo plano.
    _lifecycle = AppLifecycleListener(
      onResume: () => _state.setForeground(true),
      onPause: () => _state.setForeground(false),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (_ownsState) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) => MaterialApp(
          title: 'SantiGrill LeadSystem',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _state.themeMode,
          builder: (context, child) => _PaletteScope(child: child!),
          home: const AppShell(),
        ),
      ),
    );
  }
}

/// Aplica a paleta clara/escura de acordo com o tema efetivo e reconstrói
/// as telas quando ele muda (ex.: o sistema entrou no modo escuro).
class _PaletteScope extends StatelessWidget {
  const _PaletteScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (AppColors.usePalette(dark ? AppPalette.dark : AppPalette.light)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) rebuildAllChildren(context);
      });
    }
    return child;
  }
}
