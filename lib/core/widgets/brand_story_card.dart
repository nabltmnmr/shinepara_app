import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../../models/brand.dart';

class BrandStoryCard extends StatelessWidget {
  final Brand brand;
  final VoidCallback onTap;
  final bool hasNewProducts;

  const BrandStoryCard({
    super.key,
    required this.brand,
    required this.onTap,
    this.hasNewProducts = false,
  });

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasNewProducts
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFE8A5A0),
                          Color(0xFF8B4B6B),
                          Color(0xFFE8A5A0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: hasNewProducts
                    ? null
                    : Border.all(color: AppColors.divider, width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: ClipOval(
                  child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: brand.logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildNameFallback(),
                          errorWidget: (context, url, error) => _buildNameFallback(),
                        )
                      : _buildNameFallback(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              brand.name,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: hasNewProducts ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildNameFallback() {
    final initials = brand.name.length > 2 
        ? brand.name.substring(0, 2).toUpperCase()
        : brand.name.toUpperCase();
    
    return Container(
      color: AppColors.sectionHeader,
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
