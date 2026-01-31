import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/banner.dart';

class HeroBannerCard extends StatelessWidget {
  final HomeBanner? banner;
  final VoidCallback? onTapCta;

  /// If you provide an asset path (e.g. `assets/images/hero_girl.jpg`),
  /// it will be used as a fallback when banner image URL is missing/fails.
  final String? fallbackAssetPath;

  const HeroBannerCard({
    super.key,
    required this.banner,
    this.onTapCta,
    this.fallbackAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(30);
    final imageUrl = banner?.imageUrl?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: AspectRatio(
          aspectRatio: 0.88, // tall, dominant visual
          child: Stack(
            fit: StackFit.expand,
            children: [
              _HeroImage(
                imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                fallbackAssetPath: fallbackAssetPath,
              ),

              // Warm espresso bottom overlay (NOT black)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color.fromRGBO(27, 18, 14, 0.85),
                      ],
                      stops: [0.38, 1.0],
                    ),
                  ),
                ),
              ),

              // NEW COLLECTION pill near top-right
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7D6C3).withOpacity(0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'NEW COLLECTION',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),

              // Hero content (lower-left)
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Awaken Your',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textOffWhite,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Inner ',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.textOffWhite,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: 'Glow',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Discover the new nightly repair\nserum designed for radiant\nmornings',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textOffWhite.withOpacity(0.88),
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    _HeroCtaButton(
                      onTap: onTapCta,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCtaButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _HeroCtaButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'Start Your Routine',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackAssetPath;

  const _HeroImage({required this.imageUrl, required this.fallbackAssetPath});

  @override
  Widget build(BuildContext context) {
    final warmPlaceholder = Container(color: AppColors.surfaceDark);

    if (imageUrl == null || imageUrl!.isEmpty) {
      if (fallbackAssetPath != null && fallbackAssetPath!.isNotEmpty) {
        return Image.asset(
          fallbackAssetPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => warmPlaceholder,
        );
      }
      return warmPlaceholder;
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => warmPlaceholder,
      errorWidget: (_, __, ___) {
        if (fallbackAssetPath != null && fallbackAssetPath!.isNotEmpty) {
          return Image.asset(
            fallbackAssetPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => warmPlaceholder,
          );
        }
        return warmPlaceholder;
      },
    );
  }
}

