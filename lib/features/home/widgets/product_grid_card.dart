import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/product.dart';
import '../../../services/providers.dart';
import '../../../core/utils/iqd_currency.dart';

class ProductGridCard extends ConsumerWidget {
  final List<Product> products;
  final ValueChanged<Product> onTapProduct;
  final VoidCallback? onTapAdd;
  final VoidCallback? onTapFavorite;

  const ProductGridCard({
    super.key,
    required this.products,
    required this.onTapProduct,
    this.onTapAdd,
    this.onTapFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = products.take(6).toList();
    final cartItems = ref.watch(cartProvider);
    final qtyById = <int, int>{};
    for (final item in cartItems) {
      qtyById[item.productId] = (qtyById[item.productId] ?? 0) + item.quantity;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.56, // bigger/taller cards (match reference)
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        final wishlist = ref.watch(wishlistProvider);
        final isInWishlist = wishlist.contains(p.id);
        final qtyInCart = qtyById[p.id] ?? 0;
        return _ProductCard(
          product: p,
          onTap: () => onTapProduct(p),
          onTapAdd: () {
            // If a parent provided a handler, keep it; otherwise add to cart.
            if (onTapAdd != null) {
              onTapAdd!.call();
              return;
            }
            final cart = ref.read(cartProvider.notifier);
            if (qtyInCart <= 0) {
              cart.addToCart(p);
            } else {
              cart.incrementQuantity(p.id);
            }
          },
          onTapRemove: () {
            ref.read(cartProvider.notifier).decrementQuantity(p.id);
          },
          onTapFavorite: () {
            if (onTapFavorite != null) {
              onTapFavorite!.call();
              return;
            }
            ref.read(wishlistProvider.notifier).toggleWishlist(p.id);
          },
          isInWishlist: isInWishlist,
          qtyInCart: qtyInCart,
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onTapAdd;
  final VoidCallback? onTapRemove;
  final VoidCallback? onTapFavorite;
  final bool isInWishlist;
  final int qtyInCart;

  const _ProductCard({
    required this.product,
    required this.onTap,
    this.onTapAdd,
    this.onTapRemove,
    this.onTapFavorite,
    required this.isInWishlist,
    required this.qtyInCart,
  });

  @override
  Widget build(BuildContext context) {
    final title = product.nameEn.isNotEmpty ? product.nameEn : product.nameAr;
    final subtitle = (product.ingredients ?? '').trim().isNotEmpty
        ? (product.ingredients ?? '').trim().split(',').first.trim()
        : ((product.brandName ?? '').isNotEmpty
            ? (product.brandName ?? '')
            : (product.categoryName ?? ''));
    final category = _categoryLabel(product);

    return GestureDetector(
      onTap: onTap,
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
                  SizedBox(
                    height: imageH,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _image()),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.bottomNavBackground
                                      .withOpacity(0.55),
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
                            behavior: HitTestBehavior.opaque,
                            onTap: onTapFavorite,
                            child: Container(
                              height: 34,
                              width: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.22),
                                border: Border.all(
                                    color: AppColors.white.withOpacity(0.10)),
                              ),
                              child: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isInWishlist
                                    ? AppColors.primary
                                    : AppColors.white.withOpacity(0.90),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                              subtitle.isNotEmpty ? subtitle : '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.iconTint,
                                fontSize: 13,
                                height: 1.0,
                              ),
                            ),
                            const Spacer(),
                            LayoutBuilder(
                              builder: (context, rowConstraints) {
                                final isTight = rowConstraints.maxWidth < 170;
                                final addButtonSize = isTight ? 34.0 : 40.0;
                                return Row(
                                  children: [
                                    if (qtyInCart <= 0)
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: onTapAdd,
                                        child: Container(
                                          height: addButtonSize,
                                          width: addButtonSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.black.withOpacity(0.22),
                                            border: Border.all(
                                                color: AppColors.white
                                                    .withOpacity(0.08)),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: AppColors.white,
                                            size: isTight ? 18 : 20,
                                          ),
                                        ),
                                      )
                                    else
                                      _MiniQtyStepper(
                                        compact: isTight,
                                        quantity: qtyInCart,
                                        onDecrement: onTapRemove,
                                        onIncrement: onTapAdd,
                                      ),
                                    SizedBox(width: isTight ? 6 : 10),
                                    Expanded(
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            IqdCurrency.format(
                                                product.displayPrice),
                                            maxLines: 1,
                                            style: AppTextStyles.titleLarge
                                                .copyWith(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: isTight ? 15 : 17,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
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

  Widget _image() {
    final url = product.imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return Container(
        color: AppColors.brandCircleBackground,
        child: const Center(
          child: Icon(Icons.image, color: AppColors.textMuted),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: AppColors.brandCircleBackground,
        child:
            const Center(child: Icon(Icons.image, color: AppColors.textMuted)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.brandCircleBackground,
        child:
            const Center(child: Icon(Icons.image, color: AppColors.textMuted)),
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
}

class _MiniQtyStepper extends StatelessWidget {
  final bool compact;
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _MiniQtyStepper({
    this.compact = false,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 36.0 : 40.0;
    final width = compact ? 92.0 : 116.0;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          _StepIconButton(
              compact: compact, icon: Icons.remove, onTap: onDecrement),
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 13 : null,
                ),
              ),
            ),
          ),
          _StepIconButton(
              compact: compact, icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepIconButton extends StatelessWidget {
  final bool compact;
  final IconData icon;
  final VoidCallback? onTap;

  const _StepIconButton({
    this.compact = false,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 40.0;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Icon(
            icon,
            size: compact ? 16 : 19,
            color: onTap == null ? AppColors.iconTint : AppColors.white,
          ),
        ),
      ),
    );
  }
}
