import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Pill-shaped floating bottom navigation bar with a central scan action,
/// matching the Shine UI mockups.
class ShineBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onScanPressed;
  final VoidCallback onCartPressed;

  const ShineBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onScanPressed,
    required this.onCartPressed,
  });

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: This widget is used as Scaffold.bottomNavigationBar.
    // It MUST be height-bounded, otherwise it can consume the whole screen.
    //
    // This design matches the provided reference:
    // [profile] [wishlist] [scan] [cart] [home]
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: SizedBox(
          height: 92,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth * 0.92).clamp(300.0, 560.0);

                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: width,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarker.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.55),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Indices MUST match MainShell.pages:
                          // 0: Home, 1: Wishlist, 2: Profile
                          _NavItem(
                            icon: Icons.person,
                            outlinedIcon: Icons.person_outline,
                            index: 2,
                            currentIndex: currentIndex,
                            onTap: onTabSelected,
                          ),
                          _NavItem(
                            icon: Icons.favorite,
                            outlinedIcon: Icons.favorite_border,
                            index: 1,
                            currentIndex: currentIndex,
                            onTap: onTabSelected,
                          ),

                          // Center scan button (not a tab index)
                          SizedBox(
                            width: 74,
                            child: Center(
                              child: GestureDetector(
                                onTap: onScanPressed,
                                child: Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.65),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: AppColors.background,
                                      width: 4,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner,
                                    color: AppColors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          _ActionItem(
                            icon: Icons.shopping_bag_outlined,
                            onTap: onCartPressed,
                          ),
                          _NavItem(
                            icon: Icons.home,
                            outlinedIcon: Icons.home_outlined,
                            index: 0,
                            currentIndex: currentIndex,
                            onTap: onTabSelected,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withOpacity(0.22) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? icon : outlinedIcon,
                color: selected ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionItem({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: SizedBox(
              height: 42,
              width: 42,
              child: Center(
                child: Icon(
                  icon,
                  color: AppColors.textMuted,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

