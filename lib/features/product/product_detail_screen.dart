import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/iqd_currency.dart';
import '../../core/utils/navigation_utils.dart';
import '../../models/product_review.dart';
import '../../services/providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _tabIndex =
      0; // 0: Description, 1: How to Use, 2: Ingredients, 3: Reviews

  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');

  TextDirection _directionForText(String text) {
    return _arabicRegex.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final wishlist = ref.watch(wishlistProvider);
    final cartItems = ref.watch(cartProvider);

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
            final title = product.nameEn.trim().isNotEmpty
                ? product.nameEn.trim()
                : product.nameAr.trim();
            final description = product.descriptionAr.trim().isNotEmpty
                ? product.descriptionAr.trim()
                : product.descriptionEn.trim();
            final howToUse = (product.usage ?? '').trim();
            final ingredients = (product.ingredients ?? '').trim();

            return LayoutBuilder(
              builder: (context, constraints) {
                // Height reserved by the sticky bottom bar for internal paddings.
                const bottomBarHeight = 108.0;
                final heroHeight =
                    (constraints.maxHeight * 0.62).clamp(360.0, 560.0);

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
                                    AppColors.background
                                        .withValues(alpha: 0.92),
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
                        icon: isInWishlist
                            ? Icons.favorite
                            : Icons.favorite_border,
                        iconColor: isInWishlist
                            ? AppColors.white
                            : AppColors.textOffWhite,
                        onTap: () => ref
                            .read(wishlistProvider.notifier)
                            .toggleWishlist(product.id),
                      ),
                    ),

                    // C) Bottom rounded draggable sheet (title, price, description only)
                    DraggableScrollableSheet(
                      initialChildSize: 0.52,
                      minChildSize: 0.46,
                      maxChildSize: 0.92,
                      builder: (context, scrollController) {
                        final bottomInset =
                            MediaQuery.of(context).padding.bottom;
                        final Widget tabBody = switch (_tabIndex) {
                          0 => Text(
                              description,
                              textDirection: _directionForText(description),
                              textAlign: TextAlign.start,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.65,
                                fontSize: 16,
                              ),
                            ),
                          1 => Text(
                              howToUse.isNotEmpty ? howToUse : '—',
                              textDirection: _directionForText(howToUse),
                              textAlign: TextAlign.start,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.65,
                                fontSize: 16,
                              ),
                            ),
                          2 => Text(
                              ingredients.isNotEmpty ? ingredients : '—',
                              textDirection: _directionForText(ingredients),
                              textAlign: TextAlign.start,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.65,
                                fontSize: 16,
                              ),
                            ),
                          3 => _ReviewsTab(productId: product.id),
                          _ => const SizedBox.shrink(),
                        };

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(36)),
                          ),
                          child: ListView(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(
                                24, 12, 24, bottomBarHeight + bottomInset + 16),
                            children: [
                              Center(
                                child: Container(
                                  height: 4,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.iconTint
                                        .withValues(alpha: 0.45),
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
                                IqdCurrency.format(product.displayPrice),
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
                                  border: Border.all(
                                      color: AppColors.white
                                          .withValues(alpha: 0.06)),
                                ),
                                child: Row(
                                  children: [
                                    _SegmentTab(
                                      label: 'Description',
                                      selected: _tabIndex == 0,
                                      onTap: () =>
                                          setState(() => _tabIndex = 0),
                                    ),
                                    _SegmentTab(
                                      label: 'How to Use',
                                      selected: _tabIndex == 1,
                                      onTap: () =>
                                          setState(() => _tabIndex = 1),
                                    ),
                                    _SegmentTab(
                                      label: 'Ingredients',
                                      selected: _tabIndex == 2,
                                      onTap: () =>
                                          setState(() => _tabIndex = 2),
                                    ),
                                    _SegmentTab(
                                      label: 'Reviews',
                                      selected: _tabIndex == 3,
                                      onTap: () =>
                                          setState(() => _tabIndex = 3),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),
                              tabBody,
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
          loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load product', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(productDetailProvider(widget.productId)),
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
                final existing =
                    cartItems.where((i) => i.productId == product.id).toList();
                final currentQty =
                    existing.isNotEmpty ? existing.first.quantity : 0;

                if (currentQty == 0) {
                  ref.read(cartProvider.notifier).addToCart(product);
                }
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(product.id, currentQty + qty);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor:
                        AppColors.bottomNavBackground.withValues(alpha: 0.92),
                    behavior: SnackBarBehavior.floating,
                    elevation: 0,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.08)),
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
        child: Icon(Icons.image_not_supported,
            size: 64, color: AppColors.iconTint),
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
        child: Icon(Icons.image_not_supported,
            size: 64, color: AppColors.iconTint),
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
              color: Colors.black.withValues(alpha: 0.18),
              border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.14), width: 1.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: iconColor ?? AppColors.textOffWhite, size: 28),
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
            color: Colors.black.withValues(alpha: 0.35),
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
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
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

class _ReviewsTab extends ConsumerWidget {
  final int productId;
  const _ReviewsTab({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));
    final user = ref.watch(authProvider);

    return reviewsAsync.when(
      data: (reviews) {
        final total = reviews.length;
        final avg = total == 0
            ? 0.0
            : reviews.fold<int>(0, (sum, r) => sum + r.rating) / total;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReviewsSummaryCard(
              average: avg,
              count: total,
              isLoggedIn: user != null,
              onPrimaryAction: () {
                if (user == null) {
                  context.push('/login');
                  return;
                }
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AddReviewSheet(productId: productId),
                );
              },
            ),
            const SizedBox(height: 14),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No reviews yet. Be the first to review this product.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              )
            else
              ...reviews.map((r) => _ReviewTile(review: r)),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Failed to load reviews.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () => ref
                    .read(productReviewsProvider(productId).notifier)
                    .refresh(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textOffWhite,
                  side: BorderSide(color: AppColors.white.withAlpha(20)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSummaryCard extends StatelessWidget {
  final double average;
  final int count;
  final bool isLoggedIn;
  final VoidCallback onPrimaryAction;

  const _ReviewsSummaryCard({
    required this.average,
    required this.count,
    required this.isLoggedIn,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withAlpha(18)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textOffWhite,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              _StarRow(rating: average),
              const SizedBox(height: 6),
              Text(
                '$count review${count == 1 ? '' : 's'}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
              child: Text(
                isLoggedIn ? 'Write a review' : 'Login to review',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ProductReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('MMM d, yyyy').format(review.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withAlpha(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textOffWhite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                dateText,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StarRow(rating: review.rating.toDouble(), size: 16),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor().clamp(0, 5);
    final frac = rating - full;
    final hasHalf = frac >= 0.5 && full < 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icon = i < full
            ? Icons.star
            : (i == full && hasHalf ? Icons.star_half : Icons.star_border);
        return Icon(
          icon,
          size: size,
          color: AppColors.accentGold,
        );
      }),
    );
  }
}

class _AddReviewSheet extends ConsumerStatefulWidget {
  final int productId;
  const _AddReviewSheet({required this.productId});

  @override
  ConsumerState<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends ConsumerState<_AddReviewSheet> {
  int _rating = 5;
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final user = ref.read(authProvider);
      if (user == null) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) context.push('/login');
        return;
      }

      await ref
          .read(productReviewsProvider(widget.productId).notifier)
          .addReview(
            rating: _rating,
            comment: _controller.text,
            userName: user.fullName,
            userId: user.id,
          );
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.bottomNavBackground,
            content: Text(
              'Review submitted',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textOffWhite),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.iconTint.withAlpha(120),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Write a review',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textOffWhite,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                final idx = i + 1;
                final filled = idx <= _rating;
                return IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _rating = idx),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? AppColors.accentGold : AppColors.iconTint,
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Share your experience…',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.iconTint.withAlpha(210),
                ),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.white.withAlpha(18)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.white.withAlpha(18)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
