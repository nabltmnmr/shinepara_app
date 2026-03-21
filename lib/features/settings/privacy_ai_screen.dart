import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/shine_strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../ai/services/ai_consent_service.dart';

class PrivacyAiScreen extends StatefulWidget {
  const PrivacyAiScreen({super.key});

  @override
  State<PrivacyAiScreen> createState() => _PrivacyAiScreenState();
}

class _PrivacyAiScreenState extends State<PrivacyAiScreen> {
  AiConsentStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await AiConsentService.getStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _withdrawConsent() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('withdraw_ai_consent')),
            content: const Text(
              'Withdrawing consent will stop AI-powered features until you consent again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  context.tr('withdraw_ai_consent'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    await AiConsentService.revokeConsent();
    await _loadStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI consent withdrawn. AI features are now disabled.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return ShineScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('privacy_ai'),
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('ai_consent_status'),
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              status?.given == true ? Icons.verified : Icons.info_outline,
                              color: status?.given == true
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status?.given == true
                                  ? context.tr('granted')
                                  : context.tr('not_granted'),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if ((status?.timestamp ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Consent time: ${status!.timestamp}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _Card(
                    child: _InfoBlock(
                      title: 'What data may be sent',
                      items: [
                        'photos uploaded for skin analysis',
                        'messages sent to the AI assistant',
                        'relevant profile and skin details needed for results',
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _Card(
                    child: _InfoBlock(
                      title: 'Why data is sent',
                      items: [
                        'to analyze skin images',
                        'to generate personalized recommendations',
                        'to provide AI assistant responses',
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _Card(
                    child: _InfoBlock(
                      title: 'AI providers',
                      items: [
                        'OpenAI',
                        'Shine AI processing backend (for skin analysis workflows)',
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Privacy links', style: AppTextStyles.titleMedium),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => _openLink('https://shine-care.com/privacy-policy'),
                          child: const Text('Privacy Policy'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _openLink('https://shine-care.com/privacy-choices'),
                          child: const Text('Privacy Choices'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: OutlinedButton.icon(
                      onPressed: _withdrawConsent,
                      icon: const Icon(Icons.block, color: AppColors.error),
                      label: Text(
                        context.tr('withdraw_ai_consent'),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final List<String> items;
  const _InfoBlock({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.textPrimary)),
                Expanded(
                  child: Text(
                    item,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
