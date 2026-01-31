import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Floating capsule bottom navigation for Home (spec).
///
/// 5 icons: Profile, Wishlist, Center Scan, AI Chat (action), Home (active when index==0)
/// Tabs: Home (0), Wishlist (1), Profile (2)
class FloatingBottomNav extends StatelessWidget {
  final int currentIndex; // 0..2 (home, wishlist, profile)
  final ValueChanged<int> onTabSelected;
  final VoidCallback onScanPressed;
  final VoidCallback onAiPressed;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onScanPressed,
    required this.onAiPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78, // fixed nav height (pill only)
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pillWidth = (constraints.maxWidth * 0.82).clamp(280.0, 520.0);
            return ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 72,
                  width: pillWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bottomNavBackground.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 26,
                        spreadRadius: -8,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TabIcon(
                        icon: Icons.person,
                        outlinedIcon: Icons.person_outline,
                        index: 2,
                        currentIndex: currentIndex,
                        onTap: onTabSelected,
                      ),
                      _TabIcon(
                        icon: Icons.favorite,
                        outlinedIcon: Icons.favorite_border,
                        index: 1,
                        currentIndex: currentIndex,
                        onTap: onTabSelected,
                      ),
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
                              ),
                              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                            ),
                          ),
                        ),
                      ),
                      _ActionIcon(
                        icon: Icons.smart_toy_outlined,
                        onTap: onAiPressed,
                      ),
                      _TabIcon(
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
    );
  }
}

class _TabIcon extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabIcon({
    required this.icon,
    required this.outlinedIcon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = currentIndex == index;
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
                color: selected ? AppColors.primary : AppColors.iconTint,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

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
              child: Icon(icon, color: AppColors.iconTint, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

