import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../../models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: category.iconUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.divider,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.sectionHeader,
                  child: Icon(Icons.category, color: AppColors.primary, size: 40),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            category.nameAr,
            style: AppTextStyles.labelMedium,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
