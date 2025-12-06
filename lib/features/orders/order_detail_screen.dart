import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    final formatter = NumberFormat('#,###', 'ar');
    final dateFormatter = DateFormat('yyyy/MM/dd - HH:mm', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('تفاصيل الطلب #$orderId', style: AppTextStyles.titleLarge),
        centerTitle: true,
      ),
      body: order.when(
        data: (orderData) {
          if (orderData == null) {
            return Center(
              child: Text(
                'الطلب غير موجود',
                style: AppTextStyles.bodyMedium,
                textDirection: ui.TextDirection.rtl,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(orderData.status),
                          Text(
                            'حالة الطلب',
                            style: AppTextStyles.titleSmall,
                            textDirection: ui.TextDirection.rtl,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('تاريخ الطلب', dateFormatter.format(orderData.createdAt)),
                      _buildInfoRow('الاسم', orderData.customerName),
                      _buildInfoRow('الهاتف', orderData.customerPhone),
                      _buildInfoRow('العنوان', orderData.customerLocation),
                      if (orderData.notes != null && orderData.notes!.isNotEmpty)
                        _buildInfoRow('ملاحظات', orderData.notes!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'المنتجات',
                        style: AppTextStyles.titleSmall,
                        textDirection: ui.TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      if (orderData.items.isEmpty)
                        Text(
                          'لا توجد منتجات',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        )
                      else
                        ...orderData.items.map((item) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.divider),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${formatter.format(item.subtotal)} د.ع',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: AppTextStyles.bodyMedium,
                                      textDirection: ui.TextDirection.rtl,
                                    ),
                                    Text(
                                      '${formatter.format(item.unitPrice)} د.ع × ${item.quantity}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textDirection: ui.TextDirection.rtl,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ملخص الطلب',
                        style: AppTextStyles.titleSmall,
                        textDirection: ui.TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      _buildPriceRow('المجموع الفرعي', orderData.subtotal, formatter),
                      _buildPriceRow('رسوم التوصيل', orderData.shippingFee, formatter),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${formatter.format(orderData.total)} د.ع',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الإجمالي',
                            style: AppTextStyles.titleSmall,
                            textDirection: ui.TextDirection.rtl,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'الدفع عند الاستلام',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                          Text(
                            'طريقة الدفع',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            textDirection: ui.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (orderData.statusHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'تتبع الطلب',
                          style: AppTextStyles.titleSmall,
                          textDirection: ui.TextDirection.rtl,
                        ),
                        const SizedBox(height: 12),
                        ...orderData.statusHistory.asMap().entries.map((entry) {
                          final index = entry.key;
                          final history = entry.value;
                          final isLast = index == orderData.statusHistory.length - 1;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        history.statusAr,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        textDirection: ui.TextDirection.rtl,
                                      ),
                                      Text(
                                        dateFormatter.format(history.changedAt),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      if (history.notes != null && history.notes!.isNotEmpty)
                                        Text(
                                          history.notes!,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          textDirection: ui.TextDirection.rtl,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isLast ? AppColors.primary : AppColors.textLight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 40,
                                      color: AppColors.textLight.withOpacity(0.5),
                                    ),
                                ],
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
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
                'حدث خطأ في تحميل الطلب',
                style: AppTextStyles.bodyMedium,
                textDirection: ui.TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.left,
              textDirection: ui.TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$label:',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textDirection: ui.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${formatter.format(value)} د.ع',
            style: AppTextStyles.bodyMedium,
          ),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textDirection: ui.TextDirection.rtl,
          ),
        ],
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
        _getStatusAr(status),
        style: AppTextStyles.labelSmall.copyWith(color: textColor),
      ),
    );
  }

  String _getStatusAr(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'تم التأكيد';
      case 'preparing':
        return 'قيد التحضير';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      case 'returned':
        return 'مرتجع';
      default:
        return status;
    }
  }
}
