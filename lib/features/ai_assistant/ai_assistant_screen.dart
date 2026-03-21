import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/localization/shine_strings.dart';
import '../../models/ai_recommendation.dart';
import '../../models/product.dart';
import '../../services/providers.dart';
import '../ai/services/ai_consent_service.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  List<String> _quickChips(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ar') {
      return const [
        'مساعدة لحب الشباب',
        'اقترح سيروم',
        'ما نوع بشرتي؟',
      ];
    }
    return const [
      'Help with acne', // intentionally partially visible
      'Recommend a serum',
      'What is my skin type',
    ];
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final allowed = await AiConsentService.ensureAiConsent(context);
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI action cancelled: consent not granted.')),
      );
      return;
    }

    _textController.clear();
    setState(() => _isLoading = true);

    await ref.read(aiChatProvider.notifier).sendMessage(message);

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiChatProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // We manage keyboard insets manually to avoid overflow.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Match Home background exactly.
          const Positioned.fill(child: ColoredBox(color: AppColors.background)),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      _ChatHeader(
                        onTapMore: () => _showMoreSheet(context, messages.isNotEmpty),
                        onTapBack: () => context.safeGoBack(),
                        onTapAssistantIcon: () {},
                      ),
                      Expanded(
                        child: messages.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 170),
                                itemCount: 1 + messages.length + (_isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return _DatePill(text: context.tr('today'));
                                  }

                                  final msgIndex = index - 1;
                                  if (_isLoading && msgIndex == messages.length) {
                                    return _buildTypingIndicator();
                                  }
                                  return _ChatMessageRow(message: messages[msgIndex]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuickChips(),
                          _buildInputArea(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreSheet(BuildContext context, bool canClear) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBottomPanel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 46,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                _SheetAction(
                  icon: Icons.refresh,
                  label: context.tr('ai_clear_chat'),
                  onTap: canClear
                      ? () {
                          Navigator.pop(context);
                          ref.read(aiChatProvider.notifier).clearChat();
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Container(
              height: 74,
              width: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.18),
                border: Border.all(color: AppColors.white.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.20),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('ai_title'),
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('ai_subtitle'),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('ai_example'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.aiAssistant,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '…',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    final chips = _quickChips(context);
    return SizedBox(
      height: 54,
      child: Transform.translate(
        offset: const Offset(-20, 0), // partial chip peeking offscreen (left)
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final text = chips[index];
            final highlighted = index == 2;
            return GestureDetector(
              onTap: () => _sendMessage(text),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: highlighted ? AppColors.primary.withOpacity(0.70) : AppColors.white.withOpacity(0.08),
                    width: highlighted ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  text,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textOffWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(_textController.text),
            child: Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.45),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              // Flip direction to match the reference.
              child: Transform.rotate(
                angle: math.pi,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          enabled: !_isLoading,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOffWhite),
                          decoration: InputDecoration(
                            hintText: context.tr('ai_subtitle'),
                            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.iconTint),
                            border: InputBorder.none,
                          ),
                          // Allow Arabic input comfortably (emulator keyboard may still vary).
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          onSubmitted: _isLoading ? null : _sendMessage,
                        ),
                      ),
                      Icon(Icons.image_outlined, color: AppColors.iconTint, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final VoidCallback onTapMore;
  final VoidCallback onTapBack;
  final VoidCallback onTapAssistantIcon;

  const _ChatHeader({
    required this.onTapMore,
    required this.onTapBack,
    required this.onTapAssistantIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onTapMore,
                icon: const Icon(Icons.more_vert, color: AppColors.white, size: 22),
              ),
              const Spacer(),
              IconButton(
                onPressed: onTapBack,
                icon: const Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.tr('ai_title'),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onTapAssistantIcon,
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A1A16),
                    border: Border.all(color: AppColors.white.withOpacity(0.10)),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Online',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
              ),
              const SizedBox(width: 8),
              _Dot(color: AppColors.primary),
              const SizedBox(width: 6),
              const _Dot(color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      width: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String text;
  const _DatePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.white.withOpacity(0.06)),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
          ),
        ),
      ),
    );
  }
}

class _ChatMessageRow extends StatelessWidget {
  final ChatMessage message;
  const _ChatMessageRow({required this.message});

  static final _rtlRegex = RegExp(r'[\u0600-\u06FF]');

  bool _isRtl(String s) => _rtlRegex.hasMatch(s);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final rtl = _isRtl(message.content);

