import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../../models/product.dart';
import '../../services/providers.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final isInWishlist = wishlist.contains(product.id);
    final formatter = NumberFormat('#,###', 'ar');
    final imageUrl = product.imageUrl ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
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
                              color: AppColors.divider,
                              child: Icon(Icons.image_not_supported, color: AppColors.textLight),
                            ),
                          )
                        : Container(
                            color: AppColors.divider,
                            child: Icon(Icons.image_not_supported, color: AppColors.textLight),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      onPressed: () {
                        ref.read(wishlistProvider.notifier).toggleWishlist(product.id);
                      },
                      icon: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? AppColors.error : AppColors.textLight,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.white.withOpacity(0.9),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercentage.toInt()}%-',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.nameAr,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: ui.TextDirection.rtl,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'د.ع',
                          style: AppTextStyles.labelSmall,
                        ),
                        const SizedBox(width: 4),
                        if (product.hasDiscount) ...[
                          Text(
                            formatter.format(product.price),
                            style: AppTextStyles.oldPrice,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          formatter.format(product.displayPrice),
                          style: AppTextStyles.price,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
