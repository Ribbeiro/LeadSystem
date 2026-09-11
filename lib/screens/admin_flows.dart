import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../models/product.dart';
import '../widgets/shared.dart';

String _shortDate(DateTime value) {
  const months = <String>[
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
}

String _dateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${_shortDate(value)} · $hour:$minute';
}

double? _decimal(String value) {
  final raw = value.trim().replaceAll(' ', '');
  final normalized = raw.contains(',')
      ? raw.replaceAll('.', '').replaceAll(',', '.')
      : raw;
  return double.tryParse(normalized);
}

Color _orderColor(OrderStatus status) {
  return switch (status) {
    OrderStatus.received || OrderStatus.preparing => AppColors.warning,
    OrderStatus.paymentApproved => const Color(0xFF2F6495),
    OrderStatus.shipped => const Color(0xFF6A55A5),
    OrderStatus.delivered => AppColors.success,
    OrderStatus.cancelled => AppColors.red,
  };
}

Color _quoteColor(QuoteStatus status) {
  return switch (status) {
    QuoteStatus.pending => AppColors.warning,
    QuoteStatus.reviewing => const Color(0xFF2F6495),
    QuoteStatus.approved || QuoteStatus.answered => AppColors.success,
    QuoteStatus.rejected => AppColors.red,
  };
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String description,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.delete_outline, color: AppColors.red),
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      ) ??
      false;
}

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _onlyLowStock = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final query = _query.trim().toLowerCase();
    final products = state.products.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.id.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      return matchesQuery && (!_onlyLowStock || product.stock <= 5);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Produtos e estoque',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome, SKU ou categoria',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${products.length} de ${state.products.length} produtos',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                    FilterChip(
                      selected: _onlyLowStock,
                      avatar: const Icon(Icons.warning_amber, size: 17),
                      label: const Text('Estoque baixo'),
                      onSelected: (value) =>
                          setState(() => _onlyLowStock = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nenhum produto encontrado',
                    description: _onlyLowStock
                        ? 'Não há produtos com cinco unidades ou menos.'
                        : 'Revise a busca ou cadastre um novo item.',
                    actionLabel: 'Limpar filtros',
                    onAction: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _onlyLowStock = false;
                      });
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductAdminCard(
                        product: product,
                        onEdit: () => _openForm(context, product: product),
                        onStock: () => _editStock(context, product),
                        onDelete: () => _delete(context, product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Product? product}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  Future<void> _editStock(BuildContext context, Product product) async {
    final controller = TextEditingController(text: '${product.stock}');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Estoque · ${product.shortName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade disponível',
            prefixIcon: Icon(Icons.inventory_2_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final stock = int.tryParse(controller.text);
              if (stock != null && stock >= 0) {
                Navigator.of(dialogContext).pop(stock);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !context.mounted) return;
    AppScope.of(context).setProductStock(product.id, value);
    showAppSnackBar(context, 'Estoque atualizado para $value unidades.');
  }

  Future<void> _delete(BuildContext context, Product product) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Excluir ${product.shortName}?',
      description: 'O produto será removido do catálogo. Pedidos já registrados continuarão preservados.',
    );
    if (!confirmed || !context.mounted) return;
    final removed = AppScope.of(context).removeProduct(product.id);
    showAppSnackBar(
      context,
      removed
          ? '${product.shortName} excluído do catálogo.'
          : 'Não foi possível excluir este produto.',
    );
  }
}

