import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/shine_strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/navigation_utils.dart';
import '../../models/skin_scan.dart';
import '../../services/providers.dart';
import 'smart_capture_screen.dart';

class SkinScanHomeScreen extends ConsumerStatefulWidget {
  const SkinScanHomeScreen({super.key});

  @override
  ConsumerState<SkinScanHomeScreen> createState() => _SkinScanHomeScreenState();
}

class _SkinScanHomeScreenState extends ConsumerState<SkinScanHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<EmbeddedSmartCaptureSectionState> _captureKey =
      GlobalKey<EmbeddedSmartCaptureSectionState>();

  bool _captureVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final ctx = _captureKey.currentContext;
    if (ctx == null || !mounted) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final topLeft = box.localToGlobal(Offset.zero);
    final size = box.size;
    final viewportH = MediaQuery.of(context).size.height;

    // Visible if it intersects the viewport with a small buffer.
    const buffer = 140.0;
    final isVisible = topLeft.dy < (viewportH - buffer) &&
        (topLeft.dy + size.height) > buffer;

    if (isVisible == _captureVisible) return;
    _captureVisible = isVisible;

    if (isVisible) {
      _captureKey.currentState?.startIfNeeded();
    } else {
      _captureKey.currentState?.pauseIfNeeded();
    }
  }

  Future<void> _scrollToCapture() async {
    final ctx = _captureKey.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.0,
    );
    _captureKey.currentState?.startIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(scanCreditsProvider);
    final historyAsync = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(context.tr('skin_scan'), style: AppTextStyles.headlineSmall),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.safeGoBack(),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('scan_preview'),
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: EmbeddedSmartCaptureSection(
                  key: _captureKey,
                  onClose: () async {
                    // In embedded mode, close just scrolls back up slightly.
                    await _scrollController.animateTo(
                      (_scrollController.offset - 280).clamp(
                        0.0,
                        _scrollController.position.maxScrollExtent,
                      ),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildCreditsCard(creditsAsync, ref),
            const SizedBox(height: 20),
            _buildScrollToScanButton(context, creditsAsync),
            const SizedBox(height: 16),
            _buildFeatureHighlights(),
            const SizedBox(height: 24),
            _buildHistorySection(context, historyAsync, ref),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsCard(AsyncValue<ScanCredits> creditsAsync, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [
            AppColors.surfaceHighlight,
            AppColors.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                    context.tr('scan_credits'),
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
              Icon(Icons.face_retouching_natural, size: 60, color: AppColors.white.withValues(alpha: 0.8)),
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
      icon: Icon(Icons.share, color: AppColors.textPrimary),
      label: Builder(
        builder: (context) => Text(
          context.tr('share_reward'),
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.50)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildRewardClaimed() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Text(
            context.tr('reward_claimed_today'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollToScanButton(
      BuildContext context, AsyncValue<ScanCredits> creditsAsync) {
    final hasCredits = creditsAsync.when(
      data: (credits) => credits.credits > 0,
      loading: () => false,
      error: (_, __) => false,
    );

    return SizedBox(
      height: 54,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!hasCredits) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('scan_preview_notice'),
                    ),
                    backgroundColor: AppColors.aiAssistant,
                  ),
                );
              }
              _scrollToCapture();
            },
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.95),
                    AppColors.primaryLight.withValues(alpha: 0.95),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: AppColors.white),
                  SizedBox(width: 10),
                  Text(
                    hasCredits ? context.tr('start_scan') : context.tr('preview_scan'),
                    style: AppTextStyles.buttonText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights() {
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
              Icon(Icons.auto_awesome, color: AppColors.aiAssistant, size: 20),
              SizedBox(width: 8),
              Text(context.tr('ai_highlights_title'), style: AppTextStyles.titleSmall),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureChip(context.tr('feature_12_metrics')),
              _buildFeatureChip(context.tr('feature_analysis_images')),
              _buildFeatureChip(context.tr('feature_custom_routine')),
              _buildFeatureChip(context.tr('feature_progress_compare')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aiAssistant.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.aiAssistant),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, AsyncValue<List<SkinScan>> historyAsync, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('scan_history'), style: AppTextStyles.titleLarge),
            Row(
              children: [
                historyAsync.when(
                  data: (history) => history.length >= 2
                      ? TextButton.icon(
                          onPressed: () => context.push('/skin-scan/compare'),
                          icon: Icon(Icons.compare_arrows, color: AppColors.accent, size: 18),
                          label: Text(context.tr('compare'), style: TextStyle(color: AppColors.accent)),
                        )
                      : SizedBox.shrink(),
                  loading: () => SizedBox.shrink(),
                  error: (_, __) => SizedBox.shrink(),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.textLight),
                  onPressed: () => ref.invalidate(scanHistoryProvider),
                ),
              ],
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
            child: Text(context.tr('history_load_error')),
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
            context.tr('no_scans_yet'),
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
          ),
          Text(
            context.tr('start_first_scan'),
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, SkinScan scan) {
    final scoreColor = scan.overallScore >= 70
        ? AppColors.success
        : scan.overallScore >= 50
            ? Colors.orange
            : AppColors.error;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            color: scoreColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${scan.overallScore}%',
              style: AppTextStyles.titleSmall.copyWith(color: scoreColor),
            ),
          ),
        ),
        title: Text(
          context.tr('skin_scan_item_title'),
          style: AppTextStyles.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(scan.createdAt),
              style: AppTextStyles.bodySmall,
            ),
            if (scan.visualizations.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  context.trf('analysis_images_count', {
                    'count': '${scan.visualizations.length}',
                  }),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.aiAssistant),
                ),
              ),
          ],
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
