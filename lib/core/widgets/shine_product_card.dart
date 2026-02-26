import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../utils/iqd_currency.dart';
import '../../models/product.dart';
import '../../services/providers.dart';

/// Product card matching the new Shine grid/list design.
class ShineProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;
  final bool compact;

  const ShineProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final isInWishlist = wishlist.contains(product.id);
    final imageUrl = (product.imageUrl ?? '').trim();
    final isOutOfStock = product.stock <= 0;

    if (compact) {
      return _buildCompact(context, ref, isInWishlist, imageUrl, isOutOfStock);
    }

    return _buildGrid(context, ref, isInWishlist, imageUrl, isOutOfStock);
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    bool isInWishlist,
    String imageUrl,
    bool isOutOfStock,
  ) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartItems = ref.watch(cartProvider);
    final qtyInCart = cartItems
        .where((i) => i.productId == product.id)
        .map((i) => i.quantity)
        .fold<int>(0, (prev, q) => q > prev ? q : prev);

    final category = _categoryLabel(product);
    final title = product.nameEn.trim().isNotEmpty ? product.nameEn.trim() : product.nameAr.trim();
    final subtitle = _subtitle(product);
    final priceText = IqdCurrency.format(product.displayPrice);

    return GestureDetector(
      onTap: isOutOfStock ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground.withOpacity(0.48),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              // Target design: bigger image section, smaller bottom panel.
              // Keep the bottom compact, but guarantee enough room to avoid overflow
              // for 1 category line + 2 title lines + 1 subtitle line + row.
              final bottomH = (h * 0.36).clamp(132.0, 146.0);
              final imageH = (h - bottomH).clamp(0.0, h);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image section (fixed height to prevent overflow)
                  SizedBox(
                    height: imageH,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _imagePlaceholder(),
                                  errorWidget: (_, __, ___) => _imagePlaceholder(),
                                )
                              : _imagePlaceholder(),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.bottomNavBackground.withOpacity(0.55),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: GestureDetector(
                            onTap: () => ref.read(wishlistProvider.notifier).toggleWishlist(product.id),
                            child: Container(
                              height: 34,
                              width: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.22),
                                border: Border.all(color: AppColors.white.withOpacity(0.10)),
                              ),
                              child: Icon(
                                isInWishlist ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isInWishlist ? AppColors.primary : AppColors.white.withOpacity(0.90),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom section (fixed height + constrained text)
                  SizedBox(
                    height: bottomH,
                    child: ColoredBox(
                      color: AppColors.cardBottomPanel,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 1.1,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.textOffWhite,
                                fontWeight: FontWeight.w900,
                                height: 1.04,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.iconTint,
                                fontSize: 13,
                                height: 1.0,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                if (qtyInCart <= 0)
                                  GestureDetector(
                                    onTap: isOutOfStock ? null : () => cartNotifier.addToCart(product),
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.22),
                                        border: Border.all(color: AppColors.white.withOpacity(0.08)),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: isOutOfStock ? AppColors.iconTint : AppColors.white,
                                        size: 17,
                                      ),
                                    ),
                                  )
                                else
                                  _MiniQtyStepper(
                                    quantity: qtyInCart,
                                    onDecrement: () => cartNotifier.updateQuantity(product.id, qtyInCart - 1),
                                    onIncrement: isOutOfStock ? null : () => cartNotifier.addToCart(product),
                                  ),
                                const Spacer(),
                                Text(
                                  priceText,
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    WidgetRef ref,
    bool isInWishlist,
    String imageUrl,
    bool isOutOfStock,
  ) {
    return GestureDetector(
      onTap: isOutOfStock ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 72,
                width: 72,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _imagePlaceholder(),
                        errorWidget: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nameAr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    IqdCurrency.format(product.displayPrice),
                    style: AppTextStyles.price,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(wishlistProvider.notifier).toggleWishlist(product.id);
              },
              icon: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: isInWishlist ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.brandCircleBackground,
      child: const Center(
        child: Icon(
          Icons.image,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  String _categoryLabel(Product p) {
    final id = p.categoryId.trim().toLowerCase();
    switch (id) {
      case 'moisturizers':
        return 'MOISTURIZERS';
      case 'serums':
        return 'SERUMS';
      case 'masks':
        return 'MASKS';
      case 'oils':
        return 'OILS';
      case 'toners':
        return 'TONERS';
      case 'sets':
        return 'SETS';
      default:
        final name = (p.categoryName ?? '').trim();
        return name.isNotEmpty ? name.toUpperCase() : id.toUpperCase();
    }
  }

  String _subtitle(Product p) {
    final ing = (p.ingredients ?? '').trim();
    if (ing.isNotEmpty) {
      final first = ing.split(',').first.trim();
      if (first.isNotEmpty) return first;
      return ing;
    }
    final usage = (p.usage ?? '').trim();
    if (usage.isNotEmpty) {
      final first = usage.split('.').first.trim();
      return first.isNotEmpty ? first : usage;
    }
    final brand = (p.brandName ?? '').trim();
    if (brand.isNotEmpty) return brand;
    return '—';
  }
}

class _MiniQtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback? onIncrement;

  const _MiniQtyStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 92,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _StepIconButton(icon: Icons.remove, onTap: onDecrement),
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _StepIconButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? AppColors.iconTint : AppColors.white,
        ),
      ),
    );
  }
}

