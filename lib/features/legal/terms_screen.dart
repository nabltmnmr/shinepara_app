import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        title: Text('شروط الاستخدام', style: AppTextStyles.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSection(
              'القبول بالشروط',
              'باستخدامك لتطبيق Shine، فإنك توافق على الالتزام بشروط الاستخدام هذه. إذا كنت لا توافق على أي من هذه الشروط، يرجى عدم استخدام التطبيق.',
            ),
            _buildSection(
              'استخدام التطبيق',
              '''يجب عليك:

• أن تكون بعمر 18 عامًا أو أكثر لإنشاء حساب
• تقديم معلومات صحيحة ودقيقة عند التسجيل
• الحفاظ على سرية معلومات تسجيل الدخول الخاصة بك
• استخدام التطبيق لأغراض قانونية فقط''',
            ),
            _buildSection(
              'الطلبات والدفع',
              '''• جميع الأسعار معروضة بالدينار العراقي
• الدفع يتم عند الاستلام (كاش)
• نحتفظ بالحق في رفض أي طلب
• أسعار المنتجات قابلة للتغيير دون إشعار مسبق''',
            ),
            _buildSection(
              'التوصيل',
              '''• نسعى جاهدين لتوصيل طلبك في الوقت المحدد
• قد تختلف أوقات التوصيل حسب موقعك
• يجب أن يكون شخص متاح لاستلام الطلب في العنوان المحدد
• رسوم التوصيل تُحسب تلقائيًا عند الطلب''',
            ),
            _buildSection(
              'الإرجاع والاستبدال',
              '''• يمكنك إرجاع المنتجات خلال 7 أيام من الاستلام
• يجب أن تكون المنتجات في حالتها الأصلية وغير مستخدمة
• بعض المنتجات غير قابلة للإرجاع لأسباب صحية
• تواصل معنا لبدء عملية الإرجاع''',
            ),
            _buildSection(
              'المنتجات',
              '''• نسعى لعرض صور ومعلومات دقيقة عن المنتجات
• قد تختلف الألوان قليلاً بسبب إعدادات الشاشة
• المعلومات المقدمة ليست بديلاً عن الاستشارة الطبية
• تحقق من المكونات إذا كان لديك حساسية''',
            ),
            _buildSection(
              'المسؤولية',
              '''• لا نتحمل المسؤولية عن أي ردود فعل تحسسية
• استخدم المنتجات وفقًا للتعليمات المرفقة
• توقف عن الاستخدام واستشر طبيبًا إذا لاحظت أي تهيج
• لا نتحمل المسؤولية عن الأضرار الناتجة عن سوء الاستخدام''',
            ),
            _buildSection(
              'حقوق الملكية الفكرية',
              'جميع المحتويات في التطبيق، بما في ذلك النصوص والصور والشعارات، محمية بحقوق الملكية الفكرية ولا يجوز نسخها أو استخدامها دون إذن.',
            ),
            _buildSection(
              'تعديل الشروط',
              'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بأي تغييرات جوهرية عبر التطبيق.',
            ),
            _buildSection(
              'التواصل معنا',
              'لأي استفسارات حول شروط الاستخدام، يرجى التواصل معنا عبر البريد الإلكتروني: support@shinepara.com',
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
