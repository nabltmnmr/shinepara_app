import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/product_card.dart';
import '../../services/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ProductFilter(searchQuery: _searchQuery);
    final products = ref.watch(productsProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج...',
            hintTextDirection: TextDirection.rtl,
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
      ),
      body: _searchQuery.isEmpty
          ? _buildEmptySearch()
          : products.when(
              data: (productList) {
                if (productList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppColors.textLight),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد نتائج لـ "$_searchQuery"',
                          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'جرب البحث بكلمات مختلفة',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                child: Text('حدث خطأ في البحث'),
              ),
            ),
    );
  }

  Widget _buildEmptySearch() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'بحث شائع',
            style: AppTextStyles.titleMedium,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSearchChip('سيروم فيتامين سي'),
              _buildSearchChip('واقي شمس'),
              _buildSearchChip('غسول'),
              _buildSearchChip('مرطب'),
              _buildSearchChip('حب الشباب'),
              _buildSearchChip('تصبغات'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String text) {
    return ActionChip(
      label: Text(text, style: AppTextStyles.labelMedium),
      backgroundColor: AppColors.sectionHeader,
      onPressed: () {
        _searchController.text = text;
        setState(() => _searchQuery = text);
      },
    );
  }
}
