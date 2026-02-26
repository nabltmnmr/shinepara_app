import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../localization/shine_strings.dart';
import '../../models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  static const Map<String, String> _assetByArabicName = {
    'العناية بالبشرة': 'assets/images/categories/skin.png',
    'العناية باليد': 'assets/images/categories/hand.png',
    'العناية بالجسم': 'assets/images/categories/body.png',
    'العناية بالاسنان': 'assets/images/categories/teeth.png',
    'العناية بالقدم': 'assets/images/categories/foot.png',
    'العناية بالشعر': 'assets/images/categories/hair.png',
  };

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = category.nameAr.trim().isNotEmpty ? category.nameAr.trim() : category.nameEn.trim();
    final label = category.nameEn.trim().isNotEmpty
        ? category.nameEn.trim().toUpperCase()
        : category.id.trim().toUpperCase();
    final localAsset = _assetByArabicName[category.nameAr.trim()];
    final imageUrl = (category.imageUrl ?? category.iconUrl ?? '').trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground.withOpacity(0.48),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final bottomH = (h * 0.36).clamp(132.0, 146.0);
              final imageH = (h - bottomH).clamp(0.0, h);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: imageH,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: imageUrl.isNotEmpty
                              ? (localAsset != null
                                  ? Image.asset(localAsset, fit: BoxFit.cover)
                                  : CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => _imagePlaceholder(),
                                      errorWidget: (_, __, ___) => _imagePlaceholder(),
                                    ))
                              : (localAsset != null
                                  ? Image.asset(localAsset, fit: BoxFit.cover)
                                  : _imagePlaceholder()),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.bottomNavBackground.withOpacity(0.55),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: bottomH,
                    child: ColoredBox(
                      color: AppColors.cardBottomPanel,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 1.1,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.textOffWhite,
                                fontWeight: FontWeight.w900,
                                height: 1.04,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.22),
                                    border: Border.all(color: AppColors.white.withOpacity(0.08)),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.white,
                                    size: 16,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  context.tr('view_all'),
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.brandCircleBackground,
      child: const Center(
        child: Icon(Icons.category, color: AppColors.textMuted),
      ),
    );
  }
}