class _ProductAdminCard extends StatelessWidget {
  const _ProductAdminCard({
    required this.product,
    required this.onEdit,
    required this.onStock,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onStock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final lowStock = product.stock <= 5;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ProductImage(quadrant: product.imageQuadrant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.shortName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (!product.active)
                        const StatusPill(
                          label: 'Inativo',
                          color: AppColors.muted,
                          background: Color(0xFFEDEAE7),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.id} · ${product.category}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        money(product.price),
                        style: const TextStyle(
                          color: AppColors.darkRed,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      StatusPill(
                        label: '${product.stock} un.',
                        color: lowStock ? AppColors.warning : AppColors.success,
                        background: lowStock
                            ? AppColors.warningSoft
                            : AppColors.successSoft,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ações do produto',
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'stock':
                    onStock();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'stock',
                  child: ListTile(
                    leading: Icon(Icons.inventory_outlined),
                    title: Text('Ajustar estoque'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppColors.red),
                    title: Text('Excluir'),
                    contentPadding: EdgeInsets.zero,
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

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _id;
  late final TextEditingController _name;
  late final TextEditingController _shortName;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _rating;
  late final TextEditingController _reviews;
  late final TextEditingController _stock;
  late final TextEditingController _badge;
  late final TextEditingController _specifications;
  String? _category;
  int _imageQuadrant = 0;
  bool _active = true;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _id = TextEditingController(text: product?.id ?? '');
    _name = TextEditingController(text: product?.name ?? '');
    _shortName = TextEditingController(text: product?.shortName ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _price = TextEditingController(
      text: product?.price.toStringAsFixed(2).replaceAll('.', ',') ?? '',
    );
    _rating = TextEditingController(text: '${product?.rating ?? 5}');
    _reviews = TextEditingController(text: '${product?.reviewCount ?? 0}');
    _stock = TextEditingController(text: '${product?.stock ?? 0}');
    _badge = TextEditingController(text: product?.badge ?? '');
    _specifications = TextEditingController(
      text:
          product?.specifications.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join('\n') ??
          '',
    );
    _category = product?.category;
    _imageQuadrant = product?.imageQuadrant ?? 0;
    _active = product?.active ?? true;
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _shortName.dispose();
    _description.dispose();
    _price.dispose();
    _rating.dispose();
    _reviews.dispose();
    _stock.dispose();
    _badge.dispose();
    _specifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final categories = <String>{...state.categories};
    if (_category != null) categories.add(_category!);
    final orderedCategories = categories.toList()..sort();
    _category ??= orderedCategories.isEmpty ? null : orderedCategories.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'Editar produto' : 'Novo produto',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _AdminFormHeading(
              title: 'Identificação',
              subtitle: 'Dados exibidos no catálogo e usados na busca.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _id,
              enabled: !_editing,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'SKU'),
              validator: (value) {
                final id = value?.trim().toUpperCase() ?? '';
                if (id.length < 3) {
                  return 'Informe um SKU com ao menos 3 caracteres.';
                }
                if (!_editing && state.findProductById(id) != null) {
                  return 'Já existe um produto com este SKU.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (value) => (value?.trim().length ?? 0) < 4
                  ? 'Informe um nome mais descritivo.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _shortName,
              decoration: const InputDecoration(labelText: 'Nome curto'),
              validator: (value) => (value?.trim().length ?? 0) < 3
                  ? 'Informe o nome usado nos cards.'
                  : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: orderedCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value),
              validator: (value) =>
                  value == null ? 'Cadastre e selecione uma categoria.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (value) => (value?.trim().length ?? 0) < 12
                  ? 'Descreva o produto em pelo menos 12 caracteres.'
                  : null,
            ),
            const SizedBox(height: 22),
            const _AdminFormHeading(
              title: 'Venda e estoque',
              subtitle: 'Preço, disponibilidade e apresentação do item.',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Preço',
                      prefixText: 'R\$ ',
                    ),
                    validator: (value) => (_decimal(value ?? '') ?? 0) <= 0
                        ? 'Preço inválido.'
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Estoque'),
                    validator: (value) {
                      final stock = int.tryParse(value ?? '');
                      return stock == null || stock < 0
                          ? 'Valor inválido.'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rating,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Avaliação'),
                    validator: (value) {
                      final rating = _decimal(value ?? '');
                      return rating == null || rating < 0 || rating > 5
                          ? 'Use 0 a 5.'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _reviews,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nº avaliações',
                    ),
                    validator: (value) {
                      final reviews = int.tryParse(value ?? '');
                      return reviews == null || reviews < 0
                          ? 'Valor inválido.'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _badge,
              decoration: const InputDecoration(
                labelText: 'Selo promocional (opcional)',
                hintText: 'Ex.: Mais vendido',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _imageQuadrant,
              decoration: const InputDecoration(
                labelText: 'Imagem do catálogo',
              ),
              items: List.generate(
                4,
                (index) => DropdownMenuItem(
                  value: index,
                  child: Text('Imagem ${index + 1}'),
                ),
              ),
              onChanged: (value) => setState(() => _imageQuadrant = value ?? 0),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _specifications,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Especificações',
                hintText: 'Uma por linha no formato Campo: valor',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: const Text('Produto ativo'),
              subtitle: const Text('Itens inativos não aparecem para venda.'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_editing ? 'Salvar alterações' : 'Cadastrar produto'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final specifications = <String, String>{};
    for (final line in _specifications.text.split('\n')) {
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) specifications[key] = value;
    }
    final product = Product(
      id: _id.text.trim().toUpperCase(),
      name: _name.text.trim(),
      shortName: _shortName.text.trim(),
      category: _category!,
      description: _description.text.trim(),
      price: _decimal(_price.text)!,
      rating: _decimal(_rating.text)!,
      reviewCount: int.parse(_reviews.text),
      stock: int.parse(_stock.text),
      imageQuadrant: _imageQuadrant,
      specifications: specifications,
      badge: _badge.text.trim().isEmpty ? null : _badge.text.trim(),
      active: _active,
    );
    AppScope.of(context).upsertProduct(product);
    showAppSnackBar(
      context,
      _editing
          ? 'Produto atualizado com sucesso.'
          : 'Produto cadastrado com sucesso.',
    );
    Navigator.of(context).pop();
  }
}

class _AdminFormHeading extends StatelessWidget {
  const _AdminFormHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

class CouponManagementScreen extends StatelessWidget {
  const CouponManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final coupons = [...state.coupons]
      ..sort((a, b) {
        if (a.active != b.active) return a.active ? -1 : 1;
        return a.code.compareTo(b.code);
      });
    final activeCount = coupons.where((coupon) => coupon.active).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cupons',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const CouponFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo cupom'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: _AdminSummaryBanner(
              icon: Icons.percent,
              title: '$activeCount cupons ativos',
              subtitle:
                  '${coupons.length} cadastrados · alterações são refletidas no carrinho',
            ),
          ),
          Expanded(
            child: coupons.isEmpty
                ? EmptyState(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Nenhum cupom cadastrado',
                    description:
                        'Crie uma condição promocional para usar no carrinho.',
                    actionLabel: 'Criar primeiro cupom',
                    onAction: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const CouponFormScreen(),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: coupons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final expired =
                          coupon.expiresAt != null &&
                          coupon.expiresAt!.isBefore(DateTime.now());
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: coupon.active && !expired
                                    ? const Color(0xFFF8DFE1)
                                    : const Color(0xFFEDEAE7),
                                foregroundColor: coupon.active && !expired
                                    ? AppColors.red
                                    : AppColors.muted,
                                child: const Icon(Icons.percent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      coupon.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '${coupon.discountPercent.toStringAsFixed(0)}% · mínimo ${money(coupon.minimumSubtotal)}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (coupon.expiresAt != null)
                                      Text(
                                        expired
                                            ? 'Expirou em ${_shortDate(coupon.expiresAt!)}'
                                            : 'Válido até ${_shortDate(coupon.expiresAt!)}',
                                        style: TextStyle(
                                          color: expired
                                              ? AppColors.red
                                              : AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: coupon.active,
                                onChanged: (value) => state.upsertCoupon(
                                  Coupon(
                                    code: coupon.code,
                                    description: coupon.description,
                                    discountPercent: coupon.discountPercent,
                                    minimumSubtotal: coupon.minimumSubtotal,
                                    expiresAt: coupon.expiresAt,
                                    active: value,
                                    usageLimit: coupon.usageLimit,
                                    usedCount: coupon.usedCount,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Ações do cupom',
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    await Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CouponFormScreen(coupon: coupon),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    final confirmed = await _confirmDelete(
                                      context,
                                      title: 'Excluir ${coupon.code}?',
                                      description: 'O código deixará de ser aceito imediatamente no carrinho.',
                                    );
                                    if (confirmed && context.mounted) {
                                      final removed = state.removeCoupon(
                                        coupon.code,
                                      );
                                      showAppSnackBar(
                                        context,
                                        removed
                                            ? 'Cupom ${coupon.code} excluído.'
                                            : 'Não foi possível excluir o cupom.',
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Excluir'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CouponFormScreen extends StatefulWidget {
  const CouponFormScreen({super.key, this.coupon});

  final Coupon? coupon;

  @override
  State<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends State<CouponFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _description;
  late final TextEditingController _discount;
  late final TextEditingController _minimum;
  late final TextEditingController _limit;
  DateTime? _expiresAt;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final coupon = widget.coupon;
    _code = TextEditingController(text: coupon?.code ?? '');
    _description = TextEditingController(text: coupon?.description ?? '');
    _discount = TextEditingController(
      text: coupon?.discountPercent.toStringAsFixed(0) ?? '10',
    );
    _minimum = TextEditingController(
      text:
          coupon?.minimumSubtotal.toStringAsFixed(2).replaceAll('.', ',') ??
          '0,00',
    );
    _limit = TextEditingController(text: '${coupon?.usageLimit ?? ''}');
    _expiresAt = coupon?.expiresAt;
    _active = coupon?.active ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _description.dispose();
    _discount.dispose();
    _minimum.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.coupon != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'Editar cupom' : 'Criar cupom',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _AdminFormHeading(
              title: 'Condição promocional',
              subtitle: 'Defina regras claras para aplicação no carrinho.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _code,
              enabled: !editing,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Código'),
              validator: (value) => (value?.trim().length ?? 0) < 3
                  ? 'Use pelo menos 3 caracteres.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (value) => (value?.trim().length ?? 0) < 5
                  ? 'Explique o benefício do cupom.'
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Desconto',
                      suffixText: '%',
                    ),
                    validator: (value) {
                      final discount = _decimal(value ?? '');
                      return discount == null || discount <= 0 || discount > 100
                          ? 'Use 1 a 100.'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _minimum,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Compra mínima',
                      prefixText: 'R\$ ',
                    ),
                    validator: (value) => (_decimal(value ?? '') ?? -1) < 0
                        ? 'Valor inválido.'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _limit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limite de usos (opcional)',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return null;
                final limit = int.tryParse(value!);
                return limit == null || limit <= 0
                    ? 'Informe um número positivo.'
                    : null;
              },
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_outlined, color: AppColors.red),
                title: Text(
                  _expiresAt == null
                      ? 'Sem data de expiração'
                      : 'Expira em ${_shortDate(_expiresAt!)}',
                ),
                subtitle: const Text('Toque para escolher uma data'),
                trailing: _expiresAt == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        tooltip: 'Remover validade',
                        onPressed: () => setState(() => _expiresAt = null),
                        icon: const Icon(Icons.close),
                      ),
                onTap: _pickExpiry,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: const Text('Cupom ativo'),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(editing ? 'Salvar alterações' : 'Criar cupom'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) {
      setState(
        () => _expiresAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          23,
          59,
          59,
        ),
      );
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final previous = widget.coupon;
    final coupon = Coupon(
      code: _code.text.trim().toUpperCase(),
      description: _description.text.trim(),
      discountPercent: _decimal(_discount.text)!,
      minimumSubtotal: _decimal(_minimum.text)!,
      expiresAt: _expiresAt,
      active: _active,
      usageLimit: _limit.text.trim().isEmpty ? null : int.parse(_limit.text),
      usedCount: previous?.usedCount ?? 0,
    );
    AppScope.of(context).upsertCoupon(coupon);
    showAppSnackBar(context, 'Cupom ${coupon.code} salvo.');
    Navigator.of(context).pop();
  }
}

class CampaignManagementScreen extends StatelessWidget {
  const CampaignManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final campaigns = [...state.campaigns]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campanhas',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const CampaignFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nova campanha'),
      ),
      body: campaigns.isEmpty
          ? EmptyState(
              icon: Icons.campaign_outlined,
              title: 'Nenhuma campanha criada',
              description:
                  'Crie uma mensagem com período de exibição definido.',
              actionLabel: 'Criar campanha',
              onAction: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const CampaignFormScreen()),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: campaigns.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final campaign = campaigns[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                campaign.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Switch(
                              value: campaign.active,
                              onChanged: (_) =>
                                  state.toggleCampaign(campaign.id),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await Navigator.of(context).push<void>(
                                    MaterialPageRoute(
                                      builder: (_) => CampaignFormScreen(
                                        campaign: campaign,
                                      ),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  final confirmed = await _confirmDelete(
                                    context,
                                    title: 'Excluir campanha?',
                                    description:
                                        'A mensagem “${campaign.title}” deixará de estar disponível.',
                                  );
                                  if (confirmed && context.mounted) {
                                    final removed = state.removeCampaign(
                                      campaign.id,
                                    );
                                    showAppSnackBar(
                                      context,
                                      removed ? 'Campanha excluída.' : 'Não foi possível excluir a campanha.',
                                    );
                                  }
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Excluir'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          campaign.message,
                          style: const TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            StatusPill(
                              label: campaign.active ? 'Ativa' : 'Pausada',
                              color: campaign.active
                                  ? AppColors.success
                                  : AppColors.muted,
                              background: campaign.active
                                  ? AppColors.successSoft
                                  : const Color(0xFFEDEAE7),
                            ),
                            if (campaign.startAt != null)
                              StatusPill(
                                label:
                                    'Início ${_shortDate(campaign.startAt!)}',
                                color: const Color(0xFF2F6495),
                                background: const Color(0xFFE7F1FA),
                              ),
                            if (campaign.endAt != null)
                              StatusPill(
                                label: 'Fim ${_shortDate(campaign.endAt!)}',
                                color: AppColors.warning,
                                background: AppColors.warningSoft,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CampaignFormScreen extends StatefulWidget {
  const CampaignFormScreen({super.key, this.campaign});

  final Campaign? campaign;

  @override
  State<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _message;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final campaign = widget.campaign;
    _title = TextEditingController(text: campaign?.title ?? '');
    _message = TextEditingController(text: campaign?.message ?? '');
    _startAt = campaign?.startAt;
    _endAt = campaign?.endAt;
    _active = campaign?.active ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.campaign != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'Editar campanha' : 'Nova campanha',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _AdminFormHeading(
              title: 'Comunicação da campanha',
              subtitle: 'A mensagem fica salva e pode ser pausada a qualquer momento.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => (value?.trim().length ?? 0) < 4
                  ? 'Informe um título objetivo.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _message,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                alignLabelWithHint: true,
              ),
              validator: (value) => (value?.trim().length ?? 0) < 12
                  ? 'Escreva uma mensagem com ao menos 12 caracteres.'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateSelector(
                    label: 'Início',
                    value: _startAt,
                    onTap: () => _pickDate(start: true),
                    onClear: _startAt == null
                        ? null
                        : () => setState(() => _startAt = null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateSelector(
                    label: 'Fim',
                    value: _endAt,
                    onTap: () => _pickDate(start: false),
                    onClear: _endAt == null
                        ? null
                        : () => setState(() => _endAt = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: const Text('Publicar como ativa'),
              subtitle: const Text(
                'O período configurado também será respeitado.',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(editing ? 'Salvar alterações' : 'Salvar campanha'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: (start ? _startAt : _endAt) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _startAt = selected;
      } else {
        _endAt = selected;
      }
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startAt != null && _endAt != null && _endAt!.isBefore(_startAt!)) {
      showAppSnackBar(context, 'A data final deve ser posterior ao início.');
      return;
    }
    final previous = widget.campaign;
    final id =
        previous?.id ??
        'CAM-${DateTime.now().millisecondsSinceEpoch.remainder(1000000).toString().padLeft(6, '0')}';
    final campaign = Campaign(
      id: id,
      title: _title.text.trim(),
      message: _message.text.trim(),
      createdAt: previous?.createdAt ?? DateTime.now(),
      startAt: _startAt,
      endAt: _endAt,
      active: _active,
    );
    AppScope.of(context).upsertCampaign(campaign);
    showAppSnackBar(context, 'Campanha salva com sucesso.');
    Navigator.of(context).pop();
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              const Icon(Icons.event_outlined, color: AppColors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      value == null ? 'Livre' : _shortDate(value!),
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Limpar data',
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSummaryBanner extends StatelessWidget {
  const _AdminSummaryBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8DFE1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.red,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final completedOrders = state.orders
        .where((order) => order.status == OrderStatus.delivered)
        .length;
    final activeProducts = state.products
        .where((product) => product.active)
        .length;
    final statusCounts = <OrderStatus, int>{
      for (final status in OrderStatus.values)
        status: state.orders.where((order) => order.status == status).length,
    };
    final largestStatusCount = statusCounts.values.fold<int>(
      1,
      (largest, value) => value > largest ? value : largest,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relatórios',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _AdminFormHeading(
            title: 'Indicadores em tempo real',
            subtitle:
                'Resumo calculado a partir dos dados atuais do aplicativo.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ReportMetric(
                    width: width,
                    icon: Icons.payments_outlined,
                    value: money(state.totalRevenue),
                    label: 'receita entregue',
                    color: AppColors.success,
                  ),
                  _ReportMetric(
                    width: width,
                    icon: Icons.receipt_long_outlined,
                    value: '${state.orders.length}',
                    label: '$completedOrders concluídos',
                    color: const Color(0xFF2F6495),
                  ),
                  _ReportMetric(
                    width: width,
                    icon: Icons.inventory_2_outlined,
                    value: '$activeProducts',
                    label: '${state.lowStockProducts.length} com estoque baixo',
                    color: AppColors.warning,
                  ),
                  _ReportMetric(
                    width: width,
                    icon: Icons.request_quote_outlined,
                    value: '${state.quotes.length}',
                    label: '${state.pendingQuoteCount} aguardando análise',
                    color: AppColors.red,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          const SectionHeading(title: 'Pedidos por etapa'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: OrderStatus.values.map((status) {
                  final count = statusCounts[status] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _ReportBar(
                      label: status.label,
                      value: count,
                      fraction: count / largestStatusCount,
                      color: _orderColor(status),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeading(title: 'Saúde do catálogo'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.successSoft,
                    foregroundColor: AppColors.success,
                    child: Icon(Icons.check_circle_outline),
                  ),
                  title: const Text(
                    'Produtos ativos',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: Text(
                    '$activeProducts',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.warningSoft,
                    foregroundColor: AppColors.warning,
                    child: Icon(Icons.warning_amber),
                  ),
                  title: const Text(
                    'Estoque baixo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    state.lowStockProducts.isEmpty
                        ? 'Nenhum item exige reposição'
                        : state.lowStockProducts
                              .map((product) => product.shortName)
                              .join(', '),
                  ),
                  trailing: Text(
                    '${state.lowStockProducts.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Atualizado em ${_dateTime(DateTime.now())}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final double width;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 2,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportBar extends StatelessWidget {
  const _ReportBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  final String label;
  final int value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: .12),
          ),
        ),
      ],
    );
  }
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final orders =
        state.orders
            .where((order) => _filter == null || order.status == _filter)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestão de pedidos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: FilterChip(
                    selected: _filter == null,
                    label: const Text('Todos'),
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                ...OrderStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: FilterChip(
                      selected: _filter == status,
                      label: Text(status.label),
                      onSelected: (_) => setState(() => _filter = status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nenhum pedido nesta etapa',
                    description:
                        'Selecione outro filtro para consultar a fila.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final color = _orderColor(order.status);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: .12),
                            foregroundColor: color,
                            child: const Icon(Icons.receipt_long_outlined),
                          ),
                          title: Text(
                            order.id,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${_shortDate(order.createdAt)} · ${order.items.length} itens\n${order.status.label}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                money(order.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminOrderDetailScreen(orderId: order.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final _noteController = TextEditingController();
  OrderStatus? _selectedStatus;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    CustomerOrder? order;
    for (final candidate in state.orders) {
      if (candidate.id == widget.orderId) order = candidate;
    }
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhe do pedido')),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Pedido não encontrado',
          description: 'O registro não está mais disponível.',
        ),
      );
    }
    _selectedStatus ??= order.status;
    final currentOrder = order;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentOrder.id,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _AdminSummaryBanner(
            icon: Icons.receipt_long_outlined,
            title: currentOrder.status.label,
            subtitle:
                '${_dateTime(currentOrder.createdAt)} · ${money(currentOrder.total)}',
          ),
          const SizedBox(height: 22),
          const SectionHeading(title: 'Itens'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: currentOrder.items.map((item) {
                return ListTile(
                  leading: SizedBox(
                    width: 52,
                    height: 52,
                    child: ProductImage(quadrant: item.imageQuadrant),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${item.quantity} × ${money(item.unitPrice)}'),
                  trailing: Text(
                    money(item.unitPrice * item.quantity),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeading(title: 'Entrega e pagamento'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.red,
                  ),
                  title: const Text('Endereço'),
                  subtitle: Text(
                    '${currentOrder.deliveryAddress.formatted}\nCEP ${currentOrder.deliveryAddress.postalCode}',
                  ),
                  isThreeLine: true,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.red,
                  ),
                  title: const Text('Pagamento'),
                  subtitle: Text(currentOrder.paymentMethod),
                  trailing: Text(
                    money(currentOrder.total),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeading(title: 'Atualizar etapa'),
          const SizedBox(height: 8),
          DropdownButtonFormField<OrderStatus>(
            initialValue: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Novo status'),
            items: OrderStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedStatus = value),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observação para o histórico (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _selectedStatus == currentOrder.status
                ? null
                : () => _updateStatus(state, currentOrder),
            icon: const Icon(Icons.update),
            label: const Text('Atualizar pedido'),
          ),
          if (currentOrder.timeline.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeading(title: 'Histórico'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: currentOrder.timeline.reversed.map((entry) {
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: _orderColor(entry.status)
                          .withValues(alpha: .12),
                      foregroundColor: _orderColor(entry.status),
                      child: const Icon(Icons.check, size: 16),
                    ),
                    title: Text(
                      entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${entry.note.trim().isEmpty ? entry.status.label : entry.note}\n${_dateTime(entry.createdAt)}',
                    ),
                    isThreeLine: entry.note.trim().isNotEmpty,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(AppState state, CustomerOrder order) async {
    final selected = _selectedStatus;
    if (selected == null) return;
    if (selected == OrderStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.warning_amber, color: AppColors.warning),
          title: const Text('Cancelar este pedido?'),
          content: const Text(
            'O cancelamento ficará registrado no histórico do pedido.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirmar cancelamento'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    state.updateOrderStatus(
      order.id,
      selected,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    _noteController.clear();
    showAppSnackBar(context, 'Pedido atualizado para ${selected.label}.');
  }
}

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final categories = [...state.categories]..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categorias',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      body: categories.isEmpty
          ? EmptyState(
              icon: Icons.category_outlined,
              title: 'Nenhuma categoria cadastrada',
              description: 'Crie a primeira organização para o catálogo.',
              actionLabel: 'Criar categoria',
              onAction: () => _add(context, state),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final count = state.products
                    .where((product) => product.category == category)
                    .length;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF8DFE1),
                      foregroundColor: AppColors.red,
                      child: Icon(Icons.category_outlined),
                    ),
                    title: Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      '$count ${count == 1 ? 'produto' : 'produtos'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Ações da categoria',
                      onSelected: (value) {
                        if (value == 'rename') {
                          _rename(context, state, category);
                        } else if (value == 'delete') {
                          _delete(context, state, category, count);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Renomear')),
                        PopupMenuItem(value: 'delete', child: Text('Excluir')),
                      ],
                    ),
                    onTap: () => _rename(context, state, category),
                  ),
                );
              },
            ),
    );
  }

  Future<String?> _nameDialog(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome da categoria'),
          onSubmitted: (value) {
            if (value.trim().length >= 3) {
              Navigator.of(dialogContext).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 3) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _add(BuildContext context, AppState state) async {
    final name = await _nameDialog(context, title: 'Nova categoria');
    if (name == null || !context.mounted) return;
    final created = state.addCategory(name);
    showAppSnackBar(
      context,
      created ? 'Categoria $name criada.' : 'Essa categoria já existe.',
    );
  }

  Future<void> _rename(
    BuildContext context,
    AppState state,
    String category,
  ) async {
    final name = await _nameDialog(
      context,
      title: 'Renomear categoria',
      initialValue: category,
    );
    if (name == null || name == category || !context.mounted) return;
    final renamed = state.renameCategory(category, name);
    showAppSnackBar(
      context,
      renamed
          ? 'Categoria renomeada para $name.'
          : 'Não foi possível renomear. Verifique se o nome já existe.',
    );
  }

  Future<void> _delete(
    BuildContext context,
    AppState state,
    String category,
    int productCount,
  ) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Excluir $category?',
      description: productCount == 0
          ? 'A categoria será removida da organização do catálogo.'
          : 'Há $productCount produto(s) nesta categoria. Mova-os antes de excluir.',
    );
    if (!confirmed || !context.mounted) return;
    final removed = state.removeCategory(category);
    showAppSnackBar(
      context,
      removed
          ? 'Categoria $category excluída.'
          : 'Categoria em uso. Reclassifique os produtos primeiro.',
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _role = 'Todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final query = _query.trim().toLowerCase();
    final users = state.users.where((user) {
      final roleMatches = _role == 'Todos' || user.role == _role;
      final queryMatches =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      return roleMatches && queryMatches;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Usuários',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou e-mail',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Todos', label: Text('Todos')),
                    ButtonSegment(value: 'client', label: Text('Clientes')),
                    ButtonSegment(value: 'admin', label: Text('Admins')),
                  ],
                  selected: {_role},
                  onSelectionChanged: (selection) =>
                      setState(() => _role = selection.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: users.isEmpty
                ? const EmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'Nenhum usuário encontrado',
                    description: 'Revise a busca ou o perfil selecionado.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _UserAdminCard(user: users[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserAdminCard extends StatelessWidget {
  const _UserAdminCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim().substring(0, 1).toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: user.blocked
                  ? const Color(0xFFEDEAE7)
                  : const Color(0xFFF8DFE1),
              foregroundColor: user.blocked ? AppColors.muted : AppColors.red,
              child: Text(initial),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      StatusPill(
                        label: user.role == 'admin'
                            ? 'Administrador'
                            : 'Cliente',
                        color: user.role == 'admin'
                            ? const Color(0xFF2F6495)
                            : AppColors.success,
                        background: user.role == 'admin'
                            ? const Color(0xFFE7F1FA)
                            : AppColors.successSoft,
                      ),
                      if (user.blocked)
                        const StatusPill(
                          label: 'Bloqueado',
                          color: AppColors.red,
                          background: Color(0xFFFFE7E8),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Gerenciar usuário',
              onSelected: (value) async {
                if (value == 'role') {
                  final role = user.role == 'admin' ? 'client' : 'admin';
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Alterar nível de acesso?'),
                      content: Text(
                        role == 'admin'
                            ? '${user.name} poderá acessar funções administrativas.'
                            : '${user.name} voltará a ter acesso somente como cliente.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    state.setUserRole(user.id, role);
                    showAppSnackBar(context, 'Nível de acesso atualizado.');
                  }
                } else if (value == 'block') {
                  final nextValue = !user.blocked;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(
                        nextValue
                            ? 'Bloquear usuário?'
                            : 'Desbloquear usuário?',
                      ),
                      content: Text(
                        nextValue
                            ? '${user.name} não poderá entrar até ser desbloqueado.'
                            : '${user.name} poderá acessar a conta novamente.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          style: nextValue
                              ? FilledButton.styleFrom(
                                  backgroundColor: AppColors.red,
                                )
                              : null,
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Text(nextValue ? 'Bloquear' : 'Desbloquear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    state.setUserBlocked(user.id, nextValue);
                    showAppSnackBar(
                      context,
                      nextValue
                          ? 'Usuário bloqueado.'
                          : 'Usuário desbloqueado.',
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'role',
                  child: Text(
                    user.role == 'admin' ? 'Tornar cliente' : 'Tornar admin',
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Text(user.blocked ? 'Desbloquear' : 'Bloquear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuoteManagementScreen extends StatefulWidget {
  const QuoteManagementScreen({super.key});

  @override
  State<QuoteManagementScreen> createState() => _QuoteManagementScreenState();
}

class _QuoteManagementScreenState extends State<QuoteManagementScreen> {
  QuoteStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final quotes =
        state.quotes
            .where((quote) => _filter == null || quote.status == _filter)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orçamentos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: FilterChip(
                    selected: _filter == null,
                    label: const Text('Todos'),
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                ...QuoteStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: FilterChip(
                      selected: _filter == status,
                      label: Text(status.label),
                      onSelected: (_) => setState(() => _filter = status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: quotes.isEmpty
                ? const EmptyState(
                    icon: Icons.request_quote_outlined,
                    title: 'Nenhum orçamento nesta etapa',
                    description:
                        'Selecione outro filtro para consultar a fila.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: quotes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      final color = _quoteColor(quote.status);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: .12),
                            foregroundColor: color,
                            child: const Icon(Icons.request_quote_outlined),
                          ),
                          title: Text(
                            quote.id,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${quote.customerName} · ${quote.productName}\n${quote.status.label}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuoteDetailScreen(quoteId: quote.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  final _responseController = TextEditingController();
  QuoteStatus? _selectedStatus;
  bool _initialized = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    QuoteRequest? quote;
    for (final candidate in state.quotes) {
      if (candidate.id == widget.quoteId) quote = candidate;
    }
    if (quote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhe do orçamento')),
        body: const EmptyState(
          icon: Icons.request_quote_outlined,
          title: 'Orçamento não encontrado',
          description: 'O registro não está mais disponível.',
        ),
      );
    }
    final currentQuote = quote;
    if (!_initialized) {
      _selectedStatus = currentQuote.status;
      _responseController.text = currentQuote.response ?? '';
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentQuote.id,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _AdminSummaryBanner(
            icon: Icons.request_quote_outlined,
            title: currentQuote.status.label,
            subtitle:
                '${currentQuote.productName} · ${_dateTime(currentQuote.createdAt)}',
          ),
          const SizedBox(height: 20),
          const SectionHeading(title: 'Solicitante'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: AppColors.red,
                  ),
                  title: Text(currentQuote.customerName),
                  subtitle: Text(currentQuote.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.red,
                  ),
                  title: const Text('Telefone'),
                  subtitle: Text(currentQuote.phone),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeading(title: 'Solicitação'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                currentQuote.details,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeading(title: 'Análise e resposta'),
          const SizedBox(height: 8),
          DropdownButtonFormField<QuoteStatus>(
            initialValue: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: QuoteStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedStatus = value),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _responseController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Resposta ao cliente',
              hintText: 'Informe condições, prazo e próximos passos',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _save(state, currentQuote),
            icon: const Icon(Icons.send_outlined),
            label: const Text('Salvar e responder'),
          ),
          if (currentQuote.updatedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Última atualização em ${_dateTime(currentQuote.updatedAt!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  void _save(AppState state, QuoteRequest quote) {
    final response = _responseController.text.trim();
    final status = _selectedStatus ?? quote.status;
    if ((status == QuoteStatus.approved ||
            status == QuoteStatus.rejected ||
            status == QuoteStatus.answered) &&
        response.length < 8) {
      showAppSnackBar(
        context,
        'Inclua uma resposta clara antes de concluir o orçamento.',
      );
      return;
    }
    state.updateQuoteStatus(
      quote.id,
      status,
      response: response.isEmpty ? null : response,
    );
    showAppSnackBar(context, 'Orçamento atualizado para ${status.label}.');
  }
}
