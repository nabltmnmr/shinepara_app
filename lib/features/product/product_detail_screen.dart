import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _tabIndex = 0; // 0: Description, 1: How to Use, 2: Ingredients

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final wishlist = ref.watch(wishlistProvider);
    final cartItems = ref.watch(cartProvider);
    final priceFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: productAsync.when(
          data: (product) {
            if (product == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Product not found', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.safeGoBack(),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              );
            }

            final isInWishlist = wishlist.contains(product.id);
            final imageUrl = (product.imageUrl ?? '').trim();
            final title = product.nameEn.trim().isNotEmpty ? product.nameEn.trim() : product.nameAr.trim();
            final description = product.descriptionEn.trim().isNotEmpty
                ? product.descriptionEn.trim()
                : product.descriptionAr.trim();
            final howToUse = (product.usage ?? '').trim();
            final ingredients = (product.ingredients ?? '').trim();

            return LayoutBuilder(
              builder: (context, constraints) {
                // Height reserved by the sticky bottom bar for internal paddings.
                const bottomBarHeight = 108.0;
                final heroHeight = (constraints.maxHeight * 0.62).clamp(360.0, 560.0);

                return Stack(
                  children: [
                    // A) Hero image (full-bleed) + bottom gradient
                    SizedBox(
                      height: heroHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _HeroImage(imageUrl: imageUrl),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.background.withOpacity(0.92),
                                  ],
                                  stops: const [0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // B) Overlay top buttons (back left, heart right)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 16,
                      child: _OverlayCircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.safeGoBack(),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      right: 16,
                      child: _OverlayCircleIconButton(
                        icon: isInWishlist ? Icons.favorite : Icons.favorite_border,
                        iconColor: isInWishlist ? AppColors.white : AppColors.textOffWhite,
                        onTap: () => ref.read(wishlistProvider.notifier).toggleWishlist(product.id),
                      ),
                    ),

                    // C) Bottom rounded draggable sheet (title, price, description only)
                    DraggableScrollableSheet(
                      initialChildSize: 0.52,
                      minChildSize: 0.46,
                      maxChildSize: 0.92,
                      builder: (context, scrollController) {
                        final bottomInset = MediaQuery.of(context).padding.bottom;
                        final selectedContent = switch (_tabIndex) {
                          0 => description,
                          1 => howToUse.isNotEmpty ? howToUse : '—',
                          2 => ingredients.isNotEmpty ? ingredients : '—',
                          _ => description,
                        };

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                          ),
                          child: ListView(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(24, 12, 24, bottomBarHeight + bottomInset + 16),
                            children: [
                              Center(
                                child: Container(
                                  height: 4,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.iconTint.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                title,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: AppColors.textOffWhite,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 34,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                priceFormatter.format(product.displayPrice),
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Segmented tabs (Description / How to Use / Ingredients)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.productDetailsTabsBg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.white.withOpacity(0.06)),
                                ),
                                child: Row(
                                  children: [
                                    _SegmentTab(
                                      label: 'Description',
                                      selected: _tabIndex == 0,
                                      onTap: () => setState(() => _tabIndex = 0),
                                    ),
                                    _SegmentTab(
                                      label: 'How to Use',
                                      selected: _tabIndex == 1,
                                      onTap: () => setState(() => _tabIndex = 1),
                                    ),
                                    _SegmentTab(
                                      label: 'Ingredients',
                                      selected: _tabIndex == 2,
                                      onTap: () => setState(() => _tabIndex = 2),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),
                              Text(
                                selectedContent,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.65,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
          loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load product', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(productDetailProvider(widget.productId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: productAsync.when(
          data: (product) {
            if (product == null) return const SizedBox.shrink();
            return _BottomActionBar(
              productId: product.id,
              onAddToBag: (qty) {
                final existing = cartItems.where((i) => i.productId == product.id).toList();
                final currentQty = existing.isNotEmpty ? existing.first.quantity : 0;

                if (currentQty == 0) {
                  ref.read(cartProvider.notifier).addToCart(product);
                }
                ref.read(cartProvider.notifier).updateQuantity(product.id, currentQty + qty);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.bottomNavBackground.withOpacity(0.92),
                    behavior: SnackBarBehavior.floating,
                    elevation: 0,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.white.withOpacity(0.08)),
                    ),
                    content: Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            context.push('/cart');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          child: const Text('View'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Added $qty to bag',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textOffWhite,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLarge.copyWith(
                color: selected ? AppColors.white : AppColors.iconTint,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  const _HeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: AppColors.bottomNavBackground,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported, size: 64, color: AppColors.iconTint),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: AppColors.bottomNavBackground,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.primary),
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.bottomNavBackground,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported, size: 64, color: AppColors.iconTint),
      ),
    );
  }
}

class _OverlayCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _OverlayCircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              border: Border.all(color: AppColors.white.withOpacity(0.14), width: 1.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? AppColors.textOffWhite, size: 28),
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatefulWidget {
  final int productId;
  final ValueChanged<int> onAddToBag;

  const _BottomActionBar({
    super.key,
    required this.productId,
    required this.onAddToBag,
  });

  @override
  State<_BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends State<_BottomActionBar> {
  int _qty = 1;

  void _setQty(int v) {
    final next = v.clamp(1, 99);
    setState(() => _qty = next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.bottomNavBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _QtyStepper(
              value: _qty,
              onMinus: () => _setQty(_qty - 1),
              onPlus: () => _setQty(_qty + 1),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => widget.onAddToBag(_qty),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Add to Bag',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtyStepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 150,
      decoration: BoxDecoration(
        color: AppColors.appBarBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          _StepperIconButton(icon: Icons.remove, onTap: onMinus),
          Expanded(
            child: Center(
              child: Text(
                '$value',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textOffWhite,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          _StepperIconButton(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Center(
          child: Icon(icon, color: AppColors.iconTint, size: 22),
        ),
      ),
    );
  }
}
