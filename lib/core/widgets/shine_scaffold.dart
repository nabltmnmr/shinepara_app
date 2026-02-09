import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';

/// Base page shell for Shine screens.
///
/// Renders the dark background, soft blurred gradient blobs, and an optional
/// floating bottom navigation bar area.
class ShineScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final SystemUiOverlayStyle? systemUiOverlayStyle;

  const ShineScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.systemUiOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final overlay = systemUiOverlayStyle ??
        SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar,
        body: Stack(
          children: [
            // Background gradients (fills into notch when extendBodyBehindAppBar=true)
            const Positioned(
              top: -120,
              right: -120,
              child: _GlowCircle(
                size: 320,
                color: AppColors.primary,
                opacity: 0.12,
              ),
            ),
            const Positioned(
              bottom: 80,
              left: -120,
              child: _GlowCircle(
                size: 260,
                color: AppColors.primary,
                opacity: 0.08,
              ),
            ),
            // Content
            Positioned.fill(
              child: body,
            ),
          ],
        ),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 120,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

