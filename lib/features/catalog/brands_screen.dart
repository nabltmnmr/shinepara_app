import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_brand_chip.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../core/localization/shine_strings.dart';
import '../../services/providers.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  final Map<String, GlobalKey> _sectionKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);

    return ShineScaffold(
      body: SafeArea(
        child: brands.when(
          data: (brandList) {
            final grouped = _groupBrands(brandList);
            final letters = grouped.keys.toList()..sort();

            return Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      _buildSearch(),
                      const SizedBox(height: 12),
                      ...letters.map((letter) => _buildSection(letter, grouped[letter]!)),
                    ],
                  ),
                ),
                _buildIndexBar(letters),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => Center(
            child: Text(
              context.tr('brands_load_error'),
              style: AppTextStyles.bodyMedium,
            ),
          ),
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
            icon: const Icon(Icons.tune, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          const Spacer(),
          Text(
            context.tr('brands_directory'),
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: ShineStrings.of(context, 'brands_search_hint'),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSection(String letter, List<dynamic> brands) {
    _sectionKeys.putIfAbsent(letter, () => GlobalKey());

    return Padding(
      key: _sectionKeys[letter],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.white.withOpacity(0.12),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                letter.toUpperCase(),
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              for (final brand in brands)
                ShineBrandChip(
                  brand: brand,
                  onTap: () => context.push('/products?brandId=${brand.id}'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndexBar(List<String> letters) {
    return Positioned(
      right: 8,
      top: 140,
      bottom: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final letter in letters)
            GestureDetector(
              onTap: () => _scrollTo(letter),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  letter.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _scrollTo(String letter) {
    final key = _sectionKeys[letter];
    if (key == null) return;
    final context = key.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Map<String, List<dynamic>> _groupBrands(List<dynamic> brands) {
    final Map<String, List<dynamic>> grouped = {};
    for (final brand in brands) {
      final name = (brand.name ?? '').toString().trim();
      final letter = name.isEmpty ? '#' : name[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(brand);
    }
    return grouped;
  }
}
