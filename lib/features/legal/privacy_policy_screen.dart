import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('سياسة الخصوصية', style: AppTextStyles.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSection(
              'مقدمة',
              'نحن في Shine نلتزم بحماية خصوصيتك. توضح سياسة الخصوصية هذه كيفية جمع معلوماتك الشخصية واستخدامها وحمايتها عند استخدام تطبيقنا.',
            ),
            _buildSection(
              'المعلومات التي نجمعها',
              '''نقوم بجمع المعلومات التالية:
              
• معلومات الحساب: الاسم، البريد الإلكتروني، رقم الهاتف، العنوان
• معلومات الطلب: تفاصيل المنتجات المطلوبة وعنوان التوصيل
• معلومات الاستخدام: كيفية تفاعلك مع التطبيق لتحسين تجربتك''',
            ),
            _buildSection(
              'كيف نستخدم معلوماتك',
              '''نستخدم المعلومات المجمعة للأغراض التالية:

• معالجة وتوصيل طلباتك
• التواصل معك بخصوص طلباتك
• تحسين خدماتنا ومنتجاتنا
• إرسال إشعارات حول حالة الطلب
• تقديم توصيات منتجات مخصصة''',
            ),
            _buildSection(
              'حماية المعلومات',
              'نحن نتخذ تدابير أمنية مناسبة لحماية معلوماتك الشخصية من الوصول غير المصرح به أو التغيير أو الإفصاح أو التدمير.',
            ),
            _buildSection(
              'مشاركة المعلومات',
              '''لا نبيع أو نؤجر معلوماتك الشخصية لأطراف ثالثة. قد نشارك معلوماتك فقط مع:

• مزودي خدمات التوصيل لإتمام عملية التسليم
• مزودي خدمات الدفع (إن وجد)
• السلطات القانونية عند الطلب''',
            ),
            _buildSection(
              'حقوقك',
              '''لديك الحق في:

• الوصول إلى معلوماتك الشخصية
• تصحيح أي معلومات غير دقيقة
• طلب حذف حسابك ومعلوماتك
• إلغاء الاشتراك في الإشعارات التسويقية''',
            ),
            _buildSection(
              'تحديثات السياسة',
              'قد نقوم بتحديث سياسة الخصوصية هذه من وقت لآخر. سنخطرك بأي تغييرات جوهرية عبر التطبيق أو البريد الإلكتروني.',
            ),
            _buildSection(
              'التواصل معنا',
              'إذا كانت لديك أي أسئلة حول سياسة الخصوصية هذه، يرجى التواصل معنا عبر البريد الإلكتروني: support@shinepara.com',
            ),
            const SizedBox(height: 16),
            Text(
              'آخر تحديث: ديسمبر 2024',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
