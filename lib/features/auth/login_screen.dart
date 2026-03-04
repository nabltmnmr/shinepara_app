import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../core/widgets/shine_primary_button.dart';
import '../../core/localization/shine_strings.dart';
import '../../services/providers.dart';
import '../../services/social_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim().toLowerCase(),
            _passwordController.text.trim(),
          );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await SocialAuthService.signInWithGoogle();
      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      await ref.read(authProvider.notifier).socialLogin(
            provider: result.provider,
            idToken: result.idToken,
            name: result.displayName,
          );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await SocialAuthService.signInWithApple();
      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      await ref.read(authProvider.notifier).socialLogin(
            provider: result.provider,
            idToken: result.idToken,
            name: result.displayName,
          );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShineScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: _AuthGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          height: 86,
                          width: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.18),
                            border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.10)),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.20),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person,
                              size: 44, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.tr('login_title'),
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textOffWhite,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('login_subtitle'),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.iconTint),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        _AuthError(text: _error!),
                        const SizedBox(height: 14),
                      ],
                      _AuthField(
                        controller: _emailController,
                        label: context.tr('email'),
                        hint: 'example@email.com',
                        icon: Icons.email_outlined,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'الرجاء إدخال البريد الإلكتروني';
                          if (!value.contains('@'))
                            return 'الرجاء إدخال بريد إلكتروني صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _passwordController,
                        label: context.tr('password'),
                        hint: '••••••••',
                        icon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.iconTint,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'الرجاء إدخال كلمة المرور';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      ShinePrimaryButton(
                        label: context.tr('login'),
                        leadingIcon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : null,
                        onPressed: _isLoading ? null : _login,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'أو',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.iconTint,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SocialButton(
                        label: 'تسجيل الدخول بحساب Google',
                        fallbackIcon: Icons.g_mobiledata,
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                      ),
                      if (!kIsWeb) ...[
                        const SizedBox(height: 10),
                        _SocialButton(
                          label: 'تسجيل الدخول بحساب Apple',
                          fallbackIcon: Icons.apple,
                          onPressed: _isLoading ? null : _handleAppleSignIn,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${context.tr('no_account')} ',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.iconTint),
                          ),
                          TextButton(
                            onPressed: () => context.push('/signup'),
                            child: Text(
                              context.tr('create_account'),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthGlassCard extends StatelessWidget {
  final Widget child;
  const _AuthGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.bottomNavBackground.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  final String text;
  const _AuthError({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE05A5A).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFE05A5A).withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textOffWhite),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextDirection textDirection;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.textDirection = TextDirection.rtl,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textDirection: textDirection,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOffWhite),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.iconTint.withValues(alpha: 0.75)),
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: AppColors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.9), width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String? iconPath;
  final IconData fallbackIcon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    this.iconPath,
    required this.fallbackIcon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (iconPath != null) {
      iconWidget = Image.asset(
        iconPath!,
        width: 22,
        height: 22,
        errorBuilder: (_, __, ___) => Icon(
          fallbackIcon,
          color: AppColors.textOffWhite,
          size: 24,
        ),
      );
    } else {
      iconWidget = Icon(
        fallbackIcon,
        color: AppColors.textOffWhite,
        size: 24,
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.15)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.black.withValues(alpha: 0.18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOffWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
