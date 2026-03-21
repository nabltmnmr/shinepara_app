import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/shine_strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_primary_button.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../services/providers.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _deleteWordController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _confirmChecked = false;
  bool _isDeleting = false;
  String? _error;

  bool get _canDelete =>
      _confirmChecked &&
      _deleteWordController.text.trim().toUpperCase() == 'DELETE' &&
      !_isDeleting;

  @override
  void dispose() {
    _deleteWordController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_canDelete) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteAccount(
        currentPassword: _passwordController.text.trim(),
      );

      await ref.read(authProvider.notifier).logout();
      ref.read(cartProvider.notifier).clearCart();
      ref.read(wishlistProvider.notifier).clearWishlist();
      ref.read(aiChatProvider.notifier).clearChat();
      ref.invalidate(scanHistoryProvider);
      ref.invalidate(savedRoutinesProvider);
      ref.invalidate(scanCreditsProvider);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Account deleted'),
          content: const Text(
            'Your account and associated app data were deleted successfully.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _error = _mapError(msg);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  String _mapError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('timeout') || lower.contains('مهلة')) {
      return 'The request timed out. Please try again.';
    }
    if (lower.contains('unauthorized') ||
        lower.contains('منتهية') ||
        lower.contains('401')) {
      return 'Your session expired. Please log in again and retry.';
    }
    if (lower.contains('recent') ||
        lower.contains('حديث') ||
        lower.contains('reauth')) {
      return 'Recent login is required. Enter your current password and try again.';
    }
    if (lower.contains('network') || lower.contains('الاتصال')) {
      return 'Network error. Check your connection and retry.';
    }
    if (lower.contains('partial')) {
      return 'Account deletion partially failed. Please retry or contact support.';
    }
    return raw.isEmpty ? 'Deletion failed. Please try again.' : raw;
  }

  @override
  Widget build(BuildContext context) {
    return ShineScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('delete_account_title'),
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                context.tr('delete_account_body'),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password (if required)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deleteWordController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _confirmChecked,
              onChanged: _isDeleting
                  ? null
                  : (v) => setState(() {
                        _confirmChecked = v ?? false;
                      }),
              title: const Text('I understand this action cannot be undone.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.40)),
                ),
                child: Text(
                  _error!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ShinePrimaryButton(
              label: context.tr('delete_my_account'),
              onPressed: _canDelete ? _deleteAccount : null,
              leadingIcon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_forever, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isDeleting ? null : () => context.pop(),
              child: Text(context.tr('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
