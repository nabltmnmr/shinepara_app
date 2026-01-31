import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return ShineScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: categories.when(
                data: (categoryList) => GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: categoryList.length,
                  itemBuilder: (context, index) {
                    final category = categoryList[index];
                    final iconUrl = (category.iconUrl ?? '').trim();

                    return GestureDetector(
                      onTap: () => context.push('/products?categoryId=${category.id}'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.white.withOpacity(0.05)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: iconUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: iconUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Icon(
                                          Icons.category,
                                          color: AppColors.primary,
                                          size: 40,
                                        ),
                                      )
                                    : Icon(
                                        Icons.category,
                                        color: AppColors.primary,
                                        size: 40,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              category.nameAr,
                              style: AppTextStyles.titleSmall.copyWith(color: AppColors.white),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      const Text('حدث خطأ في تحميل التصنيفات'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(categoriesProvider),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.safeGoBack(),
          ),
          const Spacer(),
          Text(
            'Categories',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
          ),
          const Spacer(),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