    final bubbleMaxWidth = MediaQuery.of(context).size.width * 0.78;
    final bubble = _Bubble(
      isUser: isUser,
      maxWidth: bubbleMaxWidth,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      content: message.content,
      timestamp: message.timestamp,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: isUser
                ? Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: bubble,
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 52),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        bubble,
                        Positioned(
                          right: -18,
                          top: 18,
                          child: _InlineAssistantAction(),
                        ),
                      ],
                    ),
                  ),
          ),
          if (!isUser && (message.recommendations?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(right: 52),
                child: _RecommendationProductsRow(recs: message.recommendations!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool isUser;
  final double maxWidth;
  final TextDirection textDirection;
  final String content;
  final DateTime timestamp;

  const _Bubble({
    required this.isUser,
    required this.maxWidth,
    required this.textDirection,
    required this.content,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? AppColors.aiAssistantUser : AppColors.aiAssistant;
    final radius = BorderRadius.circular(26);
    final time = TimeOfDay.fromDateTime(timestamp).format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            border: Border.all(color: AppColors.white.withOpacity(0.06)),
          ),
          child: _HighlightedText(content: content, textDirection: textDirection, isUser: isUser),
        ),
        if (isUser) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              'Read $time',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ],
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String content;
  final TextDirection textDirection;
  final bool isUser;

  const _HighlightedText({
    required this.content,
    required this.textDirection,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    // Highlight only "Hyaluronic Acid" (case-insensitive) in assistant messages.
    if (!isUser) {
      final match = RegExp(r'Hyaluronic Acid', caseSensitive: false).firstMatch(content);
      if (match != null) {
        final before = content.substring(0, match.start);
        final mid = content.substring(match.start, match.end);
        final after = content.substring(match.end);
        return RichText(
          textDirection: textDirection,
          text: TextSpan(
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, height: 1.35),
            children: [
              TextSpan(text: before),
              TextSpan(
                text: mid,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(text: after),
            ],
          ),
        );
      }
    }

    return Text(
      content,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, height: 1.35),
      textDirection: textDirection,
      textAlign: textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left,
    );
  }
}

class _InlineAssistantAction extends StatelessWidget {
  const _InlineAssistantAction();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB56BFF),
            Color(0xFFFF5AA5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5AA5).withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
    );
  }
}

class _RecommendationProductsRow extends ConsumerWidget {
  final List<AIRecommendation> recs;
  const _RecommendationProductsRow({required this.recs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = recs.take(2).toList();
    final productsAsync = ref.watch(productsProvider(ProductFilter()));

    return productsAsync.when(
      loading: () => Row(
        children: const [
          Expanded(child: _RecPlaceholder()),
          SizedBox(width: 12),
          Expanded(child: _RecPlaceholder()),
        ],
      ),
      error: (_, __) => Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _RecFallbackImage(rec: items[i])),
            if (i == 0) const SizedBox(width: 12),
          ],
        ],
      ),
      data: (products) {
        return Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(
                child: _RecProductCard(
                  rec: items[i],
                  product: _resolveProduct(products, items[i]),
                ),
              ),
              if (i == 0) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Product? _resolveProduct(List<Product> products, AIRecommendation rec) {
    final id = int.tryParse(rec.productId);
    if (id == null) return null;
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class _RecProductCard extends StatelessWidget {
  final AIRecommendation rec;
  final Product? product;
  const _RecProductCard({required this.rec, required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final imageUrl = p?.imageUrl?.trim() ?? rec.imageUrl?.trim() ?? '';
    final productId = p?.id ?? int.tryParse(rec.productId);

    return GestureDetector(
      onTap: productId == null ? null : () => context.push('/product/$productId'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 118,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.16),
            border: Border.all(color: AppColors.white.withOpacity(0.06)),
          ),
          child: imageUrl.isEmpty
              ? const Center(child: Icon(Icons.image, color: AppColors.iconTint))
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.black.withOpacity(0.16)),
                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image, color: AppColors.iconTint)),
                ),
        ),
      ),
    );
  }
}

class _RecFallbackImage extends StatelessWidget {
  final AIRecommendation rec;
  const _RecFallbackImage({required this.rec});

  @override
  Widget build(BuildContext context) {
    final url = (rec.imageUrl ?? '').trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.16),
          border: Border.all(color: AppColors.white.withOpacity(0.06)),
        ),
        child: url.isEmpty
            ? const Center(child: Icon(Icons.image, color: AppColors.iconTint))
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.black.withOpacity(0.16)),
                errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image, color: AppColors.iconTint)),
              ),
      ),
    );
  }
}

class _RecPlaceholder extends StatelessWidget {
  const _RecPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.14),
          border: Border.all(color: AppColors.white.withOpacity(0.06)),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accentGold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
