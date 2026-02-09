import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../../models/brand.dart';

/// Circular brand avatar used in carousels and brand directories.
class ShineBrandChip extends StatelessWidget {
  final Brand brand;
  final VoidCallback? onTap;
  final bool highlighted;

  const ShineBrandChip({
    super.key,
    required this.brand,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderGradient = highlighted
        ? const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: borderGradient,
                color: borderGradient == null ? AppColors.surfaceDarker : null,
                boxShadow: highlighted
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ]
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandCircleBackground,
                  border: Border.all(
                    color: AppColors.white.withOpacity(0.05),
                  ),
                ),
                child: ClipOval(
                  child: _buildImageOrFallback(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              brand.name,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOrFallback() {
    final logoUrl = (brand.logoUrl ?? '').trim();

    if (logoUrl.isEmpty) {
      return _fallback();
    }

    return CachedNetworkImage(
      imageUrl: logoUrl,
      // Keep logos centered and NOT cropped in the circle.
      imageBuilder: (context, imageProvider) => Container(
        color: AppColors.brandCircleBackground,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image(
            image: imageProvider,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _fallback(),
      placeholder: (_, __) => _fallback(),
    );
  }

  Widget _fallback() {
    final letter = brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'B';
    return Container(
      color: AppColors.brandCircleBackground,
      child: Center(
        child: Text(
          letter,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

