import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../widgets/shared.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'leandro@email.com');
  final _passwordController = TextEditingController(text: 'Santi@2026');
  bool obscure = true;
  bool remember = true;
  bool loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.red,
                    size: 58,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SantiGrill',
                    style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
                  ),
                  const Text(
                    'Entre para concluir sua compra',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 26),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Acesse pedidos, orçamentos e atendimento.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) =>
                                  value != null && value.contains('@')
                                  ? null
                                  : 'Digite um e-mail válido.',
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: obscure,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: obscure
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                                  onPressed: () =>
                                      setState(() => obscure = !obscure),
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value != null && value.length >= 8
                                  ? null
                                  : 'A senha deve ter ao menos 8 caracteres.',
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: remember,
                                  onChanged: (value) =>
                                      setState(() => remember = value ?? false),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Lembrar de mim',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => showAppSnackBar(
                                    context,
                                    'Enviamos um link de recuperação para o e-mail informado.',
                                  ),
                                  child: const Text('Esqueci minha senha'),
                                ),
                              ],
                            ),
                            FilledButton(
                              onPressed: loading ? null : _login,
                              child: loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _demoLogin,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Entrar no modo demonstração'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('Ainda não tem conta? Criar conta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    AppScope.of(context).signIn();
    Navigator.of(context).pop();
  }

  void _demoLogin() {
    AppScope.of(context).signIn(name: 'Leandro Gonçalves');
    Navigator.of(context).pop();
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(
    text: 'Leandro Gonçalves Ribeiro Junior',
  );
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '(11) 99999-4321');
  final _passwordController = TextEditingController();
  bool accepted = true;
  bool submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Criar conta',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: submitted
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Text(
              'Seus dados',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Etapa 2 de 2 · revise os campos destacados',
              style: TextStyle(color: AppColors.muted),
            ),
            if (submitted) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E8),
                  border: Border.all(color: AppColors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.red),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Revise os campos em vermelho. Os demais dados foram preservados.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (value) =>
                  value == null || value.trim().split(' ').length < 2
                  ? 'Informe nome e sobrenome.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'nome@exemplo.com',
              ),
              validator: (value) =>
                  value != null && value.contains('@') && value.contains('.')
                  ? null
                  : 'Digite um e-mail completo, como nome@exemplo.com.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
              validator: (value) =>
                  value != null &&
                      value.replaceAll(RegExp(r'\D'), '').length >= 10
                  ? null
                  : 'Informe DDD e número.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              validator: _validatePassword,
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: accepted,
              onChanged: (value) => setState(() => accepted = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Li e aceito a Política de Privacidade',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: accepted ? _register : null,
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'\d'))) {
      return 'Use 8 caracteres, uma letra maiúscula e um número.';
    }
    return null;
  }

  void _register() {
    setState(() => submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    AppScope.of(context).signIn(name: _nameController.text);
    showAppSnackBar(context, 'Conta criada com sucesso.');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(compact: true),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(
              child: StatusPill(
                label: 'Admin',
                color: AppColors.red,
                background: Color(0xFFFFE7E8),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text(
            'Visão geral',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const Text(
            'Quarta-feira, 10 de setembro',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  value: '8',
                  label: 'pedidos\npendentes',
                  color: Color(0xFFFFE7E8),
                  valueColor: AppColors.darkRed,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  value: '5',
                  label: 'orçamentos\nnovos',
                  color: Color(0xFFE7F1FA),
                  valueColor: Color(0xFF2F6495),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  value: '3',
                  label: 'itens com\nestoque baixo',
                  color: AppColors.warningSoft,
                  valueColor: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeading(title: 'Ações rápidas'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: .82,
            children: [
              _AdminAction(
                icon: Icons.add_box_outlined,
                label: 'Novo\nproduto',
                onTap: () => _action(context, 'Cadastro de produto aberto.'),
              ),
              _AdminAction(
                icon: Icons.percent,
                label: 'Criar\ncupom',
                onTap: () => _action(context, 'Editor de cupom aberto.'),
              ),
              _AdminAction(
                icon: Icons.campaign_outlined,
                label: 'Nova\ncampanha',
                onTap: () => _action(context, 'Nova campanha preparada.'),
              ),
              _AdminAction(
                icon: Icons.analytics_outlined,
                label: 'Ver\nrelatórios',
                onTap: () => _action(context, 'Relatórios atualizados.'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: SectionHeading(title: 'Pedidos recentes')),
              const StatusPill(
                label: 'Pendentes',
                color: AppColors.red,
                background: Color(0xFFFFE7E8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AdminOrder(
            number: '#SG-0147',
            customer: 'Carlos Silva',
            total: 'R\$ 951,72',
            status: 'Pendente',
            onTap: () => _action(context, 'Pedido #SG-0147 selecionado.'),
          ),
          _AdminOrder(
            number: '#SG-0146',
            customer: 'Ana Costa',
            total: 'R\$ 249,90',
            status: 'Aprovado',
            onTap: () => _action(context, 'Pedido #SG-0146 selecionado.'),
          ),
          _AdminOrder(
            number: '#SG-0145',
            customer: 'João Lima',
            total: 'R\$ 1.089,80',
            status: 'Enviado',
            onTap: () => _action(context, 'Pedido #SG-0145 selecionado.'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _action(context, '2 pedidos atualizados em lote.'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            icon: const Icon(Icons.done_all),
            label: const Text('Atualizar pedidos em lote'),
          ),
          const SizedBox(height: 24),
          const SectionHeading(title: 'Gestão do sistema'),
          const SizedBox(height: 8),
          const _ManagementTile(
            icon: Icons.inventory_2_outlined,
            title: 'Produtos',
            subtitle: 'Cadastrar, editar e controlar estoque',
          ),
          const _ManagementTile(
            icon: Icons.category_outlined,
            title: 'Categorias',
            subtitle: 'Organizar o catálogo',
          ),
          const _ManagementTile(
            icon: Icons.people_outline,
            title: 'Usuários',
            subtitle: 'Consultar, editar e bloquear acessos',
          ),
          const _ManagementTile(
            icon: Icons.request_quote_outlined,
            title: 'Orçamentos',
            subtitle: 'Analisar e responder solicitações',
          ),
        ],
      ),
    );
  }

  static void _action(BuildContext context, String message) =>
      showAppSnackBar(context, message);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.color,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color color;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 11, height: 1.25)),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  const _AdminAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.red, size: 26),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminOrder extends StatelessWidget {
  const _AdminOrder({
    required this.number,
    required this.customer,
    required this.total,
    required this.status,
    required this.onTap,
  });

  final String number;
  final String customer;
  final String total;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'Pendente';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        title: Row(
          children: [
            Expanded(
              child: Text(
                number,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(total, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        subtitle: Text(customer),
        trailing: StatusPill(
          label: status,
          color: pending ? AppColors.warning : AppColors.success,
          background: pending ? AppColors.warningSoft : AppColors.successSoft,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ManagementTile extends StatelessWidget {
  const _ManagementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF8DFE1),
          foregroundColor: AppColors.red,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showAppSnackBar(
          context,
          '$title: módulo disponível para demonstração.',
        ),
      ),
    );
  }
}
