import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/skin_scan.dart';
import '../../services/providers.dart';

class CompareScansScreen extends ConsumerStatefulWidget {
  const CompareScansScreen({super.key});

  @override
  ConsumerState<CompareScansScreen> createState() => _CompareScansScreenState();
}

class _CompareScansScreenState extends ConsumerState<CompareScansScreen> {
  SkinScan? _selectedScan1;
  SkinScan? _selectedScan2;
  bool _isComparing = false;
  ScanComparison? _comparison;

  final Map<String, String> _metricLabels = {
    'hydration': 'الترطيب',
    'oiliness': 'الدهنية',
    'texture': 'النسيج',
    'pores': 'المسام',
    'spots': 'البقع',
    'wrinkles': 'التجاعيد',
  };

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('مقارنة الفحوصات', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: historyAsync.when(
        data: (history) => _buildContent(history),
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(child: Text('حدث خطأ في تحميل السجل')),
      ),
    );
  }

  Widget _buildContent(List<SkinScan> history) {
    if (history.length < 2) {
      return _buildInsufficientScans();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScanSelector('الفحص الأول', _selectedScan1, history, (scan) {
            setState(() => _selectedScan1 = scan);
          }),
          SizedBox(height: 16),
          _buildScanSelector('الفحص الثاني', _selectedScan2, history, (scan) {
            setState(() => _selectedScan2 = scan);
          }),
          SizedBox(height: 20),
          _buildCompareButton(),
          SizedBox(height: 20),
          if (_comparison != null) _buildComparisonResults(),
        ],
      ),
    );
  }

  Widget _buildInsufficientScans() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 80, color: AppColors.textLight),
            SizedBox(height: 20),
            Text(
              'يجب إجراء فحصين على الأقل للمقارنة',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'قم بإجراء فحوصات إضافية لتتمكن من مقارنة تطور بشرتك',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/skin-scan/new'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('إجراء فحص جديد', style: AppTextStyles.buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanSelector(
    String label,
    SkinScan? selected,
    List<SkinScan> history,
    Function(SkinScan?) onChanged,
  ) {
    final availableScans = history.where((scan) {
      if (label == 'الفحص الأول') {
        return _selectedScan2 == null || scan.id != _selectedScan2!.id;
      } else {
        return _selectedScan1 == null || scan.id != _selectedScan1!.id;
      }
    }).toList();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected != null ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.titleSmall),
          SizedBox(height: 12),
          DropdownButtonFormField<SkinScan>(
            value: selected,
            hint: Text('اختر فحص', style: AppTextStyles.bodyMedium),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: availableScans.map((scan) {
              return DropdownMenuItem(
                value: scan,
                child: Text(
                  '${_formatDate(scan.createdAt)} - ${scan.overallScore}%',
                  style: AppTextStyles.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          if (selected != null) ...[
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('النتيجة:', style: AppTextStyles.bodySmall),
                Text(
                  '${selected.overallScore}%',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompareButton() {
    final canCompare = _selectedScan1 != null && _selectedScan2 != null;

    return ElevatedButton(
      onPressed: canCompare && !_isComparing ? _compareScans : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        disabledBackgroundColor: AppColors.textLight,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isComparing
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('جاري المقارنة...', style: AppTextStyles.buttonText),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.compare_arrows, color: AppColors.white),
                SizedBox(width: 10),
                Text('مقارنة الفحوصات', style: AppTextStyles.buttonText),
              ],
            ),
    );
  }

  Widget _buildComparisonResults() {
    if (_comparison == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.accent),
              SizedBox(width: 8),
              Text('نتائج المقارنة', style: AppTextStyles.titleMedium),
            ],
          ),
          SizedBox(height: 16),
          _buildOverallDelta(),
          SizedBox(height: 16),
          _buildMetricsDelta(),
          if (_comparison!.aiInsights != null) ...[
            SizedBox(height: 16),
            _buildAIInsights(_comparison!.aiInsights!),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallDelta() {
    final delta = _comparison!.scan2.overallScore - _comparison!.scan1.overallScore;
    final isPositive = delta > 0;
    final color = isPositive ? AppColors.success : (delta < 0 ? AppColors.error : AppColors.textSecondary);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('التغيير الإجمالي', style: AppTextStyles.titleSmall),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : (delta < 0 ? Icons.arrow_downward : Icons.remove),
                color: color,
                size: 20,
              ),
              SizedBox(width: 4),
              Text(
                '${delta > 0 ? '+' : ''}$delta%',
                style: AppTextStyles.titleMedium.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsDelta() {
    final delta = _comparison!.delta;

    return Column(
      children: _metricLabels.entries.map((entry) {
        final change = delta[entry.key] as int? ?? 0;
        final isPositive = change > 0;
        final color = isPositive ? AppColors.success : (change < 0 ? AppColors.error : AppColors.textSecondary);

        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.value, style: AppTextStyles.bodyMedium),
              Row(
                children: [
                  if (change != 0)
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: color,
                      size: 16,
                    ),
                  SizedBox(width: 4),
                  Text(
                    change == 0 ? 'ثابت' : '${change > 0 ? '+' : ''}$change%',
                    style: AppTextStyles.bodyMedium.copyWith(color: color),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAIInsights(String insights) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.aiAssistantLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.aiAssistant, size: 18),
              SizedBox(width: 8),
              Text('تحليل التطور', style: AppTextStyles.titleSmall),
            ],
          ),
          SizedBox(height: 10),
          Text(
            insights,
            style: AppTextStyles.bodyMedium,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _compareScans() async {
    if (_selectedScan1 == null || _selectedScan2 == null) return;

    setState(() => _isComparing = true);

    try {
      final comparison = await ref.read(skinScanServiceProvider).compareScans(
        scanId1: _selectedScan1!.id,
        scanId2: _selectedScan2!.id,
      );
      setState(() => _comparison = comparison);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في المقارنة'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isComparing = false);
    }
  }
}
