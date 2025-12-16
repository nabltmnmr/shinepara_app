import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/navigation_utils.dart';
import '../../models/ai_recommendation.dart';
import '../../services/providers.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _quickChips = [
    'حب الشباب',
    'البشرة الدهنية',
    'التصبغات',
    'البشرة الجافة',
    'العناية اليومية',
    'روتين صباحي',
    'تساقط الشعر',
  ];

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مساعد Shine الذكي', style: AppTextStyles.titleLarge),
            SizedBox(width: 8),
            Icon(Icons.auto_awesome, color: AppColors.aiAssistant, size: 20),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.safeGoBack(),
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.textPrimary),
              onPressed: () {
                ref.read(aiChatProvider.notifier).clearChat();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.aiAssistantLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.aiAssistant, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هذه التوصيات مبنية على معلومات عامة عن المنتجات ولا تغني عن استشارة طبيب الجلدية',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.aiAssistant),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(messages[index]);
                    },
                  ),
          ),
          _buildQuickChips(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.aiAssistantLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: AppColors.aiAssistant, size: 48),
            ),
            SizedBox(height: 24),
            Text(
              'مرحباً! أنا مساعدك الذكي',
              style: AppTextStyles.titleLarge,
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 8),
            Text(
              'أخبرني عن نوع بشرتك ومشاكلك وسأساعدك في اختيار المنتجات المناسبة',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'مثال: "بشرتي دهنية وعندي حب شباب، ما هو أفضل روتين؟"',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.aiAssistant,
                fontStyle: FontStyle.italic,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser ? AppColors.userMessage : AppColors.aiMessage,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: isUser ? Radius.zero : Radius.circular(16),
                bottomRight: isUser ? Radius.circular(16) : Radius.zero,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'مساعد Shine',
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.aiAssistant),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.auto_awesome, color: AppColors.aiAssistant, size: 14),
                      ],
                    ),
                  ),
                Text(
                  message.content,
                  style: AppTextStyles.bodyMedium,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          if (message.recommendations != null && message.recommendations!.isNotEmpty) ...[
            SizedBox(height: 12),
            ...message.recommendations!.map((rec) => _buildRecommendationCard(rec)),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(AIRecommendation recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () => context.push('/product/${recommendation.productId}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text('عرض المنتج', style: AppTextStyles.labelSmall.copyWith(color: AppColors.white)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  recommendation.productName,
                  style: AppTextStyles.titleSmall,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  recommendation.brand,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  recommendation.reason,
                  style: AppTextStyles.bodySmall,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          if (recommendation.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: recommendation.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppColors.divider),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.divider,
                  child: Icon(Icons.image, color: AppColors.textLight),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.aiMessage,
            borderRadius: BorderRadius.circular(16).copyWith(bottomRight: Radius.zero),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.aiAssistant,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'جاري التفكير...',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.aiAssistant),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        reverse: true,
        itemCount: _quickChips.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: 8),
            child: ActionChip(
              label: Text(_quickChips[index], style: AppTextStyles.labelSmall),
              backgroundColor: AppColors.sectionHeader,
              onPressed: () => _sendMessage(_quickChips[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.send, color: AppColors.primary),
              onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'اسأل عن منتجات العناية...',
                  hintTextDirection: TextDirection.rtl,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
