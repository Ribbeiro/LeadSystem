import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/product.dart';
import '../widgets/shared.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final product = widget.product;
    final favorite = state.favorites.contains(product.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes do produto',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Badge(
            isLabelVisible: state.cartCount > 0,
            label: Text('${state.cartCount}'),
            child: IconButton(
              tooltip: 'Carrinho',
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CartScreen())),
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          AspectRatio(
            aspectRatio: 1.35,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductImage(quadrant: product.imageQuadrant),
                ),
                if (product.badge != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: StatusPill(
                      label: product.badge!,
                      color: AppColors.red,
                      background: const Color(0xFFFFE7E8),
                    ),
                  ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton.filledTonal(
                    tooltip: favorite ? 'Remover dos favoritos' : 'Favoritar',
                    onPressed: () => state.toggleFavorite(product.id),
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const StatusPill(label: 'Em estoque'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.warning,
                size: 19,
              ),
              Text(
                ' ${product.rating.toStringAsFixed(1).replaceAll('.', ',')}  ',
              ),
              Text(
                '${product.reviewCount} avaliações',
                style: const TextStyle(color: AppColors.muted),
              ),
              const Spacer(),
              Text(
                'SKU ${product.id}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            money(product.price),
            style: const TextStyle(
              color: AppColors.darkRed,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(product.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 22),
          const SectionHeading(title: 'Especificações'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: product.specifications.entries
                  .map(
                    (entry) => ListTile(
                      dense: true,
                      title: Text(
                        entry.key,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      trailing: Text(
                        entry.value,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Calcule o frete',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'CEP',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 112,
                child: OutlinedButton(
                  onPressed: () => showAppSnackBar(
                    context,
                    'Entrega entre 12 e 14 set · frete R\$ 24,90',
                  ),
                  child: const Text('Calcular'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Quantidade',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton.outlined(
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton.outlined(
                onPressed: quantity < product.stock
                    ? () => setState(() => quantity++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              state.addToCart(product, quantity: quantity);
              showAppSnackBar(
                context,
                '$quantity item(ns) adicionado(s) ao carrinho.',
              );
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(
              'Adicionar ao carrinho · ${money(product.price * quantity)}',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => QuoteScreen(product: product)),
            ),
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Solicitar orçamento'),
          ),
        ],
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController(
    text: 'PRIMEIRACOMPRA',
  );

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seu carrinho',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: state.cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Seu carrinho está vazio',
              description: 'Adicione produtos para revisar quantidades, usar cupom e concluir a compra.',
              actionLabel: 'Continuar comprando',
              onAction: () => Navigator.of(context).pop(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: StatusPill(
                    label:
                        '${state.cartCount} ${state.cartCount == 1 ? 'item' : 'itens'}',
                    color: AppColors.red,
                    background: const Color(0xFFFFE7E8),
                  ),
                ),
                const SizedBox(height: 12),
                ...state.cart.entries.map((entry) {
                  final product = state.productById(entry.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CartItem(
                      product: product,
                      quantity: entry.value,
                      onDecrease: () =>
                          state.setQuantity(product.id, entry.value - 1),
                      onIncrease: () =>
                          state.setQuantity(product.id, entry.value + 1),
                      onRemove: () =>
                          _remove(context, state, product, entry.value),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                const Text(
                  'Cupom',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 112,
                      child: OutlinedButton(
                        onPressed: () {
                          final valid = state.applyCoupon(
                            _couponController.text,
                          );
                          showAppSnackBar(
                            context,
                            valid
                                ? 'Cupom aplicado: 10% de desconto.'
                                : 'Cupom inválido ou expirado.',
                          );
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
                if (state.couponApplied) ...[
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PRIMEIRACOMPRA aplicado',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                _OrderSummary(state: state),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  ),
                  child: const Text('Ir para pagamento'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Continuar comprando'),
                ),
              ],
            ),
    );
  }

  void _remove(
    BuildContext context,
    AppState state,
    Product product,
    int quantity,
  ) {
    state.setQuantity(product.id, 0);
    showAppSnackBar(
      context,
      '${product.shortName} removido.',
      action: SnackBarAction(
        label: 'DESFAZER',
        onPressed: () => state.setQuantity(product.id, quantity),
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  const _CartItem({
    required this.product,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final Product product;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 86,
              height: 86,
              child: ProductImage(quadrant: product.imageQuadrant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.shortName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    money(product.price),
                    style: const TextStyle(
                      color: AppColors.darkRed,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextButton(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 30),
                    ),
                    child: const Text('Remover'),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDecrease,
                    icon: const Icon(Icons.remove, size: 17),
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onIncrease,
                    icon: const Icon(Icons.add, size: 17),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _SummaryRow(label: 'Subtotal', value: money(state.subtotal)),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Desconto',
              value: state.discount > 0
                  ? '- ${money(state.discount)}'
                  : 'R\$ 0,00',
              success: state.discount > 0,
            ),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Frete', value: money(state.shipping)),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Total',
              value: money(state.total),
              emphasis: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasis = false,
    this.success = false,
  });

  final String label;
  final String value;
  final bool emphasis;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: emphasis ? FontWeight.w900 : FontWeight.w400,
            fontSize: emphasis ? 17 : 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: success
                ? AppColors.success
                : (emphasis ? AppColors.darkRed : AppColors.ink),
            fontWeight: emphasis ? FontWeight.w900 : FontWeight.w600,
            fontSize: emphasis ? 18 : 14,
          ),
        ),
      ],
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String payment = 'Pix';
  bool accepted = true;
  bool processing = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finalizar compra',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _CheckoutSteps(),
            const SizedBox(height: 22),
            const Text(
              'Endereço de entrega',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: 'Rua Amazonas, 50',
              decoration: const InputDecoration(labelText: 'Endereço'),
              validator: (value) => value == null || value.trim().length < 5
                  ? 'Informe o endereço completo.'
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: 'Centro',
                    decoration: const InputDecoration(labelText: 'Bairro'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: '09520-070',
                    decoration: const InputDecoration(labelText: 'CEP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.verified, color: AppColors.success, size: 18),
                SizedBox(width: 6),
                Text(
                  'Endereço verificado · São Caetano do Sul/SP',
                  style: TextStyle(color: AppColors.success, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Forma de pagamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: payment,
              onChanged: (value) {
                if (value != null) setState(() => payment = value);
              },
              child: Column(
                children: [
                  _PaymentTile(
                    value: 'Pix',
                    subtitle: 'Aprovação imediata',
                    selected: payment == 'Pix',
                  ),
                  _PaymentTile(
                    value: 'Cartão',
                    subtitle: 'Até 6x sem juros',
                    selected: payment == 'Cartão',
                  ),
                  _PaymentTile(
                    value: 'Boleto',
                    subtitle: 'Vencimento em 2 dias',
                    selected: payment == 'Boleto',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _OrderSummary(state: state),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: accepted,
              onChanged: (value) => setState(() => accepted = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Confirmo os dados do pedido e aceito os termos.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: !accepted || processing
                  ? null
                  : () => _finish(context, state),
              child: processing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text('Finalizar pedido · ${money(state.total)}'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context, AppState state) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => processing = true);
    final orderTotal = state.total;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!context.mounted) return;
    state.placeOrder();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(total: orderTotal, payment: payment),
      ),
    );
  }
}

class _CheckoutSteps extends StatelessWidget {
  const _CheckoutSteps();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StepBadge(number: '1', label: 'Entrega', done: true),
        Expanded(child: Divider(color: AppColors.red)),
        _StepBadge(number: '2', label: 'Pagamento', active: true),
        Expanded(child: Divider()),
        _StepBadge(number: '3', label: 'Revisão'),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.number,
    required this.label,
    this.active = false,
    this.done = false,
  });

  final String number;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final highlighted = active || done;
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: highlighted ? AppColors.red : Colors.white,
          foregroundColor: highlighted ? Colors.white : AppColors.muted,
          child: done ? const Icon(Icons.check, size: 17) : Text(number),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: highlighted ? AppColors.red : AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.value,
    required this.subtitle,
    required this.selected,
  });

  final String value;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.red : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        title: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.total,
    required this.payment,
  });

  final double total;
  final String payment;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.successSoft,
                foregroundColor: AppColors.success,
                child: Icon(Icons.check_rounded, size: 52),
              ),
              const SizedBox(height: 22),
              const Text(
                'Pedido realizado!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Recebemos seu pedido e enviaremos atualizações a cada mudança de status.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const _SummaryRow(
                        label: 'Pedido',
                        value: '#SG-2026-0148',
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(label: 'Pagamento', value: payment),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Total',
                        value: money(total),
                        emphasis: true,
                      ),
                      const SizedBox(height: 10),
                      const _SummaryRow(
                        label: 'Previsão',
                        value: '12 a 14 de setembro',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  state.setNavigationIndex(2);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Acompanhar pedido'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  state.setNavigationIndex(0);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Acompanhar pedido',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.successSoft,
                    foregroundColor: AppColors.success,
                    child: Icon(Icons.local_shipping_outlined),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #SG-2026-0147',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Em transporte',
                          style: TextStyle(color: AppColors.success),
                        ),
                        Text(
                          'Atualizado hoje às 14:28',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const StatusPill(label: 'No prazo'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Andamento',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const _TimelineItem(
            title: 'Pedido recebido',
            subtitle: '10 set · 14:32',
            done: true,
          ),
          const _TimelineItem(
            title: 'Pagamento aprovado',
            subtitle: '10 set · 14:35',
            done: true,
          ),
          const _TimelineItem(
            title: 'Em transporte',
            subtitle: '11 set · 09:10',
            done: true,
            current: true,
          ),
          const _TimelineItem(
            title: 'Entregue',
            subtitle: 'Previsto até 14 set',
          ),
          const SizedBox(height: 20),
          Card(
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entrega estimada',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '12 a 14 de setembro',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Rua Amazonas, 50 · Centro',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => showAppSnackBar(
              context,
              'Atendimento avisado sobre o pedido #SG-2026-0147.',
            ),
            icon: const Icon(Icons.support_agent),
            label: const Text('Falar com o atendimento'),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    this.done = false,
    this.current = false,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: done ? AppColors.red : Colors.white,
                  foregroundColor: done ? Colors.white : AppColors.muted,
                  child: done
                      ? const Icon(Icons.check, size: 15)
                      : const SizedBox.shrink(),
                ),
                Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: current ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key, required this.product});

  final Product product;

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Solicitar orçamento',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: ProductImage(
                        quadrant: widget.product.imageQuadrant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            money(widget.product.price),
                            style: const TextStyle(
                              color: AppColors.darkRed,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              initialValue: 'Leandro Gonçalves Ribeiro Junior',
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe seu nome.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: '(11) 99999-4321',
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
              validator: (value) => value == null || value.trim().length < 8
                  ? 'Informe um telefone válido.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: 'leandro@email.com',
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (value) => value != null && value.contains('@')
                  ? null
                  : 'Informe um e-mail válido.',
            ),
            const SizedBox(height: 10),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Detalhes da solicitação',
                hintText: 'Quantidade, data do evento e observações',
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.schedule, color: AppColors.success, size: 18),
                SizedBox(width: 7),
                Text(
                  'Resposta em até 1 dia útil',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: sending ? null : _send,
              child: sending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar orçamento'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => sending = false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 42,
        ),
        title: const Text('Orçamento enviado'),
        content: const Text(
          'Protocolo #ORC-2026-0085. Você receberá atualizações na área de pedidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
