import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/skin_scan.dart';
import '../../services/providers.dart';

class SkinScanHomeScreen extends ConsumerWidget {
  const SkinScanHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(scanCreditsProvider);
    final historyAsync = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('فحص البشرة', style: AppTextStyles.headlineSmall),
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
            _buildCreditsCard(creditsAsync, ref),
            SizedBox(height: 20),
            _buildNewScanButton(context, creditsAsync),
            SizedBox(height: 24),
            _buildHistorySection(context, historyAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsCard(AsyncValue<ScanCredits> creditsAsync, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رصيد الفحوصات',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: 4),
                  creditsAsync.when(
                    data: (credits) => Text(
                      '${credits.credits}',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.white,
                        fontSize: 48,
                      ),
                    ),
                    loading: () => CircularProgressIndicator(color: AppColors.white),
                    error: (_, __) => Text(
                      '0',
                      style: AppTextStyles.headlineLarge.copyWith(color: AppColors.white),
                    ),
                  ),
                ],
              ),
              Icon(Icons.face_retouching_natural, size: 60, color: AppColors.white.withOpacity(0.8)),
            ],
          ),
          SizedBox(height: 16),
          creditsAsync.when(
            data: (credits) => credits.canClaimShareReward
                ? _buildShareRewardButton(ref)
                : _buildRewardClaimed(),
            loading: () => SizedBox.shrink(),
            error: (_, __) => SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildShareRewardButton(WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        await ref.read(scanCreditsProvider.notifier).claimShareReward();
      },
      icon: Icon(Icons.share, color: AppColors.white),
      label: Text('شارك واحصل على +2 فحص', style: TextStyle(color: AppColors.white)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.white),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildRewardClaimed() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'تم الحصول على المكافأة اليوم',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNewScanButton(BuildContext context, AsyncValue<ScanCredits> creditsAsync) {
    final hasCredits = creditsAsync.when(
      data: (credits) => credits.credits > 0,
      loading: () => false,
      error: (_, __) => false,
    );

    return ElevatedButton(
      onPressed: hasCredits ? () => context.push('/skin-scan/new') : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.textLight,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, color: AppColors.white),
          SizedBox(width: 10),
          Text(
            hasCredits ? 'بدء فحص جديد' : 'لا يوجد رصيد كافٍ',
            style: AppTextStyles.buttonText,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, AsyncValue<List<SkinScan>> historyAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('سجل الفحوصات', style: AppTextStyles.titleLarge),
            historyAsync.when(
              data: (history) => history.length >= 2
                  ? TextButton.icon(
                      onPressed: () => context.push('/skin-scan/compare'),
                      icon: Icon(Icons.compare_arrows, color: AppColors.accent),
                      label: Text('مقارنة', style: TextStyle(color: AppColors.accent)),
                    )
                  : SizedBox.shrink(),
              loading: () => SizedBox.shrink(),
              error: (_, __) => SizedBox.shrink(),
            ),
          ],
        ),
        SizedBox(height: 12),
        historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return _buildEmptyHistory();
            }
            return Column(
              children: history.map((scan) => _buildHistoryItem(context, scan)).toList(),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => Center(
            child: Text('حدث خطأ في تحميل السجل'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: AppColors.textLight),
          SizedBox(height: 12),
          Text(
            'لا توجد فحوصات سابقة',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
          ),
          Text(
            'ابدأ فحصك الأول الآن',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, SkinScan scan) {
    final areaNames = {
      'face': 'الوجه',
      'forehead': 'الجبين',
      'cheeks': 'الخدين',
      'chin': 'الذقن',
    };

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.sectionHeader,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${scan.overallScore}%',
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.accent),
            ),
          ),
        ),
        title: Text(
          areaNames[scan.areaType] ?? 'فحص البشرة',
          style: AppTextStyles.titleMedium,
        ),
        subtitle: Text(
          _formatDate(scan.createdAt),
          style: AppTextStyles.bodySmall,
        ),
        trailing: Icon(Icons.chevron_left, color: AppColors.textLight),
        onTap: () => context.push('/skin-scan/results/${scan.id}'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'اليوم';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
