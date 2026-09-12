import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../models/product.dart';
import '../widgets/shared.dart';
import 'auth_admin.dart';
import 'detail_flows.dart';
import 'profile_flows.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const pages = <Widget>[
      HomeScreen(),
      CatalogScreen(),
      OrdersScreen(),
      HelpScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: state.navigationIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.navigationIndex,
        onDestinationSelected: state.setNavigationIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Ajuda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

void _openCart(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const CartScreen()));
}

void _openProduct(BuildContext context, Product product) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final featuredProducts = state.products
        .where((product) => product.active)
        .toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AppTopBar(
            cartCount: state.cartCount,
            onCartTap: () => _openCart(context),
            onProfileTap: () => state.setNavigationIndex(4),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverList.list(
            children: [
              const Text(
                'Olá! O que vamos preparar?',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Busque churrasqueiras, grelhas...',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) {
                  state.setSearch(value);
                  state.setNavigationIndex(1);
                },
              ),
              const SizedBox(height: 18),
              if (featuredProducts.isNotEmpty) ...[
                _PromoBanner(
                  onTap: () => _openProduct(
                    context,
                    featuredProducts.length > 1
                        ? featuredProducts[1]
                        : featuredProducts.first,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const SectionHeading(title: 'Categorias'),
              const SizedBox(height: 10),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: state.categories
                      .where((item) => item != 'Todos')
                      .map(
                        (item) => _CategoryTile(
                          icon: _categoryIcon(item),
                          label: item,
                          onTap: () => _selectCategory(state, item),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              SectionHeading(
                title: 'Mais vendidos',
                action: 'Ver todos',
                onAction: () {
                  state.setSearch('');
                  state.setCategory('Todos');
                  state.setNavigationIndex(1);
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 302,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredProducts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = featuredProducts[index];
                    return SizedBox(
                      width: 220,
                      child: ProductCard(
                        product: product,
                        favorite: state.favorites.contains(product.id),
                        onTap: () => _openProduct(context, product),
                        onAdd: () {
                          state.addToCart(product);
                          showAppSnackBar(
                            context,
                            '${product.shortName} adicionado ao carrinho.',
                          );
                        },
                        onFavorite: () => state.toggleFavorite(product.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const _TrustStrip(),
            ],
          ),
        ),
      ],
    );
  }

  void _selectCategory(AppState state, String category) {
    state.setCategory(category);
    state.setNavigationIndex(1);
  }

  IconData _categoryIcon(String category) => switch (category) {
    'Churrasqueiras' => Icons.outdoor_grill,
    'Grelhas' => Icons.view_in_ar_outlined,
    'Espetos' => Icons.horizontal_rule_rounded,
    'Kits' => Icons.inventory_2_outlined,
    _ => Icons.category_outlined,
  };
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkRed,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 170,
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHURRASCO DE\nDOMINGO COMEÇA AQUI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '10% na primeira compra',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PRIMEIRACOMPRA',
                            style: TextStyle(
                              color: AppColors.darkRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(
                flex: 5,
                child: ProductImage(
                  quadrant: 1,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(38),
                    bottomLeft: Radius.circular(38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 108,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.red),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
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

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Row(
          children: const [
            Expanded(
              child: _TrustItem(
                icon: Icons.verified_user_outlined,
                label: 'Compra segura',
              ),
            ),
            Expanded(
              child: _TrustItem(
                icon: Icons.local_shipping_outlined,
                label: 'Envio rastreado',
              ),
            ),
            Expanded(
              child: _TrustItem(
                icon: Icons.support_agent,
                label: 'Suporte rápido',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.red),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _searchController.text = AppScope.of(context).searchQuery;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final products = state.filteredProducts;
    return Column(
      children: [
        AppTopBar(
          title: 'Catálogo',
          cartCount: state.cartCount,
          onCartTap: () => _openCart(context),
          onProfileTap: () => state.setNavigationIndex(4),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                sliver: SliverList.list(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar produto',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: () {
                                  _searchController.clear();
                                  state.setSearch('');
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                      onChanged: (value) {
                        state.setSearch(value);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            [
                                  'Todos',
                                  ...state.categories.where(
                                    (item) => item != 'Todos',
                                  ),
                                ]
                                .map(
                                  (category) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      selected: state.category == category,
                                      label: Text(category),
                                      onSelected: (_) =>
                                          state.setCategory(category),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${products.length} produtos',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const Spacer(),
                        PopupMenuButton<ProductSort>(
                          tooltip: 'Ordenar produtos',
                          initialValue: state.productSort,
                          onSelected: state.setProductSort,
                          itemBuilder: (context) => ProductSort.values
                              .map(
                                (value) => PopupMenuItem(
                                  value: value,
                                  child: Text(value.label),
                                ),
                              )
                              .toList(),
                          child: Row(
                            children: [
                              const Icon(Icons.swap_vert, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                state.productSort.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'Nenhum produto encontrado',
                    description:
                        'Tente outro termo ou limpe os filtros aplicados.',
                    actionLabel: 'Limpar filtros',
                    onAction: () {
                      _searchController.clear();
                      state.setSearch('');
                      state.setCategory('Todos');
                      setState(() {});
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: .65,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        favorite: state.favorites.contains(product.id),
                        onTap: () => _openProduct(context, product),
                        onAdd: () {
                          state.addToCart(product);
                          showAppSnackBar(
                            context,
                            '${product.shortName} adicionado ao carrinho.',
                          );
                        },
                        onFavorite: () => state.toggleFavorite(product.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      children: [
        AppTopBar(
          title: 'Meus pedidos',
          cartCount: state.cartCount,
          onCartTap: () => _openCart(context),
          onProfileTap: () => state.setNavigationIndex(4),
        ),
        Expanded(
          child: !state.loggedIn
              ? EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Entre para ver seus pedidos',
                  description: 'Seu histórico, rastreamento e orçamentos ficam protegidos na sua conta.',
                  actionLabel: 'Entrar',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (state.orders.isEmpty && state.quotes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Nenhum pedido ainda',
                          description: 'Seus pedidos e solicitações de orçamento aparecerão aqui.',
                        ),
                      ),
                    ...state.orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OrderCard(
                          number: order.id,
                          date: _shortDate(order.createdAt),
                          total: money(order.total),
                          status: order.status.label,
                          current:
                              order.status != OrderStatus.delivered &&
                              order.status != OrderStatus.cancelled,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TrackingScreen(order: order),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (state.quotes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Orçamentos',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.quotes.map(
                        (quote) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor:
                                  quote.status == QuoteStatus.approved
                                  ? AppColors.successSoft
                                  : AppColors.warningSoft,
                              foregroundColor:
                                  quote.status == QuoteStatus.approved
                                  ? AppColors.success
                                  : AppColors.warning,
                              child: const Icon(Icons.request_quote_outlined),
                            ),
                            title: Text(
                              quote.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${quote.productName} · ${quote.status.label}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showQuote(context, quote),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  static String _shortDate(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static Future<void> _showQuote(BuildContext context, QuoteRequest quote) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.request_quote_outlined, color: AppColors.red),
        title: Text('Orçamento ${quote.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote.productName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              StatusPill(label: quote.status.label),
              const SizedBox(height: 14),
              Text(quote.details),
              if (quote.response?.trim().isNotEmpty ?? false) ...[
                const Divider(height: 28),
                const Text(
                  'Resposta da equipe',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(quote.response!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.number,
    required this.date,
    required this.total,
    required this.status,
    this.current = false,
    this.onTap,
  });

  final String number;
  final String date;
  final String total;
  final String status;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  StatusPill(
                    label: status,
                    color: current ? AppColors.warning : AppColors.success,
                    background: current
                        ? AppColors.warningSoft
                        : AppColors.successSoft,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$date  ·  $total',
                style: const TextStyle(color: AppColors.muted),
              ),
              if (onTap != null) ...[
                const Divider(height: 28),
                const Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.red,
                      size: 19,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Acompanhar pedido',
                      style: TextStyle(
                        color: AppColors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right, color: AppColors.red),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _faqQuery = '';

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final query = _faqQuery.trim().toLowerCase();
    final faqs = _faqEntries
        .where(
          (faq) =>
              query.isEmpty ||
              faq.title.toLowerCase().contains(query) ||
              faq.subtitle.toLowerCase().contains(query) ||
              faq.answer.toLowerCase().contains(query),
        )
        .toList();
    return Column(
      children: [
        AppTopBar(
          title: 'Ajuda e atendimento',
          cartCount: state.cartCount,
          onCartTap: () => _openCart(context),
          onProfileTap: () => state.setNavigationIndex(4),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Como podemos ajudar?',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _faqQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _faqQuery = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (value) => setState(() => _faqQuery = value),
              ),
              const SizedBox(height: 20),
              const SectionHeading(title: 'Encontre uma resposta'),
              const SizedBox(height: 8),
              if (faqs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Nenhuma resposta encontrada. Envie sua dúvida no atendimento abaixo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                ...faqs.map((faq) => _FaqTile(faq: faq)),
              const SizedBox(height: 24),
              const SectionHeading(title: 'Converse com a equipe'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.successSoft,
                            foregroundColor: AppColors.success,
                            child: Text('M'),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mariana · Atendimento',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '● Online · responde em cerca de 2 min',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      ...state.messages.map(
                        (message) => _MessageBubble(message: message),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Digite sua mensagem',
                              ),
                              onSubmitted: (_) => _send(state),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Enviar mensagem',
                            onPressed: () => _send(state),
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  state.sendMessage(
                    'Gostaria de abrir um chamado para receber atendimento.',
                  );
                  showAppSnackBar(
                    context,
                    'Chamado registrado. Acompanhe a resposta nesta conversa.',
                  );
                },
                icon: const Icon(Icons.confirmation_number_outlined),
                label: const Text('Fora do horário? Abrir um chamado'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _send(AppState state) {
    state.sendMessage(_messageController.text);
    _messageController.clear();
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});

  final _FaqData faq;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFFF8DFE1),
          foregroundColor: AppColors.red,
          child: Icon(Icons.question_mark, size: 17),
        ),
        title: Text(
          faq.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(faq.subtitle),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.answer,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqData {
  const _FaqData({
    required this.title,
    required this.subtitle,
    required this.answer,
  });

  final String title;
  final String subtitle;
  final String answer;
}

const _faqEntries = <_FaqData>[
  _FaqData(
    title: 'Entrega e frete',
    subtitle: 'Prazo, CEP e rastreio',
    answer: 'Informe o CEP na página do produto para ver o prazo. Depois da compra, abra Meus pedidos e toque em Acompanhar pedido para consultar cada etapa.',
  ),
  _FaqData(
    title: 'Pagamento',
    subtitle: 'Pix, cartão e boleto',
    answer: 'O Pix é aprovado imediatamente. O cartão pode ser parcelado em até 6 vezes e o boleto vence em dois dias úteis.',
  ),
  _FaqData(
    title: 'Trocas e garantia',
    subtitle: 'Prazos e condições',
    answer: 'Você pode solicitar troca em até 7 dias após o recebimento. A garantia varia por produto e aparece nas especificações do catálogo.',
  ),
];

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.fromUser
              ? const Color(0xFFF8DFE1)
              : const Color(0xFFF0ECE7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      children: [
        AppTopBar(
          title: 'Perfil',
          cartCount: state.cartCount,
          onCartTap: () => _openCart(context),
          onProfileTap: () => _openAccount(context, state),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFF8DFE1),
                        foregroundColor: AppColors.red,
                        child: Icon(Icons.person, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.loggedIn ? state.userName : 'Visitante',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              state.loggedIn
                                  ? state.userEmail
                                  : 'Entre para acessar pedidos e orçamentos',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!state.loggedIn) ...[
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Entrar ou criar conta'),
                ),
              ],
              const SizedBox(height: 20),
              _ProfileTile(
                icon: Icons.favorite_border,
                title: 'Favoritos',
                subtitle: '${state.favorites.length} produtos salvos',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
              _ProfileTile(
                icon: Icons.location_on_outlined,
                title: 'Endereços',
                subtitle: 'Gerencie seus locais de entrega',
                onTap: () =>
                    _openProtected(context, state, const AddressesScreen()),
              ),
              _ProfileTile(
                icon: Icons.notifications_none,
                title: 'Notificações',
                subtitle: 'Pedidos, ofertas e atendimento',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              _ProfileTile(
                icon: Icons.shield_outlined,
                title: 'Privacidade e segurança',
                subtitle: 'Senha, dados e consentimentos',
                onTap: () => _openProtected(
                  context,
                  state,
                  const AccountSecurityScreen(),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _openAdmin(context, state),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: Text(
                  state.isAdmin
                      ? 'Abrir painel administrativo'
                      : 'Acesso administrativo',
                ),
              ),
              if (state.loggedIn) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: state.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                ),
              ],
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'LeadSystem · versão acadêmica 1.1.0',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _openAccount(BuildContext context, AppState state) async {
    if (!state.loggedIn) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AccountSecurityScreen()));
  }

  static Future<void> _openProtected(
    BuildContext context,
    AppState state,
    Widget screen,
  ) async {
    if (!state.loggedIn) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!context.mounted || !state.loggedIn) return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  static Future<void> _openAdmin(BuildContext context, AppState state) async {
    if (!state.isAdmin) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
    if (!context.mounted) return;
    if (!state.isAdmin) {
      showAppSnackBar(
        context,
        'Entre com a conta administrativa para acessar este painel.',
      );
      return;
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.red),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
