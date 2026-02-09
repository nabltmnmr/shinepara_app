import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Custom seamless app bar for Shine (Home spec).
///
/// - Height: 60
/// - Background: same as page background (no shadow/divider)
/// - Left group: Shine + search
/// - Right group: cart + notifications (notifications at far right)
/// - Badge: only shown when notificationsCount > 0
class ShineAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int notificationsCount;
  final int cartCount;
  final VoidCallback onTapNotifications;
  final VoidCallback onTapCart;
  final VoidCallback onTapSearch;

  const ShineAppBar({
    super.key,
    required this.notificationsCount,
    required this.cartCount,
    required this.onTapNotifications,
    required this.onTapCart,
    required this.onTapSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.appBarBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        children: [
          Text(
            'Shine',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 10),
          _IconButtonWithBadge(
            icon: Icons.search_outlined,
            color: AppColors.iconTint,
            onTap: onTapSearch,
          ),
          const Spacer(),
          _IconButtonWithBadge(
            icon: Icons.shopping_bag_outlined,
            color: AppColors.iconTint,
            badgeText: cartCount > 0 ? cartCount.toString() : null,
            onTap: onTapCart,
            // Cart badge is typically optional; keep it subtle.
            badgeColor: AppColors.primary.withOpacity(0.9),
          ),
          const SizedBox(width: 10),
          _IconButtonWithBadge(
            icon: Icons.notifications_none,
            color: AppColors.iconTint,
            badgeText: notificationsCount > 0 ? notificationsCount.toString() : null,
            onTap: onTapNotifications,
          ),
        ],
      ),
    );
  }
}

class _IconButtonWithBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badgeText;
  final Color badgeColor;

  const _IconButtonWithBadge({
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeText,
    this.badgeColor = const Color(0xFFE84A2C),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          children: [
            Center(child: Icon(icon, color: color, size: 28)),
            if (badgeText != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      badgeText!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontSize: 8,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

