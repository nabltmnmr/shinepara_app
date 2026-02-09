import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/localization/shine_strings.dart';
import '../../core/widgets/shine_product_card.dart';
import '../../services/providers.dart';

class WishlistScreen extends ConsumerWidget {
  final VoidCallback? onBackToHome;

  const WishlistScreen({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistIds = ref.watch(wishlistProvider);
    final wishlistProducts = ref.watch(wishlistProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(context.tr('wishlist'), style: AppTextStyles.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              context.pop();
              return;
            }
            if (onBackToHome != null) {
              onBackToHome!();
              return;
            }
            context.go('/');
          },
        ),
      ),
      body: wishlistIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('wishlist_empty_title'),
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('wishlist_empty_subtitle'),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (onBackToHome != null) {
                        onBackToHome!();
                      } else {
                        context.go('/');
                      }
                    },
                    child: Text(context.tr('browse_products')),
                  ),
                ],
              ),
            )
          : wishlistProducts.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 80, color: AppColors.textLight),
                        const SizedBox(height: 16),
                        Text(
                          'قائمة المفضلة فارغة',
                          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.66,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ShineProductCard(
                      product: product,
                      onTap: () => context.push('/product/${product.id}'),
                    );
                  },
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
                    Text(
                      'حدث خطأ في تحميل المنتجات',
                      style: AppTextStyles.bodyMedium,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(wishlistProductsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
