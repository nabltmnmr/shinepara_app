import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final formatter = NumberFormat('#,###', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('سلة التسوق', style: AppTextStyles.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تفريغ السلة', textDirection: ui.TextDirection.rtl
),
                    content: const Text('هل تريد حذف جميع المنتجات من السلة؟', textDirection: ui.TextDirection.rtl
),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          cartNotifier.clearCart();
                          Navigator.pop(context);
                        },
                        child: Text('حذف', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
              child: Text('مسح الكل', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'سلة التسوق فارغة',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                    textDirection: ui.TextDirection.rtl
,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضف بعض المنتجات للبدء',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                    textDirection: ui.TextDirection.rtl
,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('تسوق الآن'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final imageUrl = item.product.imageUrl ?? '';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
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
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () {
                          cartNotifier.removeFromCart(item.productId);
                        },
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onPressed: () {
                              cartNotifier.updateQuantity(item.productId, item.quantity + 1);
                            },
                          ),
                          Text(
                            '${item.quantity}',
                            style: AppTextStyles.titleMedium,
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: AppColors.textLight),
                            onPressed: () {
                              cartNotifier.updateQuantity(item.productId, item.quantity - 1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item.product.nameAr,
                              style: AppTextStyles.titleSmall,
                              textAlign: TextAlign.right,
                              textDirection: ui.TextDirection.rtl
,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatter.format(item.product.displayPrice)} د.ع',
                              style: AppTextStyles.price,
                              textDirection: ui.TextDirection.rtl
,
                            ),
                            if (item.quantity > 1) ...[
                              const SizedBox(height: 2),
                              Text(
                                'المجموع: ${formatter.format(item.totalPrice)} د.ع',
                                style: AppTextStyles.bodySmall,
                                textDirection: ui.TextDirection.rtl
,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.divider,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.divider,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: AppColors.divider,
                                child: const Icon(Icons.image_not_supported),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${formatter.format(cartNotifier.totalPrice)} د.ع',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: ui.TextDirection.rtl
,
                        ),
                        Text(
                          'المجموع (${cartNotifier.itemCount} منتج)',
                          style: AppTextStyles.titleMedium,
                          textDirection: ui.TextDirection.rtl
,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/checkout'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('إتمام الشراء', style: AppTextStyles.buttonText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
