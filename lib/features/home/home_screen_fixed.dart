import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_app_bar.dart';
import '../../core/localization/shine_strings.dart';
import '../../services/providers.dart';
import 'widgets/brand_chips_row.dart';
import 'widgets/hero_banner_card.dart';
import 'widgets/product_grid_card.dart';

/// Home screen (spec-accurate).
///
/// Structure:
/// 1) ShineAppBar (custom, seamless)
/// 2) HeroBannerCard (full-bleed image + warm overlay + CTA)
/// 3) Trending Brands header + row
/// 4) New Arrivals title + product grid
/// 5) Bottom nav provided by MainShell
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String heroAssetPath = 'assets/images/hero_girl.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final bestSellersAsync = ref.watch(bestSellersProvider);
    final cartItems = ref.watch(cartProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    // Reference layout is LTR.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(bannersProvider);
              ref.invalidate(brandsProvider);
              ref.invalidate(bestSellersProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: ShineAppBar(
                    notificationsCount: unreadCountAsync.when(
                      data: (v) => v,
                      loading: () => 0,
                      error: (_, __) => 0,
                    ),
                    cartCount: cartItems.length,
                    onTapNotifications: () => context.push('/notifications'),
                    onTapCart: () => context.push('/cart'),
                    onTapSearch: () => context.push('/search'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: bannersAsync.when(
                    data: (banners) => HeroBannerCard(
                      banner: banners.isNotEmpty ? banners.first : null,
                      fallbackAssetPath: heroAssetPath,
                      onTapCta: () => context.push('/skin-scan'),
                    ),
                    loading: () => const _HeroLoadingPlaceholder(),
                    error: (_, __) => HeroBannerCard(
                      banner: null,
                      fallbackAssetPath: heroAssetPath,
                      onTapCta: () => context.push('/skin-scan'),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: brandsAsync.when(
                    data: (brands) => BrandChipsRow(
                      brands: brands,
                      onViewAll: () => context.push('/brands'),
                      onTapBrand: (b) => context.push('/products?brandId=${b.id}'),
                    ),
                    loading: () => const SizedBox(height: 130),
                    error: (_, __) => const SizedBox(height: 130),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('new_arrivals'),
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textOffWhite,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/products'),
                          child: Text(
                            context.tr('view_all'),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.viewAll,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: bestSellersAsync.when(
                      data: (products) => ProductGridCard(
                        products: products,
                        onTapProduct: (p) => context.push('/product/${p.id}'),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroLoadingPlaceholder extends StatelessWidget {
  const _HeroLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: AspectRatio(
          aspectRatio: 0.88,
          child: Container(
            color: AppColors.surfaceDark,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

