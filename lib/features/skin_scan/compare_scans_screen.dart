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
  SkinScan? _scan1;
  SkinScan? _scan2;

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
        data: (scans) => _buildContent(scans),
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(child: Text('حدث خطأ في تحميل البيانات')),
      ),
    );
  }

  Widget _buildContent(List<SkinScan> scans) {
    if (scans.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: AppColors.textLight),
            SizedBox(height: 16),
            Text('تحتاج إلى فحصين على الأقل للمقارنة', style: AppTextStyles.bodyLarge),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/skin-scan/new'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('بدء فحص جديد', style: AppTextStyles.buttonText),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWarningBanner(),
          SizedBox(height: 16),
          _buildScanSelector(scans),
          SizedBox(height: 24),
          if (_scan1 != null && _scan2 != null) _buildComparison(),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'إذا كانت الإضاءة أو زاوية الصورة مختلفة بين الفحصين، قد تكون النتائج غير دقيقة.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanSelector(List<SkinScan> scans) {
    return Row(
      children: [
        Expanded(
          child: _buildScanDropdown(
            label: 'الفحص الأول',
            value: _scan1,
            scans: scans.where((s) => _scan2 == null || s.id != _scan2!.id).toList(),
            onChanged: (scan) => setState(() => _scan1 = scan),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.compare_arrows, color: AppColors.textLight),
        ),
        Expanded(
          child: _buildScanDropdown(
            label: 'الفحص الثاني',
            value: _scan2,
            scans: scans.where((s) => _scan1 == null || s.id != _scan1!.id).toList(),
            onChanged: (scan) => setState(() => _scan2 = scan),
          ),
        ),
      ],
    );
  }

  Widget _buildScanDropdown({
    required String label,
    required SkinScan? value,
    required List<SkinScan> scans,
    required Function(SkinScan?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SkinScan>(
              value: value,
              isExpanded: true,
              hint: Text('اختر', style: AppTextStyles.bodySmall),
              items: scans.map((scan) {
                return DropdownMenuItem(
                  value: scan,
                  child: Text(
                    '${_formatDate(scan.createdAt)} (${scan.overallScore}%)',
                    style: AppTextStyles.bodySmall,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScoreComparison(),
        SizedBox(height: 24),
        _buildMetricDeltas(),
      ],
    );
  }

  Widget _buildScoreComparison() {
    final diff = _scan2!.overallScore - _scan1!.overallScore;
    final isImproved = diff > 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('مقارنة النتيجة الإجمالية', style: AppTextStyles.titleMedium),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreCircle(_scan1!.overallScore, _formatDate(_scan1!.createdAt)),
              Column(
                children: [
                  Icon(
                    isImproved ? Icons.arrow_upward : (diff < 0 ? Icons.arrow_downward : Icons.remove),
                    color: isImproved ? AppColors.success : (diff < 0 ? AppColors.error : AppColors.textLight),
                    size: 32,
                  ),
                  Text(
                    diff == 0 ? 'ثابت' : '${diff > 0 ? '+' : ''}$diff%',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: isImproved ? AppColors.success : (diff < 0 ? AppColors.error : AppColors.textLight),
                    ),
                  ),
                  Text(
                    isImproved ? 'تحسن' : (diff < 0 ? 'تراجع' : ''),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isImproved ? AppColors.success : (diff < 0 ? AppColors.error : AppColors.textLight),
                    ),
                  ),
                ],
              ),
              _buildScoreCircle(_scan2!.overallScore, _formatDate(_scan2!.createdAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(int score, String label) {
    final color = score >= 70
        ? AppColors.success
        : score >= 50
            ? Colors.orange
            : AppColors.error;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: AppColors.divider,
                color: color,
              ),
            ),
            Text(
              '$score%',
              style: AppTextStyles.titleLarge.copyWith(color: color),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildMetricDeltas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تفاصيل المقارنة (12 مؤشر)', style: AppTextStyles.titleLarge),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.sectionHeader,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('المؤشر', style: AppTextStyles.bodySmall)),
              Expanded(child: Text('قبل', style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
              Expanded(child: Text('التغيير', style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
              Expanded(child: Text('بعد', style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
            ],
          ),
        ),
        SizedBox(height: 8),
        ...SkinScan.metricKeys.map((key) {
          final val1 = _scan1!.getMetricValue(key);
          final val2 = _scan2!.getMetricValue(key);
          final diff = val1 - val2;
          final isImproved = diff > 0;
          final nameAr = SkinScan.metricNamesAr[key] ?? key;

          return Container(
            margin: EdgeInsets.only(bottom: 6),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(nameAr, style: AppTextStyles.bodyMedium),
                ),
                Expanded(
                  child: Text(
                    '${100 - val1}%',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (diff != 0)
                        Icon(
                          isImproved ? Icons.trending_up : Icons.trending_down,
                          color: isImproved ? AppColors.success : AppColors.error,
                          size: 14,
                        ),
                      SizedBox(width: 2),
                      Text(
                        diff == 0 ? '-' : '${diff > 0 ? '+' : ''}$diff',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: diff == 0
                              ? AppColors.textLight
                              : isImproved
                                  ? AppColors.success
                                  : AppColors.error,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    '${100 - val2}%',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
