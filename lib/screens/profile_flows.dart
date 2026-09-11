import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../models/product.dart';
import '../widgets/shared.dart';
import 'detail_flows.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final products = state.favoriteProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus favoritos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: products.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Nenhum favorito ainda',
              description: 'Toque no coração de um produto para encontrá-lo rapidamente aqui.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = products[index];
                return _FavoriteProductCard(
                  product: product,
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  ),
                  onAdd: () {
                    state.addToCart(product);
                    showAppSnackBar(
                      context,
                      '${product.shortName} adicionado ao carrinho.',
                    );
                  },
                  onRemove: () {
                    state.toggleFavorite(product.id);
                    showAppSnackBar(
                      context,
                      '${product.shortName} removido dos favoritos.',
                      action: SnackBarAction(
                        label: 'DESFAZER',
                        onPressed: () => state.toggleFavorite(product.id),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _FavoriteProductCard extends StatelessWidget {
  const _FavoriteProductCard({
    required this.product,
    required this.onOpen,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 94,
                height: 104,
                child: ProductImage(quadrant: product.imageQuadrant),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.shortName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remover dos favoritos',
                          visualDensity: VisualDensity.compact,
                          onPressed: onRemove,
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.rating
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Em estoque',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            money(product.price),
                            style: const TextStyle(
                              color: AppColors.darkRed,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final addresses = state.addresses;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Endereços de entrega',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Adicionar endereço',
            onPressed: () => _openEditor(context, state),
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: addresses.isEmpty
          ? EmptyState(
              icon: Icons.location_on_outlined,
              title: 'Nenhum endereço cadastrado',
              description:
                  'Adicione um endereço para agilizar suas próximas compras.',
              actionLabel: 'Adicionar endereço',
              onAction: () => _openEditor(context, state),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'O endereço padrão será selecionado automaticamente no checkout.',
                          style: TextStyle(fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...addresses.map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AddressCard(
                      address: address,
                      onSetDefault: address.isDefault
                          ? null
                          : () {
                              state.setDefaultAddress(address.id);
                              showAppSnackBar(
                                context,
                                '${address.label} definido como endereço padrão.',
                              );
                            },
                      onEdit: () =>
                          _openEditor(context, state, address: address),
                      onDelete: () => _confirmDelete(context, state, address),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () => _openEditor(context, state),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar outro endereço'),
                ),
              ],
            ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppState state, {
    Address? address,
  }) async {
    final draft = await showModalBottomSheet<_AddressDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.canvas,
      builder: (_) => _AddressEditorSheet(address: address),
    );
    if (draft == null || !context.mounted) return;

    if (address == null) {
      state.addAddress(
        label: draft.label,
        street: draft.street,
        number: draft.number,
        complement: draft.complement,
        neighborhood: draft.neighborhood,
        city: draft.city,
        state: draft.state,
        postalCode: draft.postalCode,
        makeDefault: draft.makeDefault,
      );
      showAppSnackBar(context, 'Endereço adicionado com sucesso.');
    } else {
      state.updateAddress(
        Address(
          id: address.id,
          label: draft.label,
          street: draft.street,
          number: draft.number,
          complement: draft.complement,
          neighborhood: draft.neighborhood,
          city: draft.city,
          state: draft.state,
          postalCode: draft.postalCode,
          isDefault: draft.makeDefault || address.isDefault,
        ),
      );
      if (draft.makeDefault) state.setDefaultAddress(address.id);
      showAppSnackBar(context, 'Endereço atualizado com sucesso.');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    Address address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.red,
          size: 38,
        ),
        title: const Text('Excluir endereço?'),
        content: Text(
          'O endereço “${address.label}” será removido da sua conta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    state.removeAddress(address.id);
    showAppSnackBar(context, 'Endereço excluído.');
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: address.isDefault ? AppColors.red : AppColors.border,
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: address.isDefault
                  ? const Color(0xFFF8DFE1)
                  : const Color(0xFFF0ECE7),
              foregroundColor: address.isDefault
                  ? AppColors.red
                  : AppColors.muted,
              child: Icon(_addressIcon(address.label)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        const StatusPill(
                          label: 'Padrão',
                          color: AppColors.red,
                          background: Color(0xFFF8DFE1),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _addressLines(address),
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  if (onSetDefault != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onSetDefault,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Definir como padrão'),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<_AddressAction>(
              tooltip: 'Opções do endereço',
              onSelected: (action) {
                switch (action) {
                  case _AddressAction.edit:
                    onEdit();
                    break;
                  case _AddressAction.delete:
                    onDelete();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _AddressAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  value: _AddressAction.delete,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline, color: AppColors.red),
                    title: Text(
                      'Excluir',
                      style: TextStyle(color: AppColors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _AddressAction { edit, delete }

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({this.address});

  final Address? address;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _streetController;
  late final TextEditingController _numberController;
  late final TextEditingController _complementController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  late bool _makeDefault;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _labelController = TextEditingController(text: address?.label ?? 'Casa');
    _streetController = TextEditingController(text: address?.street ?? '');
    _numberController = TextEditingController(text: address?.number ?? '');
    _complementController = TextEditingController(
      text: address?.complement ?? '',
    );
    _neighborhoodController = TextEditingController(
      text: address?.neighborhood ?? '',
    );
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _postalCodeController = TextEditingController(
      text: address?.postalCode ?? '',
    );
    _makeDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.address == null
                    ? 'Adicionar endereço'
                    : 'Editar endereço',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Preencha os dados exatamente como aparecem no endereço de entrega.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _labelController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Identificação',
                  hintText: 'Casa, trabalho...',
                  prefixIcon: Icon(Icons.bookmark_border_rounded),
                ),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CEP',
                  hintText: '00000-000',
                  prefixIcon: Icon(Icons.pin_drop_outlined),
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  return digits.length == 8 ? null : 'Informe um CEP válido.';
                },
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _streetController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Rua ou avenida',
                      ),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _numberController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Número'),
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _complementController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Complemento (opcional)',
                  hintText: 'Apartamento, bloco, referência...',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _neighborhoodController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Bairro'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        counterText: '',
                      ),
                      validator: (value) => (value ?? '').trim().length == 2
                          ? null
                          : 'UF inválida.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                value: _makeDefault,
                onChanged: (value) => setState(() => _makeDefault = value),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Usar como endereço padrão',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Será selecionado no próximo checkout.'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _submit,
                child: Text(
                  widget.address == null
                      ? 'Adicionar endereço'
                      : 'Salvar alterações',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo é obrigatório.'
      : null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _AddressDraft(
        label: _labelController.text.trim(),
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        complement: _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
        postalCode: _postalCodeController.text.trim(),
        makeDefault: _makeDefault,
      ),
    );
  }
}

class _AddressDraft {
  const _AddressDraft({
    required this.label,
    required this.street,
    required this.number,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.makeDefault,
  });

  final String label;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;
  final String postalCode;
  final bool makeDefault;
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final events = state.notificationEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificações',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (events.isNotEmpty)
            IconButton(
              tooltip: 'Limpar histórico',
              onPressed: () => _confirmClear(context, state),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Preferências',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Escolha quais atualizações deseja receber.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _NotificationToggle(
                  icon: Icons.local_shipping_outlined,
                  title: 'Atualizações de pedidos',
                  subtitle: 'Pagamento, envio e entrega',
                  value: state.orderNotifications,
                  onChanged: state.setOrderNotifications,
                ),
                const Divider(height: 1, indent: 64),
                _NotificationToggle(
                  icon: Icons.local_offer_outlined,
                  title: 'Ofertas e novidades',
                  subtitle: 'Cupons, campanhas e novos produtos',
                  value: state.offersNotifications,
                  onChanged: state.setOffersNotifications,
                ),
                const Divider(height: 1, indent: 64),
                _NotificationToggle(
                  icon: Icons.support_agent_outlined,
                  title: 'Atendimento',
                  subtitle: 'Respostas do suporte e orçamentos',
                  value: state.supportNotifications,
                  onChanged: state.setSupportNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(
                Icons.cloud_done_outlined,
                size: 16,
                color: AppColors.success,
              ),
              SizedBox(width: 6),
              Text(
                'Alterações salvas automaticamente',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Histórico',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
              if (events.any((event) => !event.read))
                StatusPill(
                  label: '${events.where((event) => !event.read).length} novas',
                  color: AppColors.red,
                  background: const Color(0xFFF8DFE1),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Tudo tranquilo por aqui',
                  description: 'As atualizações de pedidos e atendimento aparecerão nesta área.',
                ),
              ),
            )
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _NotificationEventCard(
                  event: event,
                  onTap: event.read
                      ? null
                      : () => state.markNotificationRead(event.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text(
          'As notificações serão removidas desta lista. Suas preferências não serão alteradas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    state.clearNotificationHistory();
    showAppSnackBar(context, 'Histórico de notificações limpo.');
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: CircleAvatar(
        backgroundColor: const Color(0xFFF8DFE1),
        foregroundColor: AppColors.red,
        child: Icon(icon, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    );
  }
}

class _NotificationEventCard extends StatelessWidget {
  const _NotificationEventCard({required this.event, this.onTap});

  final AppNotification event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _notificationVisual(event.category);
    return Card(
      color: event.read ? Colors.white : const Color(0xFFFFFAF7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: visual.background,
                foregroundColor: visual.color,
                child: Icon(visual.icon, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontWeight: event.read
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!event.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatEventDate(event.createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final state = AppScope.of(context);
    _nameController.text = state.userName;
    _emailController.text = state.userEmail;
    _phoneController.text = state.userPhone;
    _loaded = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.loggedIn || state.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Conta e segurança',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: EmptyState(
          icon: Icons.lock_person_outlined,
          title: 'Entre para gerenciar sua conta',
          description: 'Seus dados pessoais e opções de segurança ficam disponíveis após o login.',
          actionLabel: 'Voltar ao perfil',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conta e segurança',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _profileFormKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFF8DFE1),
                      foregroundColor: AppColors.red,
                      child: Icon(Icons.person_rounded, size: 30),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            state.userEmail,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: state.isAdmin ? 'Admin' : 'Cliente',
                      color: state.isAdmin ? AppColors.red : AppColors.success,
                      background: state.isAdmin
                          ? const Color(0xFFF8DFE1)
                          : AppColors.successSoft,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeading(title: 'Dados pessoais'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) =>
                  value == null || value.trim().split(RegExp(r'\s+')).length < 2
                  ? 'Informe nome e sobrenome.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              readOnly: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail da conta',
                prefixIcon: Icon(Icons.email_outlined),
                suffixIcon: Icon(Icons.lock_outline, size: 18),
                helperText: 'O e-mail identifica sua conta e não pode ser alterado aqui.',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                return digits.length >= 10 && digits.length <= 11
                    ? null
                    : 'Informe DDD e telefone válidos.';
              },
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _saveProfile(state),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar dados pessoais'),
            ),
            const SizedBox(height: 26),
            const SectionHeading(title: 'Segurança'),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF8DFE1),
                  foregroundColor: AppColors.red,
                  child: Icon(Icons.password_rounded),
                ),
                title: const Text(
                  'Alterar senha',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  'Use uma senha forte e diferente das anteriores.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePassword(context),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.successSoft,
                  foregroundColor: AppColors.success,
                  child: Icon(Icons.verified_user_outlined),
                ),
                title: const Text(
                  'Política de Privacidade',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('Veja como seus dados são tratados.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_rounded, color: AppColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Seus dados são armazenados com proteção e usados apenas para operar sua conta e seus pedidos.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile(AppState state) {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;
    state.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    showAppSnackBar(context, 'Dados pessoais atualizados.');
  }

  Future<void> _changePassword(BuildContext context) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (changed == true && context.mounted) {
      showAppSnackBar(context, 'Senha alterada com segurança.');
    }
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar senha'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Senha atual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscureCurrent
                          ? 'Mostrar senha'
                          : 'Ocultar senha',
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Informe sua senha atual.'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nova senha',
                    helperText: 'Mínimo de 8 caracteres, maiúscula e número.',
                    prefixIcon: const Icon(Icons.password_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscureNew ? 'Mostrar senha' : 'Ocultar senha',
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmationController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nova senha',
                    prefixIcon: Icon(Icons.check_circle_outline),
                  ),
                  validator: (value) => value == _newController.text
                      ? null
                      : 'As senhas não coincidem.',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE7E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.darkRed),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const Text('Alterar senha'),
        ),
      ],
    );
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'\d'))) {
      return 'Use 8 caracteres, uma letra maiúscula e um número.';
    }
    if (password == _currentController.text) {
      return 'A nova senha deve ser diferente da atual.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final state = AppScope.of(context);
    final changed = await state.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    if (changed) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = state.lastAuthMessage ?? 'Não foi possível alterar a senha.';
    });
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Política de Privacidade',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: const [
          _PolicyIntro(),
          SizedBox(height: 22),
          _PolicySection(
            number: '1',
            title: 'Dados coletados',
            text: 'O LeadSystem utiliza os dados informados no cadastro, como nome, e-mail e telefone, além dos endereços necessários para entrega. Também são registrados itens do carrinho, pedidos, orçamentos, preferências e mensagens enviadas ao atendimento.',
          ),
          _PolicySection(
            number: '2',
            title: 'Como usamos as informações',
            text: 'Os dados são usados para autenticar sua conta, processar compras e orçamentos, organizar entregas, prestar atendimento e enviar as notificações escolhidas por você. Não utilizamos informações pessoais para finalidades incompatíveis com esses serviços.',
          ),
          _PolicySection(
            number: '3',
            title: 'Compartilhamento',
            text: 'Informações são compartilhadas somente quando necessárias à operação do serviço, por exemplo com meios de pagamento e parceiros de entrega. O projeto não comercializa dados pessoais.',
          ),
          _PolicySection(
            number: '4',
            title: 'Armazenamento e segurança',
            text: 'Aplicamos medidas de acesso, validação e proteção compatíveis com a finalidade acadêmica do sistema. Senhas não devem ser exibidas em texto simples e o acesso administrativo é separado do acesso do cliente.',
          ),
          _PolicySection(
            number: '5',
            title: 'Seus direitos',
            text: 'Você pode consultar e corrigir seus dados nesta área, ajustar notificações e solicitar esclarecimentos sobre o tratamento das informações. Pedidos de exclusão serão avaliados conforme as obrigações de conservação aplicáveis.',
          ),
          _PolicySection(
            number: '6',
            title: 'Contato',
            text: 'Dúvidas sobre privacidade podem ser encaminhadas pela área Ajuda e atendimento do aplicativo. A equipe registrará a solicitação e apresentará um retorno ao usuário.',
          ),
          SizedBox(height: 6),
          Center(
            child: Text(
              'Versão 1.0 · atualizada em setembro de 2026',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyIntro extends StatelessWidget {
  const _PolicyIntro();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            CircleAvatar(
              backgroundColor: AppColors.successSoft,
              foregroundColor: AppColors.success,
              child: Icon(Icons.privacy_tip_outlined),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'A SantiGrill valoriza a transparência. Este documento resume quais dados o LeadSystem utiliza e quais escolhas estão sob seu controle.',
                style: TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFFF8DFE1),
            foregroundColor: AppColors.red,
            child: Text(
              number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(color: AppColors.muted, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _addressIcon(String label) {
  final normalized = label.toLowerCase();
  if (normalized.contains('trabalho') || normalized.contains('empresa')) {
    return Icons.business_outlined;
  }
  if (normalized.contains('evento')) return Icons.celebration_outlined;
  return Icons.home_outlined;
}

String _addressLines(Address address) {
  final complement = address.complement.trim().isEmpty
      ? ''
      : ' · ${address.complement.trim()}';
  return '${address.street}, ${address.number}$complement\n'
      '${address.neighborhood} · ${address.city}/${address.state}\n'
      'CEP ${_formatPostalCode(address.postalCode)}';
}

String _formatPostalCode(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 8) return value;
  return '${digits.substring(0, 5)}-${digits.substring(5)}';
}

_NotificationVisual _notificationVisual(String category) {
  switch (category) {
    case 'order':
      return const _NotificationVisual(
        icon: Icons.local_shipping_outlined,
        color: AppColors.success,
        background: AppColors.successSoft,
      );
    case 'offer':
      return const _NotificationVisual(
        icon: Icons.local_offer_outlined,
        color: AppColors.red,
        background: Color(0xFFF8DFE1),
      );
    case 'support':
      return const _NotificationVisual(
        icon: Icons.support_agent_outlined,
        color: Color(0xFF2F6495),
        background: Color(0xFFE7F1FA),
      );
    default:
      return const _NotificationVisual(
        icon: Icons.info_outline_rounded,
        color: AppColors.warning,
        background: AppColors.warningSoft,
      );
  }
}

String _formatEventDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inMinutes < 1) return 'Agora';
  if (difference.inMinutes < 60) return 'Há ${difference.inMinutes} min';
  if (_sameDate(now, date)) {
    return 'Hoje, ${_two(date.hour)}:${_two(date.minute)}';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (_sameDate(yesterday, date)) {
    return 'Ontem, ${_two(date.hour)}:${_two(date.minute)}';
  }
  return '${_two(date.day)}/${_two(date.month)}/${date.year} · '
      '${_two(date.hour)}:${_two(date.minute)}';
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _two(int value) => value.toString().padLeft(2, '0');

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}
