import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../core/widgets/shine_primary_button.dart';
import '../../services/providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptedTerms) {
      setState(() {
        _error = 'يجب الموافقة على سياسة الخصوصية وشروط الاستخدام';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).signup(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );
      if (mounted) {
        context.go('/');
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
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          height: 86,
                          width: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.18),
                            border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.18),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome, size: 40, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'مرحباً بك في Shine',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textOffWhite,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أنشئ حسابك للحصول على أفضل تجربة تسوق',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.iconTint),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 18),
                      if (_error != null) ...[
                        _AuthError(text: _error!),
                        const SizedBox(height: 14),
                      ],
                      _AuthField(
                        controller: _fullNameController,
                        label: 'الاسم الكامل',
                        hint: 'اكتب اسمك',
                        icon: Icons.person_outlined,
                        textDirection: TextDirection.rtl,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء إدخال الاسم الكامل';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'example@email.com',
                        icon: Icons.email_outlined,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                          if (!value.contains('@')) return 'الرجاء إدخال بريد إلكتروني صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        hint: '07XX XXX XXXX',
                        icon: Icons.phone_outlined,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء إدخال رقم الهاتف';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _locationController,
                        label: 'الموقع / العنوان',
                        hint: 'المدينة / العنوان',
                        icon: Icons.location_on_outlined,
                        textDirection: TextDirection.rtl,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء إدخال الموقع';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        hint: '••••••••',
                        icon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.iconTint,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
                          if (value.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _confirmPasswordController,
                        label: 'تأكيد كلمة المرور',
                        hint: '••••••••',
                        icon: Icons.lock_outlined,
                        obscureText: _obscureConfirmPassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.iconTint,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
                          if (value != _passwordController.text) return 'كلمة المرور غير متطابقة';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                              activeColor: AppColors.primary,
                              side: BorderSide(color: AppColors.white.withValues(alpha: 0.22)),
                            ),
                            Expanded(
                              child: RichText(
                                textDirection: TextDirection.rtl,
                                text: TextSpan(
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
                                  children: [
                                    const TextSpan(text: 'أوافق على '),
                                    TextSpan(
                                      text: 'سياسة الخصوصية',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                                      recognizer: TapGestureRecognizer()..onTap = () => context.push('/privacy-policy'),
                                    ),
                                    const TextSpan(text: ' و '),
                                    TextSpan(
                                      text: 'شروط الاستخدام',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                                      recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ShinePrimaryButton(
                        label: 'إنشاء حساب',
                        leadingIcon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : null,
                        onPressed: _isLoading ? null : _signup,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'لديك حساب بالفعل؟ ',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.iconTint),
                          ),
                          TextButton(
                            onPressed: () => context.push('/login'),
                            child: Text(
                              'تسجيل الدخول',
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
        border: Border.all(color: const Color(0xFFE05A5A).withValues(alpha: 0.35)),
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
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.iconTint.withValues(alpha: 0.75)),
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
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.9), width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}
