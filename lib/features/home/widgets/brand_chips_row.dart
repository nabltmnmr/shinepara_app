import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/brand.dart';

class BrandChipsRow extends StatelessWidget {
  final List<Brand> brands;
  final VoidCallback onViewAll;
  final ValueChanged<Brand> onTapBrand;

  const BrandChipsRow({
    super.key,
    required this.brands,
    required this.onViewAll,
    required this.onTapBrand,
  });

  @override
  Widget build(BuildContext context) {
    final items = _pickReferenceBrands(brands);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.viewAll,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Trending Brands',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textOffWhite,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            reverse: false,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final brand = items[index];
              final bool active = _isLume(brand) || (items.every((b) => !_isLume(b)) && index == 3);
              return _BrandItem(
                name: brand.name,
                logoUrl: brand.logoUrl,
                active: active,
                onTap: () => onTapBrand(brand),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isLume(Brand b) => b.name.trim().toLowerCase() == 'lume';

  List<Brand> _pickReferenceBrands(List<Brand> input) {
    // Try to match the reference names first; otherwise just take first 4.
    const target = ['pure', 'flora', 'aqua', 'lume'];
    final map = {for (final b in input) b.name.trim().toLowerCase(): b};
    final picked = <Brand>[];
    for (final key in target) {
      final b = map[key];
      if (b != null) picked.add(b);
    }
    if (picked.length >= 4) return picked.take(4).toList();
    final rest = input.where((b) => !picked.contains(b)).toList();
    return [...picked, ...rest].take(4).toList();
  }
}

class _BrandItem extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final bool active;
  final VoidCallback onTap;

  const _BrandItem({
    required this.name,
    required this.logoUrl,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale = active ? 1.06 : 1.0;
    final borderColor = active ? AppColors.primary : AppColors.white.withOpacity(0.08);

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandCircleBackground,
                border: Border.all(color: borderColor, width: active ? 2 : 1),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.45),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: (logoUrl != null && logoUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: logoUrl!,
                        imageBuilder: (context, imageProvider) => Container(
                          color: AppColors.brandCircleBackground,
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        placeholder: (_, __) => _logoPlaceholder(),
                        errorWidget: (_, __, ___) => _logoPlaceholder(),
                      )
                    : _logoPlaceholder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFF9D8F86),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      color: AppColors.brandCircleBackground,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
        style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

