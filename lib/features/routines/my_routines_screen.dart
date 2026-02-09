import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/localization/shine_strings.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../core/widgets/shine_glass_panel.dart';
import '../../core/widgets/shine_primary_button.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/providers.dart';
import '../../services/api_client.dart';

class MyRoutinesScreen extends ConsumerWidget {
  const MyRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(savedRoutinesProvider);
    final historyAsync = ref.watch(scanHistoryProvider);

    return ShineScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('my_routines'),
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.safeGoBack(),
        ),
      ),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return _buildEmptyState(context, ref, historyAsync);
          }
          return _buildRoutinesList(context, ref, routines, historyAsync);
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
          child: Text(
            'حدث خطأ في تحميل الروتينات',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, AsyncValue historyAsync) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGold.withOpacity(0.12),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
              ),
              child: Icon(Icons.spa_outlined, size: 40, color: AppColors.accentGold),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('no_routines_yet'),
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('no_routines_subtitle'),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ShinePrimaryButton(
              label: context.tr('start_skin_scan'),
              onPressed: () => context.push('/skin-scan'),
            ),
            const SizedBox(height: 12),
            historyAsync.whenOrNull(
              data: (history) {
                if (history is List && (history as List).isNotEmpty) {
                  return OutlinedButton.icon(
                    onPressed: () => context.push('/skin-scan/results/${(history as List).first.id}'),
                    icon: Icon(Icons.auto_awesome, color: AppColors.primary),
                    label: Text(context.tr('create_routine'), style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ) ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutinesList(BuildContext context, WidgetRef ref, List<SavedRoutine> routines, AsyncValue historyAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ShinePrimaryButton(
                  label: context.tr('start_skin_scan'),
                  onPressed: () => context.push('/skin-scan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          historyAsync.whenOrNull(
            data: (history) {
              if (history is List && (history as List).isNotEmpty) {
                return OutlinedButton.icon(
                  onPressed: () => context.push('/skin-scan/results/${(history as List).first.id}'),
                  icon: Icon(Icons.auto_awesome, color: AppColors.primary),
                  label: Text(context.tr('create_routine'), style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ) ?? const SizedBox.shrink(),
          const SizedBox(height: 24),
          ...routines.map((routine) => _buildRoutineCard(context, ref, routine)),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, WidgetRef ref, SavedRoutine routine) {
    final dateStr = '${routine.createdAt.day}/${routine.createdAt.month}/${routine.createdAt.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ShineGlassPanel(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa, color: AppColors.accentGold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    routine.title,
                    style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _confirmDelete(context, ref, routine),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${context.tr('saved_on')}: $dateStr',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              routine.routineText,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SavedRoutine routine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(context.tr('delete_routine'), style: TextStyle(color: AppColors.textPrimary)),
        content: Text(context.tr('delete_routine_confirm'), style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel'), style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final apiClient = ref.read(apiClientProvider);
                await apiClient.deleteRoutine(routine.id);
                ref.invalidate(savedRoutinesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('routine_deleted')), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(context.tr('delete'), style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
