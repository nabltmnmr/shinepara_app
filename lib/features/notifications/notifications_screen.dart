import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';
import '../../models/notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final apiClient = ref.watch(apiClientProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('الإشعارات', style: AppTextStyles.titleLarge),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await apiClient.markAllNotificationsAsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: Text(
              'قراءة الكل',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: notifications.when(
        data: (notificationList) {
          if (notificationList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ستظهر هنا إشعارات الطلبات والتحديثات',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationList.length,
              itemBuilder: (context, index) {
                final notification = notificationList[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () async {
                    if (!notification.isRead) {
                      await apiClient.markNotificationAsRead(notification.id);
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadNotificationCountProvider);
                    }
                    if (notification.orderId != null) {
                      context.push('/order/${notification.orderId}');
                    }
                  },
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
                'حدث خطأ في تحميل الإشعارات',
                style: AppTextStyles.bodyMedium,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.cardBackground : AppColors.sectionHeader,
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead 
            ? null 
            : Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification.timeAgo,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      notification.typeIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconBackgroundColor() {
    switch (notification.type) {
      case 'order_confirmation':
        return Colors.blue.shade50;
      case 'order_shipped':
        return Colors.orange.shade50;
      case 'order_delivered':
        return Colors.green.shade50;
      case 'order_cancelled':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }
}
