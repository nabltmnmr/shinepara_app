import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/skin_scan.dart';
import '../../services/providers.dart';

class ScanResultsScreen extends ConsumerStatefulWidget {
  final int scanId;

  const ScanResultsScreen({super.key, required this.scanId});

  @override
  ConsumerState<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends ConsumerState<ScanResultsScreen> {
  double _selectedBudget = 50000;
  bool _isGeneratingRoutine = false;
  String? _generatedRoutine;

  final Map<String, String> _metricLabels = {
    'hydration': 'الترطيب',
    'oiliness': 'الدهنية',
    'texture': 'النسيج',
    'pores': 'المسام',
    'spots': 'البقع',
    'wrinkles': 'التجاعيد',
  };

  final Map<String, IconData> _metricIcons = {
    'hydration': Icons.water_drop,
    'oiliness': Icons.opacity,
    'texture': Icons.texture,
    'pores': Icons.blur_circular,
    'spots': Icons.circle,
    'wrinkles': Icons.waves,
  };

  @override
  Widget build(BuildContext context) {
    final scanAsync = ref.watch(skinScanProvider(widget.scanId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('نتائج الفحص', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.go('/skin-scan'),
        ),
      ),
      body: scanAsync.when(
        data: (scan) => scan != null
            ? _buildResults(scan)
            : Center(child: Text('الفحص غير موجود')),
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(child: Text('حدث خطأ في تحميل النتائج')),
      ),
    );
  }

  Widget _buildResults(SkinScan scan) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOverallScoreCard(scan),
          SizedBox(height: 20),
          _buildMetricsGrid(scan),
          SizedBox(height: 20),
          if (scan.summary != null) _buildSummaryCard(scan.summary!),
          SizedBox(height: 20),
          _buildRoutineSection(scan),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard(SkinScan scan) {
    final score = scan.overallScore;
    final scoreColor = score >= 70
        ? AppColors.success
        : score >= 50
            ? Colors.orange
            : AppColors.error;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('النتيجة الإجمالية', style: AppTextStyles.titleMedium),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: AppColors.divider,
                  color: scoreColor,
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score%',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: scoreColor,
                      fontSize: 36,
                    ),
                  ),
                  Text(
                    _getScoreLabel(score),
                    style: AppTextStyles.bodySmall.copyWith(color: scoreColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'ممتاز';
    if (score >= 70) return 'جيد جداً';
    if (score >= 60) return 'جيد';
    if (score >= 50) return 'مقبول';
    return 'يحتاج عناية';
  }

  Widget _buildMetricsGrid(SkinScan scan) {
    final metrics = scan.metrics;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تحليل مفصل', style: AppTextStyles.titleLarge),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: _metricLabels.entries.map((entry) {
            final value = metrics[entry.key] as int? ?? 0;
            return _buildMetricCard(
              label: entry.value,
              value: value,
              icon: _metricIcons[entry.key] ?? Icons.circle,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int value,
    required IconData icon,
  }) {
    final color = value >= 70
        ? AppColors.success
        : value >= 50
            ? Colors.orange
            : AppColors.error;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    backgroundColor: AppColors.divider,
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '$value%',
                style: AppTextStyles.titleSmall.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
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
              Icon(Icons.auto_awesome, color: AppColors.aiAssistant),
              SizedBox(width: 8),
              Text('تحليل الذكاء الاصطناعي', style: AppTextStyles.titleSmall),
            ],
          ),
          SizedBox(height: 12),
          Text(
            summary,
            style: AppTextStyles.bodyMedium,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSection(SkinScan scan) {
    if (scan.routine != null && _generatedRoutine == null) {
      _generatedRoutine = scan.routine;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('روتين العناية المقترح', style: AppTextStyles.titleLarge),
        SizedBox(height: 12),
        if (_generatedRoutine != null)
          _buildRoutineCard(_generatedRoutine!)
        else
          _buildRoutineGenerator(scan),
      ],
    );
  }

  Widget _buildRoutineGenerator(SkinScan scan) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('حدد ميزانيتك الشهرية للعناية بالبشرة', style: AppTextStyles.titleSmall),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('25,000 د.ع', style: AppTextStyles.bodySmall),
              Text('${_selectedBudget.toInt().toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]},'
              )} د.ع', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
              Text('200,000 د.ع', style: AppTextStyles.bodySmall),
            ],
          ),
          Slider(
            value: _selectedBudget,
            min: 25000,
            max: 200000,
            divisions: 7,
            activeColor: AppColors.primary,
            onChanged: (value) => setState(() => _selectedBudget = value),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isGeneratingRoutine ? null : () => _generateRoutine(scan.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isGeneratingRoutine
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('جاري إنشاء الروتين...', style: AppTextStyles.buttonText),
                    ],
                  )
                : Text('إنشاء روتين مخصص', style: AppTextStyles.buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(String routine) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa, color: AppColors.success),
              SizedBox(width: 8),
              Text('روتينك المخصص', style: AppTextStyles.titleSmall.copyWith(color: AppColors.success)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            routine,
            style: AppTextStyles.bodyMedium,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() => _generatedRoutine = null),
            icon: Icon(Icons.refresh, color: AppColors.accent),
            label: Text('إنشاء روتين جديد', style: TextStyle(color: AppColors.accent)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateRoutine(int scanId) async {
    setState(() => _isGeneratingRoutine = true);

    try {
      final routine = await ref.read(skinScanServiceProvider).generateRoutine(
        scanId: scanId,
        budget: _selectedBudget,
      );
      setState(() => _generatedRoutine = routine);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في إنشاء الروتين'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isGeneratingRoutine = false);
    }
  }
}
