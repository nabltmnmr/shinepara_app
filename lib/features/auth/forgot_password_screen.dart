import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/shine_strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_primary_button.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../services/providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _successMessage;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient
          .forgotPassword(email: _emailController.text.trim().toLowerCase());
      if (mounted) {
        setState(() {
          _codeSent = true;
          _successMessage = context.tr('code_sent_success');
        });
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

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = context.tr('passwords_dont_match');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.resetPassword(
        email: _emailController.text.trim().toLowerCase(),
        code: _codeController.text.trim(),
        newPassword: _passwordController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _successMessage = context.tr('password_reset_success');
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.pop();
        }
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
              child: _buildGlassCard(
                child: _codeSent ? _buildResetStep() : _buildEmailStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
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

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
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
                border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_reset, size: 44, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('forgot_password_title'),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textOffWhite,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('forgot_password_subtitle'),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.iconTint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            _buildErrorBox(_error!),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOffWhite),
            decoration: InputDecoration(
              labelText: context.tr('email'),
              labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
              hintText: 'example@email.com',
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.iconTint.withValues(alpha: 0.75)),
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
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
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  width: 1.6,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
              if (!value.contains('@')) return 'الرجاء إدخال بريد إلكتروني صحيح';
              return null;
            },
          ),
          const SizedBox(height: 18),
          ShinePrimaryButton(
            label: context.tr('send_code'),
            leadingIcon: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : null,
            onPressed: _isLoading ? null : _sendCode,
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                context.tr('back_to_login'),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
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
                border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: const Icon(Icons.pin, size: 44, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('enter_code_title'),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textOffWhite,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('enter_code_subtitle'),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.iconTint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('code_expires_in'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_successMessage != null) ...[
            _buildSuccessBox(_successMessage!),
            const SizedBox(height: 14),
          ],
          if (_error != null) ...[
            _buildErrorBox(_error!),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textOffWhite,
              letterSpacing: 12,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              labelText: context.tr('reset_code'),
              labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
              hintText: '------',
              hintStyle: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.iconTint.withValues(alpha: 0.4),
                letterSpacing: 12,
              ),
              prefixIcon: const Icon(Icons.dialpad, color: AppColors.primary),
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
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  width: 1.6,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'الرجاء إدخال الرمز';
              if (value.length != 6) return 'الرمز يجب أن يكون 6 أرقام';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOffWhite),
            decoration: InputDecoration(
              labelText: context.tr('new_password'),
              labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
              hintText: '••••••••',
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.iconTint.withValues(alpha: 0.75)),
              prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.iconTint,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
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
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  width: 1.6,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
              if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOffWhite),
            decoration: InputDecoration(
              labelText: context.tr('confirm_new_password'),
              labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
              hintText: '••••••••',
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.iconTint.withValues(alpha: 0.75)),
              prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.iconTint,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
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
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  width: 1.6,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
              return null;
            },
          ),
          const SizedBox(height: 18),
          ShinePrimaryButton(
            label: context.tr('reset_password'),
            leadingIcon: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : null,
            onPressed: _isLoading ? null : _resetPassword,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _sendCode,
              child: Text(
                context.tr('resend_code'),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _codeSent = false;
                  _error = null;
                  _successMessage = null;
                  _codeController.clear();
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                });
              },
              child: Text(
                context.tr('back_to_login'),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String text) {
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

  Widget _buildSuccessBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
