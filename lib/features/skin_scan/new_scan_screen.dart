import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class NewScanScreen extends ConsumerStatefulWidget {
  const NewScanScreen({super.key});

  @override
  ConsumerState<NewScanScreen> createState() => _NewScanScreenState();
}

class _NewScanScreenState extends ConsumerState<NewScanScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('فحص جديد', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTipsCard(),
            SizedBox(height: 24),
            _buildCaptureOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.aiAssistantLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.aiAssistant),
              SizedBox(width: 8),
              Text('نصائح للحصول على نتائج أفضل', style: AppTextStyles.titleSmall),
            ],
          ),
          SizedBox(height: 12),
          _buildTip('استخدم إضاءة طبيعية جيدة'),
          _buildTip('تأكد من نظافة الوجه من المكياج'),
          _buildTip('التقط الصورة من مسافة 30 سم تقريباً'),
          _buildTip('حافظ على تعبير محايد للوجه'),
          _buildTip('تأكد من ظهور الوجه بالكامل في الإطار'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildCaptureOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر طريقة التقاط الصورة', style: AppTextStyles.titleMedium),
        SizedBox(height: 16),
        _buildOptionCard(
          icon: Icons.camera_alt,
          title: 'التقاط صورة جديدة',
          subtitle: 'استخدم الكاميرا الأمامية مع توجيه ذكي',
          color: AppColors.primary,
          onTap: () => _pickImage(ImageSource.camera),
        ),
        SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.photo_library,
          title: 'اختيار من المعرض',
          subtitle: 'اختر صورة موجودة من معرض الصور',
          color: AppColors.accent,
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image != null) {
        if (mounted) {
          context.push('/skin-scan/processing', extra: File(image.path));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في اختيار الصورة'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
