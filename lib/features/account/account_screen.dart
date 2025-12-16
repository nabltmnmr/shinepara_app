import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('حسابي', style: AppTextStyles.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.safeGoBack(),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                onPressed: () => context.push('/notifications'),
              ),
              unreadCount.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: user != null
                  ? Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.sectionHeader,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: AppTextStyles.titleLarge,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        if (user.phone != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.phone!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                          ),
                        ],
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showEditProfileDialog(context, ref),
                          icon: Icon(Icons.edit, size: 18),
                          label: const Text('تعديل الملف الشخصي'),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.sectionHeader,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'مرحباً بك في Shine',
                          style: AppTextStyles.titleLarge,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سجل دخولك للوصول إلى حسابك',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push('/login'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text('تسجيل الدخول'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: Text(
                            'إنشاء حساب جديد',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            if (user != null) ...[
              _buildMenuItem(
                icon: Icons.shopping_bag_outlined,
                title: 'طلباتي',
                onTap: () => context.push('/orders'),
              ),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                title: 'الإشعارات',
                trailing: unreadCount.when(
                  data: (count) => count > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      : null,
                  loading: () => null,
                  error: (_, __) => null,
                ),
                onTap: () => context.push('/notifications'),
              ),
            ],
            _buildMenuItem(
              icon: Icons.favorite_border,
              title: 'المفضلة',
              onTap: () => context.push('/wishlist'),
            ),
            _buildMenuItem(
              icon: Icons.headset_mic_outlined,
              title: 'تواصل معنا',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              title: 'سياسة الخصوصية',
              onTap: () => context.push('/privacy-policy'),
            ),
            _buildMenuItem(
              icon: Icons.description_outlined,
              title: 'شروط الاستخدام',
              onTap: () => context.push('/terms'),
            ),
            _buildMenuItem(
              icon: Icons.info_outline,
              title: 'عن التطبيق',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Shine',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 Shinepara',
                );
              },
            ),
            if (user != null) ...[
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'تسجيل الخروج',
                textColor: Colors.red,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('تسجيل الخروج', textDirection: TextDirection.rtl),
                      content: const Text('هل أنت متأكد من تسجيل الخروج؟', textDirection: TextDirection.rtl),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('خروج', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/');
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider);
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final locationController = TextEditingController(text: user.location ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الملف الشخصي', textDirection: TextDirection.rtl),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'الموقع',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(authProvider.notifier).updateProfile(
                  fullName: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  location: locationController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم تحديث البيانات بنجاح', textDirection: TextDirection.rtl),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل تحديث البيانات: ${e.toString()}', textDirection: TextDirection.rtl),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.arrow_back_ios, color: AppColors.textLight, size: 16),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(color: textColor),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: textColor ?? AppColors.primary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
