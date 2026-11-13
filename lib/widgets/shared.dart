import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/product.dart';

/// Logo oficial da SantiGrill (assets/images/brand/logo.png, fundo vermelho).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false});

  final bool compact;

  static const asset = 'assets/images/brand/logo.png';

  @override
  Widget build(BuildContext context) {
    final height = compact ? 34.0 : 46.0;
    return Semantics(
      label: 'SantiGrill - Churrasqueiras Práticas',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        child: Image.asset(
          asset,
          height: height,
          cacheHeight: (height * 3).round(),
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.cartCount,
    required this.onCartTap,
    required this.onProfileTap,
    this.title,
  });

  final int cartCount;
  final VoidCallback onCartTap;
  final VoidCallback onProfileTap;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
      child: Row(
        children: [
          if (title == null)
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandLogo(compact: true),
              ),
            )
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
          IconButton(
            tooltip: 'Minha conta',
            onPressed: onProfileTap,
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

/// Imagem de produto a partir de um asset, decodificada no tamanho exibido
/// (economiza memória e deixa a rolagem fluida), com placeholder e
/// tratamento de erro.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.path,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.fit = BoxFit.cover,
  });

  final String? path;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.neutralSoft,
      child: Center(
        child: Icon(
          Icons.outdoor_grill_outlined,
          color: AppColors.muted.withValues(alpha: .5),
          size: 32,
        ),
      ),
    );
    final source = path;
    return ClipRRect(
      borderRadius: borderRadius,
      child: source == null || source.isEmpty
          ? placeholder
          : LayoutBuilder(
              builder: (context, constraints) {
                final ratio = MediaQuery.devicePixelRatioOf(context);
                final width = constraints.maxWidth.isFinite
                    ? (constraints.maxWidth * ratio).round()
                    : null;
                final provider = imageProviderFor(source, cacheWidth: width);
                return ColoredBox(
                  color: Colors.white,
                  child: Image(
                    image: provider,
                    fit: fit,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                    semanticLabel: 'Foto do produto',
                    frameBuilder: (context, child, frame, synchronous) {
                      if (synchronous) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : placeholder,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
                );
              },
            ),
    );
  }
}

/// Resolve a origem da foto: asset do app, foto enviada ao servidor (URL)
/// ou foto salva no aparelho pelo painel (arquivo).
ImageProvider imageProviderFor(String source, {int? cacheWidth}) {
  final ImageProvider provider;
  if (source.startsWith('http://') || source.startsWith('https://')) {
    provider = NetworkImage(source);
  } else if (source.startsWith('assets/')) {
    provider = AssetImage(source);
  } else {
    provider = FileImage(File(source));
  }
  return ResizeImage.resizeIfNeeded(cacheWidth, null, provider);
}

/// Bloco de preço com valor no Pix e parcelamento, como no site.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.product, this.large = false});

  final Product product;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final hasPromo = product.salePrice < product.price;
    final pix = product.pixPrice;
    final installments = product.installments;
    final installmentValue = product.installmentValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPromo)
          Text(
            money(product.price),
            style: TextStyle(
              color: AppColors.muted,
              decoration: TextDecoration.lineThrough,
              fontSize: large ? 14 : 11,
            ),
          ),
        Text(
          money(product.salePrice),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.darkRed,
            fontWeight: FontWeight.w800,
            fontSize: large ? 28 : 16,
            height: 1.15,
          ),
        ),
        if (pix != null && !hasPromo)
          Text(
            '${money(pix)} no Pix',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: large ? 15 : 11,
            ),
          ),
        if (large && installments != null && installmentValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'ou ${installments}x de ${money(installmentValue)} no cartão',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
      ],
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
    this.heroScope = 'list',
  });

  final Product product;
  final bool favorite;

  /// Diferencia o Hero quando o mesmo produto aparece em listas diferentes.
  final String heroScope;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final inStock = product.inStock;
    final availabilityColor = inStock ? AppColors.success : AppColors.muted;
    final availabilityLabel = inStock ? 'Em estoque' : 'Esgotado';
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
                  Hero(
                    tag: 'product-${product.id}-$heroScope',
                    child: ProductImage(
                      path: product.coverImage,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Material(
                      color: Colors.white.withValues(alpha: .92),
                      shape: const CircleBorder(),
                      child: IconButton(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    availabilityLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: availabilityColor, fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(child: PriceTag(product: product)),
                      IconButton.filled(
                        tooltip: inStock
                            ? 'Adicionar ao carrinho'
                            : 'Produto esgotado',
                        onPressed: inStock ? onAdd : null,
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
    this.color,
    this.background,
  });

  final String label;

  /// Padrão: verde de sucesso da paleta ativa.
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.success;
    final background = this.background ?? AppColors.successSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
              decoration: BoxDecoration(
                color: AppColors.redSoft,
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
              style: TextStyle(color: AppColors.muted, height: 1.4),
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
