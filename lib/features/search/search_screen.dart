import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/shine_strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/iqd_currency.dart';
import '../../models/product.dart';
import '../../services/providers.dart';

/// Search screen (redesign to match screenshot).
///
/// UI only + light local filtering logic.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  final List<String> _recent = [];
  static const List<String> _fallbackBrands = ['Olay', 'Estée', 'Lume', 'Chanel', 'Dior', 'Clinique'];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final next = _controller.text;
      if (next != _query) {
        setState(() => _query = next);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: q.length));
    setState(() => _query = q);
  }

  void _submit() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    if (!_recent.contains(q)) {
      setState(() => _recent.insert(0, q));
    }
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(bestSellersProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final topBrands = brandsAsync.when(
      data: (brands) => brands.map((b) => b.name).toList(),
      loading: () => _fallbackBrands,
      error: (_, __) => _fallbackBrands,
    );

    return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Subtle warm top gradient.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.appBarBackground.withOpacity(0.70),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopSearchRow(
                      controller: _controller,
                      onTapBack: () => context.safeGoBack(),
                      onTapArrow: _submit,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 22),

                    // Recent searches
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('search_recent_searches'),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textOffWhite,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _recent.clear()),
                          child: Text(
                            context.tr('search_clear_all'),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final r in _recent)
                          _PillChip(
                            text: r,
                            icon: Icons.history,
                            onTap: () {
                              _applyQuery(r);
                              _submit();
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        context.tr('search_top_brands'),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textOffWhite,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final b in topBrands)
                            _PillChip(
                              text: b,
                              icon: null,
                              onTap: () {
                                _applyQuery(b);
                                _submit();
                              },
                              buttonLike: true,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        context.tr('search_recommended_for_you'),
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.textOffWhite,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    productsAsync.when(
                      data: (list) {
                        final base = list.isNotEmpty ? list : _fallbackProducts();
                        final q = _query.trim().toLowerCase();
                        final filtered = q.isEmpty
                            ? base
                            : base
                                .where((p) =>
                                    p.nameEn.toLowerCase().contains(q) ||
                                    p.nameAr.toLowerCase().contains(q) ||
                                    (p.categoryName ?? '').toLowerCase().contains(q) ||
                                    (p.brandName ?? '').toLowerCase().contains(q))
                                .toList();

                        return Column(
                          children: [
                            for (final p in filtered)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _RecommendedCard(
                                  product: p,
                                  onTap: () => context.push('/product/${p.id}'),
                                  onTapAdd: () {
                                    ref.read(cartProvider.notifier).addToCart(p);
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
                                              child: Text(context.tr('cart_view')),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                context.tr('cart_added_to_bag'),
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
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  List<Product> _fallbackProducts() {
    return <Product>[
      Product(
        id: 1,
        nameAr: 'Radiance Serum',
        nameEn: 'Radiance Serum',
        brandId: 1,
        categoryId: 'serums',
        descriptionAr: '',
        descriptionEn: '',
        price: 85,
        salePrice: 85,
        imageUrl: null,
      ),
      Product(
        id: 2,
        nameAr: 'Hydra Night Cream',
        nameEn: 'Hydra Night Cream',
        brandId: 1,
        categoryId: 'moisturizers',
        descriptionAr: '',
        descriptionEn: '',
        price: 62,
        salePrice: 62,
        imageUrl: null,
      ),
      Product(
        id: 3,
        nameAr: 'Rose Gold Oil',
        nameEn: 'Rose Gold Oil',
        brandId: 1,
        categoryId: 'oils',
        descriptionAr: '',
        descriptionEn: '',
        price: 110,
        salePrice: 110,
        imageUrl: null,
      ),
      Product(
        id: 4,
        nameAr: 'Detox Clay Mask',
        nameEn: 'Detox Clay Mask',
        brandId: 1,
        categoryId: 'masks',
        descriptionAr: '',
        descriptionEn: '',
        price: 45,
        salePrice: 45,
        imageUrl: null,
      ),
    ];
  }
}

class _TopSearchRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTapBack;
  final VoidCallback onTapArrow;
  final ValueChanged<String> onSubmitted;

  const _TopSearchRow({
    required this.controller,
    required this.onTapBack,
    required this.onTapArrow,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back,
          onTap: onTapBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bottomNavBackground.withOpacity(0.35),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary.withOpacity(0.55), width: 1.6),
            ),
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textOffWhite,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.textOffWhite,
              decoration: InputDecoration(
                hintText: context.tr('search_hint'),
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.iconTint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                suffixIcon: IconButton(
                  onPressed: onTapArrow,
                  icon: const Icon(Icons.search, color: AppColors.primary, size: 24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              border: Border.all(color: AppColors.white.withOpacity(0.10)),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final bool buttonLike;

  const _PillChip({
    required this.text,
    required this.icon,
    required this.onTap,
    this.buttonLike = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: buttonLike ? 18 : 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground.withOpacity(buttonLike ? 0.42 : 0.32),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textOffWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 10),
              Icon(icon, size: 18, color: AppColors.iconTint),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecommendedCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onTapAdd;

  const _RecommendedCard({
    required this.product,
    required this.onTap,
    required this.onTapAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartItems = ref.watch(cartProvider);
    final qtyInCart = cartItems
        .where((i) => i.productId == product.id)
        .map((i) => i.quantity)
        .fold<int>(0, (prev, q) => q > prev ? q : prev);

    final title = product.nameEn.trim().isNotEmpty ? product.nameEn.trim() : product.nameAr.trim();
    final subtitle = (product.categoryName ?? product.brandName ?? '').trim().isNotEmpty
        ? (product.categoryName ?? product.brandName ?? '').trim()
        : 'Brightening Vitamin C Complex';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground.withOpacity(0.40),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            if (qtyInCart <= 0)
              _CircleAddButton(onTap: onTapAdd)
            else
              _MiniQtyStepper(
                quantity: qtyInCart,
                onDecrement: () => cartNotifier.updateQuantity(product.id, qtyInCart - 1),
                onIncrement: onTapAdd,
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textOffWhite,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        IqdCurrency.format(product.displayPrice),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      _StarRow(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _ProductThumb(imageUrl: (product.imageUrl ?? '').trim()),
          ],
        ),
      ),
    );
  }
}

class _CircleAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.appBarBackground.withOpacity(0.55),
          border: Border.all(color: AppColors.white.withOpacity(0.06)),
        ),
        child: const Icon(Icons.add, color: AppColors.white, size: 24),
      ),
    );
  }
}

class _MiniQtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _MiniQtyStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 98,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          _StepIconButton(icon: Icons.remove, onTap: onDecrement),
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: AppTextStyles.bodyLarge.copyWith(
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
  final VoidCallback onTap;

  const _StepIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 20, color: AppColors.white),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String imageUrl;
  const _ProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 92,
        height: 92,
        child: imageUrl.isEmpty
            ? Container(color: AppColors.brandCircleBackground)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.brandCircleBackground),
                errorWidget: (_, __, ___) => Container(color: AppColors.brandCircleBackground),
              ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.accentGold.withOpacity(0.75);
    return Row(
      children: const [
        Icon(Icons.star, size: 14, color: Color(0xFFC6A87C)),
        Icon(Icons.star, size: 14, color: Color(0xFFC6A87C)),
        Icon(Icons.star, size: 14, color: Color(0xFFC6A87C)),
        Icon(Icons.star, size: 14, color: Color(0xFFC6A87C)),
        Icon(Icons.star_half, size: 14, color: Color(0xFFC6A87C)),
      ],
    );
  }
}
