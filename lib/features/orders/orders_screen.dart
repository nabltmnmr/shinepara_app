import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';
import '../../models/order.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('طلباتي', style: AppTextStyles.titleLarge),
        centerTitle: true,
      ),
      body: orders.when(
        data: (orderList) {
          if (orderList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد طلبات',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ التسوق الآن!',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تصفح المنتجات'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ordersProvider);
            },
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
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل الطلبات',
                style: AppTextStyles.bodyMedium,
                textDirection: ui.TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(ordersProvider),
                child: const Text('إعادة المحاولة'),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(order.status),
                    Text(
                      'طلب #${order.id}',
                      style: AppTextStyles.titleSmall,
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
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
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
                    Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textLight),
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
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'confirmed':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'preparing':
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case 'shipped':
        bgColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade800;
        break;
      case 'delivered':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'cancelled':
      case 'returned':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
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
