import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../widgets/shared.dart';

/// Conexão com a API LeadSystem (server/) para sincronizar pedidos,
/// orçamentos e catálogo entre aparelhos.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final TextEditingController _url;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: AppState.defaultApiUrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = AppScope.of(context).apiUrl;
    if (current != null && _url.text.isEmpty) _url.text = current;
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final state = AppScope.of(context);
    setState(() => _testing = true);
    final ok = await state.configureServer(_url.text);
    if (!mounted) return;
    setState(() => _testing = false);
    showAppSnackBar(
      context,
      ok
          ? 'Servidor conectado. Entre na conta para sincronizar seus pedidos.'
          : state.syncMessage ?? 'Não foi possível conectar.',
    );
  }

  Future<void> _disconnect() async {
    await AppScope.of(context).configureServer(null);
    if (!mounted) return;
    showAppSnackBar(context, 'Modo offline: os dados ficam só no aparelho.');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final online = state.onlineMode;
    final lastSync = state.lastSyncAt;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Servidor e sincronização',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: online ? AppColors.success : AppColors.muted,
              ),
              title: Text(
                online ? 'Conectado' : 'Modo offline',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                online
                    ? '${state.apiUrl}\n${lastSync == null ? 'Ainda não sincronizado' : 'Última sincronização: ${_time(lastSync)}'}'
                    : 'Pedidos e cadastros ficam só neste aparelho.',
              ),
              isThreeLine: online,
            ),
          ),
          if (state.syncMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              state.syncMessage!,
              style: TextStyle(color: AppColors.warning),
            ),
          ],
          if (state.pendingSyncCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              '${state.pendingSyncCount} alteração(ões) aguardando envio.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Endereço da API',
              hintText: 'http://10.0.2.2:3000',
              helperText:
                  'Emulador Android: http://10.0.2.2:3000 · '
                  'Celular: IP do computador na mesma rede Wi-Fi',
              helperMaxLines: 2,
            ),
            onSubmitted: (_) => _connect(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _testing ? null : _connect,
            icon: _testing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.link),
            label: const Text('Testar e conectar'),
          ),
          if (online) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: state.syncing ? null : state.syncNow,
              icon: const Icon(Icons.sync),
              label: Text(
                state.syncing ? 'Sincronizando...' : 'Sincronizar agora',
              ),
            ),
            TextButton(
              onPressed: _disconnect,
              child: const Text('Usar somente offline'),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Como funciona',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            '• Tudo é salvo primeiro no aparelho; sem internet, o app continua '
            'funcionando e envia as alterações quando a conexão voltar.\n'
            '• Conectado, o pedido do cliente aparece no painel do admin e as '
            'mudanças de status chegam como notificação.\n'
            '• Preços e estoque são confirmados pelo servidor ao finalizar.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  static String _time(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)} às '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

/// Seletor de aparência (sistema, claro, escuro).
Future<void> showAppearanceSheet(BuildContext context) {
  final state = AppScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: RadioGroup<ThemeMode>(
        groupValue: state.themeMode,
        onChanged: (mode) {
          if (mode != null) state.setThemeMode(mode);
          Navigator.of(context).pop();
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              value: ThemeMode.system,
              title: Text('Igual ao sistema'),
              secondary: Icon(Icons.brightness_auto_outlined),
            ),
            RadioListTile(
              value: ThemeMode.light,
              title: Text('Claro'),
              secondary: Icon(Icons.light_mode_outlined),
            ),
            RadioListTile(
              value: ThemeMode.dark,
              title: Text('Escuro'),
              secondary: Icon(Icons.dark_mode_outlined),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Igual ao sistema',
  ThemeMode.light => 'Claro',
  ThemeMode.dark => 'Escuro',
};
