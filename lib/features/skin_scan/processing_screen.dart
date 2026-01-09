import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final File imageFile;

  const ProcessingScreen({super.key, required this.imageFile});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  int _currentStep = 0;
  String _statusMessage = 'جاري التحضير...';
  bool _hasError = false;

  final List<Map<String, dynamic>> _steps = [
    {'title': 'كشف الوجه', 'icon': Icons.face, 'duration': 800},
    {'title': 'تقسيم مناطق البشرة', 'icon': Icons.grid_on, 'duration': 1000},
    {'title': 'فحص جودة الصورة', 'icon': Icons.high_quality, 'duration': 600},
    {'title': 'تحليل البشرة بالذكاء الاصطناعي', 'icon': Icons.psychology, 'duration': 3000},
    {'title': 'إنشاء الصور التحليلية', 'icon': Icons.image, 'duration': 2000},
    {'title': 'حفظ النتائج', 'icon': Icons.save, 'duration': 500},
  ];

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    try {
      for (int i = 0; i < _steps.length - 1; i++) {
        if (!mounted) return;
        setState(() {
          _currentStep = i;
          _statusMessage = _steps[i]['title'] as String;
        });
        await Future.delayed(Duration(milliseconds: _steps[i]['duration'] as int));
      }

      setState(() {
        _currentStep = _steps.length - 2;
        _statusMessage = 'جاري التحليل...';
      });

      final scan = await ref.read(skinScanServiceProvider).analyzeSkin(
        imageFile: widget.imageFile,
        areaType: 'face',
      );

      setState(() {
        _currentStep = _steps.length - 1;
        _statusMessage = 'اكتمل التحليل!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ref.invalidate(scanHistoryProvider);
        ref.invalidate(scanCreditsProvider);
        context.go('/skin-scan/results/${scan.id}');
      }
    } catch (e, stackTrace) {
      debugPrint('Skin scan error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'حدث خطأ أثناء التحليل';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImagePreview(),
              const SizedBox(height: 40),
              _buildProgressIndicator(),
              const SizedBox(height: 24),
              _buildStepsList(),
              const SizedBox(height: 32),
              if (_hasError) _buildRetryButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: AppColors.primary, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.file(widget.imageFile, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentStep + 1) / _steps.length;
    
    return Column(
      children: [
        Text(
          _statusMessage,
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: _hasError ? 0 : progress,
          backgroundColor: AppColors.divider,
          color: _hasError ? AppColors.error : AppColors.primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_currentStep + 1)}/${_steps.length}',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStepsList() {
    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;
        final isPending = index > _currentStep;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.success
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.divider,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isCurrent
                          ? step['icon'] as IconData
                          : step['icon'] as IconData,
                  color: isPending ? AppColors.textLight : Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step['title'] as String,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isPending
                        ? AppColors.textLight
                        : isCompleted
                            ? AppColors.success
                            : AppColors.textPrimary,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isCurrent && !_hasError)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRetryButton() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/skin-scan'),
          child: Text('العودة', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
