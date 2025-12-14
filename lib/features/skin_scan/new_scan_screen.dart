import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';

class NewScanScreen extends ConsumerStatefulWidget {
  const NewScanScreen({super.key});

  @override
  ConsumerState<NewScanScreen> createState() => _NewScanScreenState();
}

class _NewScanScreenState extends ConsumerState<NewScanScreen> {
  String _selectedArea = 'face';
  File? _selectedImage;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();

  final Map<String, String> _areaNames = {
    'face': 'الوجه كامل',
    'forehead': 'الجبين',
    'cheeks': 'الخدين',
    'chin': 'الذقن',
  };

  final Map<String, IconData> _areaIcons = {
    'face': Icons.face,
    'forehead': Icons.circle_outlined,
    'cheeks': Icons.blur_on,
    'chin': Icons.gesture,
  };

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
            SizedBox(height: 20),
            _buildAreaSelector(),
            SizedBox(height: 20),
            _buildImageSection(),
            SizedBox(height: 24),
            _buildAnalyzeButton(),
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

  Widget _buildAreaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر المنطقة للفحص', style: AppTextStyles.titleMedium),
        SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _areaNames.entries.map((entry) {
            final isSelected = _selectedArea == entry.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedArea = entry.key),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _areaIcons[entry.key],
                      size: 20,
                      color: isSelected ? AppColors.white : AppColors.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      entry.value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('صورة البشرة', style: AppTextStyles.titleMedium),
        SizedBox(height: 12),
        if (_selectedImage != null)
          _buildSelectedImage()
        else
          _buildImagePicker(),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPickerOption(
            icon: Icons.camera_alt,
            label: 'الكاميرا',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          Container(
            height: 80,
            width: 1,
            color: AppColors.divider,
          ),
          _buildPickerOption(
            icon: Icons.photo_library,
            label: 'المعرض',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sectionHeader,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          SizedBox(height: 12),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSelectedImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _selectedImage!,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => setState(() => _selectedImage = null),
            icon: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: AppColors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return ElevatedButton(
      onPressed: _selectedImage != null && !_isAnalyzing ? _analyzeSkin : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.textLight,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isAnalyzing
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('جاري التحليل...', style: AppTextStyles.buttonText),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.white),
                SizedBox(width: 10),
                Text('تحليل البشرة', style: AppTextStyles.buttonText),
              ],
            ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
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

  Future<void> _analyzeSkin() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final scan = await ref.read(skinScanServiceProvider).analyzeSkin(
        imageFile: _selectedImage!,
        areaType: _selectedArea,
      );

      if (mounted) {
        ref.invalidate(scanHistoryProvider);
        ref.invalidate(scanCreditsProvider);
        context.pushReplacement('/skin-scan/results/${scan.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحليل البشرة'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }
}
