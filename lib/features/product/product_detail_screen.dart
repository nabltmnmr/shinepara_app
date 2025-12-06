import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final wishlist = ref.watch(wishlistProvider);
    final cartItems = ref.watch(cartProvider);
    final formatter = NumberFormat('#,###', 'ar');

    return Scaffold(
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
                  Text('المنتج غير موجود', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('العودة'),
                  ),
                ],
              ),
            );
          }

          final isInWishlist = wishlist.contains(product.id);
          final isInCart = cartItems.any((item) => item.productId == product.id);
          final imageUrl = product.imageUrl ?? '';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: AppColors.cardBackground,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? AppColors.error : AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      ref.read(wishlistProvider.notifier).toggleWishlist(product.id);
                    },
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.share, color: AppColors.textPrimary, size: 20),
                    ),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: AppColors.cardBackground,
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.cardBackground,
                            child: Icon(Icons.image_not_supported, size: 64, color: AppColors.textLight),
                          ),
                        )
                      : Container(
                          color: AppColors.cardBackground,
                          child: Icon(Icons.image_not_supported, size: 64, color: AppColors.textLight),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.hasDiscount) ...[
                                  Text(
                                    '${formatter.format(product.price)} د.ع',
                                    style: AppTextStyles.oldPrice,
                                    textDirection: ui.TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  '${formatter.format(product.displayPrice)} د.ع',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textDirection: ui.TextDirection.rtl,
                                ),
                              ],
                            ),
                            Expanded(
                              child: Text(
                                product.nameAr,
                                style: AppTextStyles.headlineSmall,
                                textAlign: TextAlign.right,
                                textDirection: ui.TextDirection.rtl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (product.hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'خصم ${product.discountPercentage.toInt()}%',
                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
                              textDirection: ui.TextDirection.rtl,
                            ),
                          ),
                        const SizedBox(height: 24),
                        _buildSection('الوصف', product.descriptionAr),
                        if (product.usage != null && product.usage!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSection('طريقة الاستخدام', product.usage!),
                        ],
                        if (product.ingredients != null && product.ingredients!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSection('المكونات', product.ingredients!),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...product.skinTypes.map((type) => _buildTag(type, AppColors.sectionHeader)),
                            ...product.concerns.map((concern) => _buildTag(concern, AppColors.aiAssistantLight)),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('حدث خطأ في تحميل المنتج', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(productDetailProvider(productId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: productAsync.when(
        data: (product) {
          if (product == null) return const SizedBox.shrink();
          final isInCart = cartItems.any((item) => item.productId == product.id);
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'تمت الإضافة إلى السلة',
                              textDirection: ui.TextDirection.rtl,
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'عرض السلة',
                              textColor: AppColors.white,
                              onPressed: () => context.push('/cart'),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInCart ? AppColors.success : AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isInCart ? 'أضف المزيد' : 'أضف إلى السلة',
                            style: AppTextStyles.buttonText,
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.shopping_bag_outlined, color: AppColors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium,
          textDirection: ui.TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.right,
          textDirection: ui.TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary),
        textDirection: ui.TextDirection.rtl,
      ),
    );
  }
}
