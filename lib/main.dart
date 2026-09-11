import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.initialize();
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

  @override
  void dispose() {
    if (_ownsState) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _state,
      child: MaterialApp(
        title: 'SantiGrill LeadSystem',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppShell(),
      ),
    );
  }
}
