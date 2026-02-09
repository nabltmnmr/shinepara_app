import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// App splash screen matching the new Shine UI/UX (dark luxury palette).
///
/// This is intentionally a pure UI screen (no navigation logic), so it can be
/// used both during startup initialization and anywhere else if needed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.showLoader = true});

  final bool showLoader;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackground(),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Opacity(
                    opacity: _fade.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 118,
                            height: 118,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHighlight,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.accentGold.withAlpha(140),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(89),
                                  blurRadius: 22,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.spa,
                                size: 54,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Shine',
                            style: (textTheme.headlineLarge ??
                                    const TextStyle(fontSize: 36))
                                .copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (widget.showLoader) ...[
                            const SizedBox(height: 22),
                            const _DotsLoader(),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.surfaceLight,
            AppColors.background,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Soft glow to echo the primary accent without being loud.
          Align(
            alignment: const Alignment(0.85, -0.82),
            child: _GlowBlob(
              color: AppColors.primary.withAlpha(41),
              size: 240,
            ),
          ),
          Align(
            alignment: const Alignment(-0.95, 0.88),
            child: _GlowBlob(
              color: AppColors.accentGold.withAlpha(31),
              size: 280,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withAlpha(0),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader();

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        double dotScale(int index) {
          // three phase-shifted pulses
          final phase = (t + (index * 0.18)) % 1.0;
          final v = (1.0 - (2 * (phase - 0.5)).abs()).clamp(0.0, 1.0);
          return 0.72 + (v * 0.38);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: dotScale(i),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(230),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
