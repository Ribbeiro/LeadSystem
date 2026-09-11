import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../models/product.dart';
import '../widgets/shared.dart';
import 'auth_admin.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  final TextEditingController _postalCodeController = TextEditingController();
  String? _deliveryResult;
  String? _postalCodeError;

  @override
  void dispose() {
    _postalCodeController.dispose();
    super.dispose();
  }

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
              Expanded(
                child: TextField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  decoration: InputDecoration(
                    hintText: 'CEP',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    errorText: _postalCodeError,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _calculateDelivery(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 112,
                child: OutlinedButton(
                  onPressed: _calculateDelivery,
                  child: const Text('Calcular'),
                ),
              ),
            ],
          ),
          if (_deliveryResult != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _deliveryResult!,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            onPressed: () async {
              if (!state.loggedIn) {
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                if (!context.mounted || !state.loggedIn) return;
              }
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuoteScreen(product: product),
                ),
              );
            },
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Solicitar orçamento'),
          ),
        ],
      ),
    );
  }

  void _calculateDelivery() {
    final estimate = AppScope.of(context)
        .calculateShipping(_postalCodeController.text);
    if (estimate == null) {
      setState(() {
        _postalCodeError = 'Digite os 8 números do CEP.';
        _deliveryResult = null;
      });
      return;
    }
    setState(() {
      _postalCodeError = null;
      _deliveryResult =
          'Entrega estimada entre ${estimate.estimatedStart.day}/${estimate.estimatedStart.month} e '
          '${estimate.estimatedEnd.day}/${estimate.estimatedEnd.month} · ${money(estimate.cost)}';
    });
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
                      onIncrease: () {
                        if (entry.value >= product.stock) {
                          showAppSnackBar(
                            context,
                            'Estoque máximo disponível: ${product.stock}.',
                          );
                          return;
                        }
                        state.setQuantity(product.id, entry.value + 1);
                      },
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
                  onPressed: () async {
                    if (!state.loggedIn) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      if (!context.mounted || !state.loggedIn) return;
                    }
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    );
                  },
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
                    onPressed: quantity < product.stock ? onIncrease : null,
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
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  String payment = 'Pix';
  bool accepted = true;
  bool processing = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final address = AppScope.of(context).defaultAddress;
    _streetController.text = address?.street ?? '';
    _numberController.text = address?.number ?? '';
    _neighborhoodController.text = address?.neighborhood ?? '';
    _cityController.text = address?.city ?? '';
    _stateController.text = address?.state ?? 'SP';
    _postalCodeController.text = address?.postalCode ?? '';
    _cardHolderController.text = AppScope.of(context).userName;
    _initialized = true;
  }

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _streetController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Rua'),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Informe a rua.'
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _numberController,
                    keyboardType: TextInputType.streetAddress,
                    decoration: const InputDecoration(labelText: 'Número'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Obrigatório.'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _neighborhoodController,
                    decoration: const InputDecoration(labelText: 'Bairro'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o bairro.'
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _postalCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CEP'),
                    validator: (value) =>
                        (value ?? '').replaceAll(RegExp(r'\D'), '').length == 8
                        ? null
                        : 'CEP inválido.',
                  ),
                ),
              ],
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
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe a cidade.'
                        : null,
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
                    validator: (value) =>
                        value == null || value.trim().length != 2
                        ? 'UF inválida.'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.defaultAddress == null
                        ? 'O endereço será salvo para as próximas compras.'
                        : 'Você pode alterar os dados para este pedido.',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                    ),
                  ),
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
            if (payment == 'Cartão') ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número do cartão',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (value) {
                  if (payment != 'Cartão') return null;
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  return digits.length >= 13 ? null : 'Número inválido.';
                },
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cardHolderController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome no cartão',
                      ),
                      validator: (value) =>
                          payment == 'Cartão' &&
                              (value == null || value.trim().length < 3)
                          ? 'Informe o nome.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cardCvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'CVV'),
                      validator: (value) =>
                          payment == 'Cartão' &&
                              (value ?? '')
                                      .replaceAll(RegExp(r'\D'), '')
                                      .length <
                                  3
                          ? 'Inválido.'
                          : null,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      payment == 'Pix'
                          ? Icons.qr_code_2_rounded
                          : Icons.receipt_long_outlined,
                      color: AppColors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        payment == 'Pix'
                            ? 'O código Pix será exibido após a confirmação.'
                            : 'O boleto será gerado com vencimento em 2 dias úteis.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    try {
      state.calculateShipping(_postalCodeController.text);
      final current = state.defaultAddress;
      late final Address address;
      if (current == null) {
        address = state.addAddress(
          label: 'Entrega',
          street: _streetController.text,
          number: _numberController.text,
          neighborhood: _neighborhoodController.text,
          city: _cityController.text,
          state: _stateController.text,
          postalCode: _postalCodeController.text,
          makeDefault: true,
        );
      } else {
        address = current.copyWith(
          street: _streetController.text.trim(),
          number: _numberController.text.trim(),
          neighborhood: _neighborhoodController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim().toUpperCase(),
          postalCode: _postalCodeController.text.trim(),
        );
        state.updateAddress(address);
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final order = state.placeOrder(address: address, paymentMethod: payment);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      );
    } on StateError catch (error) {
      if (!context.mounted) return;
      setState(() => processing = false);
      showAppSnackBar(context, error.message.toString());
    }
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
  const OrderSuccessScreen({super.key, required this.order});

  final CustomerOrder order;

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
                      _SummaryRow(label: 'Pedido', value: order.id),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Pagamento',
                        value: order.paymentMethod,
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Total',
                        value: money(order.total),
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
  const TrackingScreen({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final updatedAt = order.timeline.isEmpty
        ? order.createdAt
        : order.timeline.last.createdAt;
    final stages = _stages(order);
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido ${order.id}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          order.status.label,
                          style: const TextStyle(color: AppColors.success),
                        ),
                        Text(
                          'Atualizado em ${_dateTime(updatedAt)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: order.status == OrderStatus.cancelled
                        ? 'Cancelado'
                        : 'No prazo',
                    color: order.status == OrderStatus.cancelled
                        ? AppColors.red
                        : AppColors.success,
                    background: order.status == OrderStatus.cancelled
                        ? const Color(0xFFFFE7E8)
                        : AppColors.successSoft,
                  ),
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
          ...stages,
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entrega estimada',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _deliveryDate(order.createdAt),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    order.deliveryAddress.formatted,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              state.sendMessage('Preciso de ajuda com o pedido ${order.id}.');
              state.setNavigationIndex(3);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('Falar com o atendimento'),
          ),
        ],
      ),
    );
  }

  List<Widget> _stages(CustomerOrder order) {
    if (order.status == OrderStatus.cancelled) {
      return order.timeline
          .map(
            (entry) => _TimelineItem(
              title: entry.title,
              subtitle: '${_dateTime(entry.createdAt)} · ${entry.note}',
              done: true,
              current: entry.status == order.status,
            ),
          )
          .toList();
    }
    const statusFlow = [
      OrderStatus.received,
      OrderStatus.paymentApproved,
      OrderStatus.preparing,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];
    final currentIndex = statusFlow.indexOf(order.status);
    return statusFlow.map((status) {
      final entry = order.timeline
          .where((item) => item.status == status)
          .firstOrNull;
      final index = statusFlow.indexOf(status);
      final done = index <= currentIndex;
      return _TimelineItem(
        title: status.label,
        subtitle: entry == null
            ? (status == OrderStatus.delivered
                  ? 'Previsão: ${_deliveryDate(order.createdAt)}'
                  : 'Aguardando atualização')
            : '${_dateTime(entry.createdAt)} · ${entry.note}',
        done: done,
        current: index == currentIndex,
      );
    }).toList();
  }

  static String _dateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month às $hour:$minute';
  }

  static String _deliveryDate(DateTime createdAt) {
    final start = createdAt.add(const Duration(days: 3));
    final end = createdAt.add(const Duration(days: 5));
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} a '
        '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool sending = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final state = AppScope.of(context);
    _nameController.text = state.loggedIn ? state.userName : '';
    _phoneController.text = state.userPhone;
    _emailController.text = state.userEmail;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

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
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe seu nome.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
              validator: (value) => value == null || value.trim().length < 8
                  ? 'Informe um telefone válido.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (value) => value != null && value.contains('@')
                  ? null
                  : 'Informe um e-mail válido.',
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Detalhes da solicitação',
                hintText: 'Quantidade, data do evento e observações',
              ),
              validator: (value) => value == null || value.trim().length < 10
                  ? 'Descreva a quantidade e a necessidade do orçamento.'
                  : null,
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
    final state = AppScope.of(context);
    final quote = state.submitQuote(
      product: widget.product,
      customerName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      details: _detailsController.text,
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => sending = false);
    final openOrders = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 42,
        ),
        title: const Text('Orçamento enviado'),
        content: Text(
          'Protocolo ${quote.id}. A solicitação já está salva e aparecerá na área de pedidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar no produto'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ver orçamento'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (openOrders == true) {
      state.setNavigationIndex(2);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pop();
    }
  }
}
