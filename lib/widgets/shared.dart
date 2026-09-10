import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/product.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 30 : 38,
          height: compact ? 30 : 38,
          decoration: BoxDecoration(
            color: light
                ? Colors.white.withValues(alpha: .14)
                : const Color(0xFFF8DFE1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            color: light ? Colors.white : AppColors.red,
            size: compact ? 20 : 26,
          ),
        ),
        const SizedBox(width: 9),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SantiGrill',
              style: TextStyle(
                color: color,
                fontSize: compact ? 17 : 21,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -.3,
              ),
            ),
            Text(
              'LEADSYSTEM',
              style: TextStyle(
                color: light ? Colors.white70 : AppColors.muted,
                fontSize: 8,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.cartCount,
    required this.onCartTap,
    this.title,
  });

  final int cartCount;
  final VoidCallback onCartTap;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
      child: Row(
        children: [
          if (title == null)
            const BrandLogo(compact: true)
          else
            Expanded(
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (title == null) const Spacer(),
          IconButton(
            tooltip: 'Minha conta',
            onPressed: () {},
            icon: const Icon(Icons.person_outline_rounded),
          ),
          Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: IconButton(
              tooltip: 'Carrinho',
              onPressed: onCartTap,
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.quadrant,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final int quadrant;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final column = quadrant % 2;
          final row = quadrant ~/ 2;
          return Stack(
            clipBehavior: Clip.hardEdge,
            fit: StackFit.expand,
            children: [
              Positioned(
                left: -column * width,
                top: -row * height,
                width: width * 2,
                height: height * 2,
                child: Image.asset(
                  'assets/images/produtos_santigrill.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  semanticLabel: 'Imagem do produto SantiGrill',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.favorite,
    required this.onTap,
    required this.onAdd,
    required this.onFavorite,
  });

  final Product product;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    quadrant: product.imageQuadrant,
                    borderRadius: BorderRadius.zero,
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Material(
                      color: Colors.white.withValues(alpha: .92),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: favorite
                            ? 'Remover dos favoritos'
                            : 'Favoritar',
                        onPressed: onFavorite,
                        iconSize: 19,
                        icon: Icon(
                          favorite ? Icons.favorite : Icons.favorite_border,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.success,
                        size: 15,
                      ),
                      Text(
                        ' ${product.rating.toStringAsFixed(1).replaceAll('.', ',')} · Em estoque',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          money(product.price),
                          style: const TextStyle(
                            color: AppColors.darkRed,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Adicionar ao carrinho',
                        visualDensity: VisualDensity.compact,
                        onPressed: onAdd,
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
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

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color = AppColors.success,
    this.background = AppColors.successSoft,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF8DFE1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.red, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
}
