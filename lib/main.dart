import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LeadSystemApp());
}

class LeadSystemApp extends StatefulWidget {
  const LeadSystemApp({super.key});

  @override
  State<LeadSystemApp> createState() => _LeadSystemAppState();
}

class _LeadSystemAppState extends State<LeadSystemApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
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
