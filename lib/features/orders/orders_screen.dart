import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../core/widgets/shine_glass_panel.dart';
import '../../core/widgets/shine_primary_button.dart';
import '../../services/providers.dart';
import '../../models/order.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return ShineScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('طلباتي', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: orders.when(
        data: (orderList) {
          if (orderList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد طلبات',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ التسوق الآن!',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 24),
                  ShinePrimaryButton(
                    label: 'تصفح المنتجات',
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ordersProvider),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                final order = orderList[index];
                return _OrderCard(
                  order: order,
                  onTap: () => context.push('/order/${order.id}'),
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل الطلبات',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                textDirection: ui.TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              ShinePrimaryButton(
                label: 'إعادة المحاولة',
                onPressed: () => ref.invalidate(ordersProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ar');
    final dateFormatter = DateFormat('yyyy/MM/dd', 'ar');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShineGlassPanel(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(order.status),
                    Text(
                      'طلب #${order.id}',
                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormatter.format(order.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    Text(
                      '${formatter.format(order.total)} د.ع',
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textMuted),
                    Text(
                      order.statusAr,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.3);
        textColor = Colors.orange.shade200;
        break;
      case 'confirmed':
        bgColor = Colors.blue.withOpacity(0.3);
        textColor = Colors.blue.shade200;
        break;
      case 'preparing':
        bgColor = Colors.purple.withOpacity(0.3);
        textColor = Colors.purple.shade200;
        break;
      case 'shipped':
        bgColor = Colors.indigo.withOpacity(0.3);
        textColor = Colors.indigo.shade200;
        break;
      case 'delivered':
        bgColor = AppColors.success.withOpacity(0.3);
        textColor = AppColors.success;
        break;
      case 'cancelled':
      case 'returned':
        bgColor = AppColors.error.withOpacity(0.3);
        textColor = AppColors.error;
        break;
      default:
        bgColor = AppColors.textMuted.withOpacity(0.2);
        textColor = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        Order(
          id: 0,
          customerName: '',
          customerPhone: '',
          customerLocation: '',
          subtotal: 0,
          shippingFee: 0,
          total: 0,
          status: status,
          createdAt: DateTime.now(),
        ).statusAr,
        style: AppTextStyles.labelSmall.copyWith(color: textColor),
      ),
    );
  }
}
