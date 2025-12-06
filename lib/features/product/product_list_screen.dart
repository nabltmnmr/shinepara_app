import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/product_card.dart';
import '../../services/providers.dart';

class ProductListScreen extends ConsumerWidget {
  final int? categoryId;
  final int? brandId;
  final String? searchQuery;

  const ProductListScreen({
    super.key,
    this.categoryId,
    this.brandId,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ProductFilter(
      categoryId: categoryId,
      brandId: brandId,
      searchQuery: searchQuery,
    );
    final products = ref.watch(productsProvider(filter));

    String title = 'المنتجات';
    if (categoryId != null) {
      final categories = ref.watch(categoriesProvider);
      categories.whenData((list) {
        final category = list.where((c) => c.id == categoryId).firstOrNull;
        if (category != null) title = category.nameAr;
      });
    } else if (brandId != null) {
      final brands = ref.watch(brandsProvider);
      brands.whenData((list) {
        final brand = list.where((b) => b.id == brandId).firstOrNull;
        if (brand != null) title = brand.name;
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(title, style: AppTextStyles.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: products.when(
        data: (productList) {
          if (productList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد منتجات',
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
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: productList.length,
            itemBuilder: (context, index) {
              final product = productList[index];
              return ProductCard(
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
                onPressed: () => ref.invalidate(productsProvider(filter)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
