import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_product_card.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/providers.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final int? brandId;
  final String? searchQuery;

  const ProductListScreen({
    super.key,
    this.categoryId,
    this.brandId,
    this.searchQuery,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  static const int _itemsPerPage = 30;
  late final TextEditingController _searchController;
  String _localQuery = '';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _localQuery = (widget.searchQuery ?? '').trim();
    _searchController = TextEditingController(text: _localQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    final trimmed = value.trim();
    setState(() {
      _localQuery = trimmed;
      _currentPage = 1;
    });
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final filtersChanged = oldWidget.categoryId != widget.categoryId ||
        oldWidget.brandId != widget.brandId ||
        oldWidget.searchQuery != widget.searchQuery;
    if (filtersChanged) {
      _localQuery = (widget.searchQuery ?? '').trim();
      _searchController.text = _localQuery;
      _currentPage = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ProductFilter(
      categoryId: widget.categoryId,
      brandId: widget.brandId,
      searchQuery: _localQuery,
    );
    final products = ref.watch(productsProvider(filter));

    String title = 'المنتجات';
    if (widget.categoryId != null) {
      final categories = ref.watch(categoriesProvider);
      categories.whenData((list) {
        final category =
            list.where((c) => c.id == widget.categoryId).firstOrNull;
        if (category != null) title = category.nameAr;
      });
    } else if (widget.brandId != null) {
      final brands = ref.watch(brandsProvider);
      brands.whenData((list) {
        final brand = list.where((b) => b.id == widget.brandId).firstOrNull;
        if (brand != null) title = brand.name;
      });
    }

    // Match Home background exactly (warm dark, no extra glow blobs).
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: AppColors.background),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTopBar(context, title),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchBar(context),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: products.when(
                    data: (productList) {
                      if (productList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 64, color: AppColors.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد منتجات',
                                style: AppTextStyles.titleMedium
                                    .copyWith(color: AppColors.textSecondary),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        );
                      }
                      final totalPages = (productList.length / _itemsPerPage).ceil();
                      final safePage = _currentPage.clamp(1, totalPages);
                      final start = (safePage - 1) * _itemsPerPage;
                      final end = (start + _itemsPerPage).clamp(0, productList.length);
                      final pageItems = productList.sublist(start, end);

                      if (safePage != _currentPage) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _currentPage = safePage);
                        });
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio:
                                    0.56, // bigger/taller cards (match reference)
                              ),
                              itemCount: pageItems.length,
                              itemBuilder: (context, index) {
                                final product = pageItems[index];
                                return ShineProductCard(
                                  product: product,
                                  onTap: () => context.push('/product/${product.id}'),
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: safePage > 1
                                        ? () => setState(() => _currentPage = safePage - 1)
                                        : null,
                                    icon: const Icon(Icons.navigate_before),
                                    label: const Text('السابق'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'الصفحة $safePage من $totalPages',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: safePage < totalPages
                                        ? () => setState(() => _currentPage = safePage + 1)
                                        : null,
                                    icon: const Icon(Icons.navigate_next),
                                    label: const Text('التالي'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ في تحميل المنتجات',
                            style: AppTextStyles.bodyMedium,
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                ref.invalidate(productsProvider(filter)),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String title) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.safeGoBack(),
        ),
        const Spacer(),
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textOffWhite,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 48), // keep title visually centered
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        onChanged: _applySearch,
        onSubmitted: _applySearch,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.iconTint.withOpacity(0.95),
          ),
          suffixIcon: const Icon(Icons.search, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.bottomNavBackground.withOpacity(0.45),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.35), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
