import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/shine_strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_scaffold.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShineScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('account'),
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
          ),
          child: ListTile(
            onTap: () => context.push('/settings/account/delete'),
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              context.tr('delete_account'),
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
