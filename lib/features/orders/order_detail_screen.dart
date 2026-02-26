import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../core/widgets/shine_glass_panel.dart';
import '../../core/widgets/shine_primary_button.dart';
import '../../core/utils/iqd_currency.dart';
import '../../services/providers.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    final dateFormatter = DateFormat('yyyy/MM/dd - HH:mm', 'ar');

    return ShineScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'تفاصيل الطلب #$orderId',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: order.when(
        data: (orderData) {
          if (orderData == null) {
            return Center(
              child: Text(
                'الطلب غير موجود',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                textDirection: ui.TextDirection.rtl,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShineGlassPanel(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(orderData.status),
                          Text(
                            'حالة الطلب',
                            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
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
                ShineGlassPanel(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'المنتجات',
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
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
                                IqdCurrency.format(item.subtotal),
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
                                      '${IqdCurrency.format(item.unitPrice)} × ${item.quantity}',
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
                ShineGlassPanel(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ملخص الطلب',
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                        textDirection: ui.TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      _buildPriceRow('المجموع الفرعي', orderData.subtotal),
                      _buildPriceRow('رسوم التوصيل', orderData.shippingFee),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            IqdCurrency.format(orderData.total),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الإجمالي',
                            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
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
                              color: AppColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'الدفع عند الاستلام',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.success),
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
                  ShineGlassPanel(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'تتبع الطلب',
                          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
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
                'حدث خطأ في تحميل الطلب',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                textDirection: ui.TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              ShinePrimaryButton(
                label: 'إعادة المحاولة',
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
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

  Widget _buildPriceRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            IqdCurrency.format(value),
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
