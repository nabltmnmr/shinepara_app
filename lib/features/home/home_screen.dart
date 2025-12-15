import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/category_card.dart';
import '../../core/widgets/brand_card.dart';
import '../../core/widgets/brand_story_card.dart';
import '../../core/widgets/whatsapp_button.dart';
import '../../services/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(bannersProvider);
    final categories = ref.watch(categoriesProvider);
    final bestSellers = ref.watch(bestSellersProvider);
    final brands = ref.watch(brandsProvider);
    final cartItems = ref.watch(cartProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Shine',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
                onPressed: () => context.push('/cart'),
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${ref.read(cartProvider.notifier).itemCount}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                onPressed: () => context.push('/notifications'),
              ),
              unreadCount.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
                loading: () => SizedBox.shrink(),
                error: (_, __) => SizedBox.shrink(),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => context.push('/search'),
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.person_outline, color: AppColors.textPrimary),
          onPressed: () => context.push('/account'),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bannersProvider);
              ref.invalidate(categoriesProvider);
              ref.invalidate(bestSellersProvider);
              ref.invalidate(brandsProvider);
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  banners.when(
                    data: (bannerList) {
                      if (bannerList.isEmpty) {
                        return _buildDefaultHeroBanner();
                      }
                      return CarouselSlider(
                        options: CarouselOptions(
                          height: 200,
                          viewportFraction: 0.95,
                          autoPlay: bannerList.length > 1,
                          autoPlayInterval: Duration(seconds: 4),
                          enlargeCenterPage: true,
                        ),
                        items: bannerList.map((banner) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.sectionHeader,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                                    CachedNetworkImage(
                                      imageUrl: banner.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => _buildBannerPlaceholder(banner),
                                      errorWidget: (context, url, error) => _buildBannerPlaceholder(banner),
                                    )
                                  else
                                    _buildBannerPlaceholder(banner),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => Container(
                      height: 200,
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.sectionHeader,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    error: (error, stack) => Container(
                      height: 200,
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.sectionHeader,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Shine', style: AppTextStyles.headlineLarge),
                            Text('اشراقة تبدأ من هنا', style: AppTextStyles.bodyMedium, textDirection: TextDirection.rtl),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  brands.when(
                    data: (brandList) => _buildBrandStories(context, brandList),
                    loading: () => SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    error: (error, stack) => SizedBox(
                      height: 100,
                      child: Center(child: Text('حدث خطأ في تحميل العلامات التجارية')),
                    ),
                  ),
                  SizedBox(height: 16),
                  SectionHeader(
                    title: 'التصنيفات',
                    onViewAll: () => context.push('/categories'),
                  ),
                  SizedBox(height: 8),
                  categories.when(
                    data: (categoryList) => SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categoryList.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final category = categoryList[index];
                          return Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: CategoryCard(
                              category: category,
                              onTap: () => context.push('/products?categoryId=${category.id}'),
                            ),
                          );
                        },
                      ),
                    ),
                    loading: () => SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    error: (error, stack) => SizedBox(
                      height: 140,
                      child: Center(child: Text('حدث خطأ في تحميل التصنيفات')),
                    ),
                  ),
                  SizedBox(height: 24),
                  SectionHeader(
                    title: 'الأكثر مبيعاً',
                    onViewAll: () => context.push('/products'),
                  ),
                  SizedBox(height: 8),
                  bestSellers.when(
                    data: (productList) => SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: productList.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final product = productList[index];
                          return Container(
                            width: 180,
                            margin: EdgeInsets.only(left: 16),
                            child: ProductCard(
                              product: product,
                              onTap: () => context.push('/product/${product.id}'),
                            ),
                          );
                        },
                      ),
                    ),
                    loading: () => SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    error: (error, stack) => SizedBox(
                      height: 280,
                      child: Center(child: Text('حدث خطأ في تحميل المنتجات')),
                    ),
                  ),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'ai_assistant',
                  onPressed: () => context.push('/ai-assistant'),
                  backgroundColor: AppColors.aiAssistant,
                  child: Icon(Icons.auto_awesome, color: AppColors.white),
                ),
                SizedBox(height: 12),
                WhatsAppButton(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.go('/categories');
              break;
            case 2:
              context.go('/skin-scan');
              break;
            case 3:
              context.go('/wishlist');
              break;
            case 4:
              context.go('/account');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'التصنيفات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face_retouching_natural_outlined),
            activeIcon: Icon(Icons.face_retouching_natural),
            label: 'فحص البشرة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'المفضلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultHeroBanner() {
    return Container(
      height: 200,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sectionHeader,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Shine',
              style: AppTextStyles.headlineLarge.copyWith(
                fontWeight: FontWeight.w300,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'اشراقة تبدأ من هنا',
              style: AppTextStyles.bodyLarge,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPlaceholder(dynamic banner) {
    return Container(
      color: AppColors.sectionHeader,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            banner.title ?? 'Shine',
            style: AppTextStyles.headlineLarge,
          ),
          if (banner.subtitle != null)
            Text(
              banner.subtitle!,
              style: AppTextStyles.bodyMedium,
              textDirection: TextDirection.rtl,
            ),
        ],
      ),
    );
  }

  Widget _buildBrandStories(BuildContext context, List<dynamic> brandList) {
    if (brandList.isEmpty) {
      return SizedBox.shrink();
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemCount: brandList.length,
        itemBuilder: (context, index) {
          final brand = brandList[index];
          final hasNewProducts = brand.hasNewProducts ?? false;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: BrandStoryCard(
              brand: brand,
              hasNewProducts: hasNewProducts,
              onTap: () => context.push('/products?brandId=${brand.id}&sort=newest'),
            ),
          );
        },
      ),
    );
  }
}
