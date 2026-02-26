import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/localization/shine_strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/iqd_currency.dart';
import '../../core/utils/navigation_utils.dart';
import '../../models/cart_item.dart';
import '../../services/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final subtotal = cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final shippingAsync = ref.watch(shippingSettingsProvider);
    final shipping = cartItems.isEmpty
        ? 0.0
        : shippingAsync.when(
            data: (settings) => settings.calculateShipping(subtotal),
            loading: () => 0.0,
            error: (_, __) => 0.0,
          );
    final total = subtotal + shipping;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.appBarBackground,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 10),
                  // Header (centered title + subtitle)
                  Column(
                    children: [
                      Text(
                        context.tr('cart_title'),
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.trf('cart_items_count', {'count': '${cartItems.length}'}),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.iconTint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.iconTint),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr('cart_empty_title'),
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.textOffWhite,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr('cart_empty_subtitle'),
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () => context.go('/'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                    child: Text(context.tr('cart_shop_now'), style: AppTextStyles.buttonText),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                            children: [
                              for (final item in cartItems)
                                _CartItemCard(
                                  item: item,
                                  onRemove: () => cartNotifier.removeFromCart(item.productId),
                                  onMinus: () => cartNotifier.updateQuantity(item.productId, item.quantity - 1),
                                  onPlus: () => cartNotifier.updateQuantity(item.productId, item.quantity + 1),
                                ),
                              const SizedBox(height: 10),
                              _PromoCodeRow(
                                onApply: () {},
                              ),
                              const SizedBox(height: 18),
                              _TotalsCard(
                                subtotal: subtotal,
                                shipping: shipping,
                                total: total,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              // ICON RULE: only back icon on top-left
              Positioned(
                top: 8,
                left: 16,
                child: _OverlayCircleIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => context.safeGoBack(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : _ConfirmOrderBar(
              onTap: () => context.push('/checkout'),
            ),
    );
  }
}

class _OverlayCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayCircleIconButton({
    required this.icon,
    required this.onTap,
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
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item.product.imageUrl ?? '').toString().trim();
    final name = item.product.nameEn.trim().isNotEmpty ? item.product.nameEn : item.product.nameAr;
    final subtitle = (item.product.categoryName ?? item.product.brandName ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: BoxDecoration(
              color: AppColors.bottomNavBackground.withOpacity(0.55),
              borderRadius: BorderRadius.circular(26),
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle.isNotEmpty ? subtitle : '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.iconTint,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _QtyStepper(
                          value: item.quantity as int,
                          onMinus: onMinus,
                          onPlus: onPlus,
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  IqdCurrency.format(item.product.displayPrice),
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(width: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 104,
                    height: 104,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.brandCircleBackground,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.brandCircleBackground,
                              alignment: Alignment.center,
                              child: Icon(Icons.image_not_supported, color: AppColors.iconTint),
                            ),
                          )
                        : Container(
                            color: AppColors.brandCircleBackground,
                            alignment: Alignment.center,
                            child: Icon(Icons.image_not_supported, color: AppColors.iconTint),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _SmallCircleIcon(
              icon: Icons.close,
              onTap: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallCircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallCircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              border: Border.all(color: AppColors.white.withOpacity(0.10)),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
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
      height: 48,
      width: 150,
      decoration: BoxDecoration(
        color: AppColors.appBarBackground.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          _StepperIconButton(icon: Icons.remove, onTap: onMinus, color: AppColors.iconTint),
          Expanded(
            child: Center(
              child: Text(
                '$value',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          _StepperIconButton(icon: Icons.add, onTap: onPlus, color: AppColors.primaryLight),
        ],
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _StepperIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 48,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Center(
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _PromoCodeRow extends StatelessWidget {
  final VoidCallback onApply;

  const _PromoCodeRow({required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bottomNavBackground.withOpacity(0.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, color: AppColors.iconTint, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOffWhite),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: context.tr('cart_promo_hint'),
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.iconTint),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 62,
          width: 110,
          child: ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.appBarBackground.withOpacity(0.65),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              side: BorderSide(color: AppColors.white.withOpacity(0.06)),
            ),
            child: Text(
              context.tr('cart_promo_apply'),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final double subtotal;
  final double shipping;
  final double total;

  const _TotalsCard({
    required this.subtotal,
    required this.shipping,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        color: AppColors.bottomNavBackground.withOpacity(0.40),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _SummaryRow(label: context.tr('cart_subtotal'), value: IqdCurrency.format(subtotal), valueColor: AppColors.white),
          const SizedBox(height: 14),
          _SummaryRow(label: context.tr('cart_shipping'), value: IqdCurrency.format(shipping), valueColor: AppColors.white),
          const SizedBox(height: 16),
          Divider(color: AppColors.white.withOpacity(0.10), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                IqdCurrency.format(total),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 40,
                ),
              ),
              const Spacer(),
              Text(
                context.tr('cart_total'),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        Text(
          label,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.iconTint,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _ConfirmOrderBar extends StatelessWidget {
  final VoidCallback onTap;

  const _ConfirmOrderBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
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
        child: SizedBox(
          height: 64,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      context.tr('cart_confirm'),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
