import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Gradient primary CTA button used across Shine screens.
class ShinePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const ShinePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[
                  leadingIcon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTextStyles.buttonText,
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  trailingIcon!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

