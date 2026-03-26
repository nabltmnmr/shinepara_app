import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../core/widgets/shine_glass_panel.dart';
import '../../core/widgets/shine_primary_button.dart';
import '../../models/skin_scan.dart';
import '../../models/product.dart';
import '../../services/providers.dart';
import '../../services/api_client.dart';
import '../ai/services/ai_consent_service.dart';

class ScanResultsScreen extends ConsumerStatefulWidget {
  final int scanId;

  const ScanResultsScreen({super.key, required this.scanId});

  @override
  ConsumerState<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends ConsumerState<ScanResultsScreen> {
  double _selectedBudget = 50000;
  bool _isGeneratingRoutine = false;
  String? _generatedRoutine;
  List<ScanRecommendedProduct> _routineRecommendedProducts = const [];

  @override
  Widget build(BuildContext context) {
    final scanAsync = ref.watch(skinScanProvider(widget.scanId));

    return ShineScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'نتائج الفحص',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.go('/skin-scan'),
        ),
      ),
      body: scanAsync.when(
        data: (scan) => scan != null
            ? _buildResults(scan)
            : Center(
                child: Text(
                  'الفحص غير موجود',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
              ),
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(
          child: Text(
            'حدث خطأ في تحميل النتائج',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(SkinScan scan) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOverallScoreCard(scan),
          SizedBox(height: 20),
          _buildVisualizationGrid(scan),
          SizedBox(height: 20),
          if (scan.summary != null) _buildSummaryCard(scan.summary!),
          SizedBox(height: 20),
          _buildRoutineSection(scan),
          if ((_routineRecommendedProducts.isNotEmpty || scan.recommendedProducts.isNotEmpty)) ...[
            SizedBox(height: 20),
            _buildRecommendedProducts(
              _routineRecommendedProducts.isNotEmpty
                  ? _routineRecommendedProducts
                  : scan.recommendedProducts,
            ),
          ],
          SizedBox(height: 16),
          _buildDisclaimerBanner(),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard(SkinScan scan) {
    final score = scan.overallScore;
    final scoreColor = score >= 70
        ? AppColors.success
        : score >= 50
            ? Colors.orange
            : AppColors.error;

    return ShineGlassPanel(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Text(
            'النتيجة الإجمالية',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: AppColors.divider,
                  color: scoreColor,
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score%',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: scoreColor,
                      fontSize: 36,
                    ),
                  ),
                  Text(
                    _getScoreLabel(score),
                    style: AppTextStyles.bodySmall.copyWith(color: scoreColor),
                  ),
                ],
              ),
            ],
          ),
          if (scan.qualityScore != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.high_quality, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'جودة الصورة: ${(scan.qualityScore! * 100).toInt()}%',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'ممتاز';
    if (score >= 70) return 'جيد جداً';
    if (score >= 60) return 'جيد';
    if (score >= 50) return 'مقبول';
    return 'يحتاج عناية';
  }

  Widget _buildVisualizationGrid(SkinScan scan) {
    final baseUrl = ApiClient.getBaseUrl();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تحليل مفصل (12 مؤشر)',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: SkinScan.metricKeys.length,
          itemBuilder: (context, index) {
            final key = SkinScan.metricKeys[index];
            final viz = scan.visualizations[key];
            final metric = scan.metricDetails[key];
            final value = metric?.value ?? scan.getMetricValue(key);
            final nameAr = metric?.nameAr ?? SkinScan.metricNamesAr[key] ?? key;
            final isEstimated = metric?.isEstimated ?? false;

            return GestureDetector(
              onTap: () => _showMetricDetail(context, key, scan),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        child: (viz != null && viz!.imageUrl.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: '$baseUrl${viz!.imageUrl}',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (_, __) => _buildMetricPlaceholder(key, 100 - value),
                                errorWidget: (_, __, ___) => _buildMetricPlaceholder(key, 100 - value),
                              )
                            : _buildMetricPlaceholder(key, 100 - value),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Text(
                            nameAr,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${100 - value}%',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: _getScoreColor(100 - value),
                                  fontSize: 12,
                                ),
                              ),
                              if (isEstimated) ...[
                                const SizedBox(width: 2),
                                Icon(Icons.info_outline, size: 10, color: AppColors.textMuted),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricPlaceholder(String metricKey, int healthScore) {
    final color = _getScoreColor(healthScore);
    final icon = _getMetricIcon(metricKey);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color.withOpacity(0.6)),
            const SizedBox(height: 4),
            Text(
              '$healthScore%',
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMetricIcon(String key) {
    switch (key) {
      case 'rgb_pores': return Icons.blur_on;
      case 'rgb_color_spot': return Icons.palette_outlined;
      case 'rgb_texture': return Icons.texture;
      case 'pl_roughness': return Icons.terrain;
      case 'uv_acne': return Icons.circle_outlined;
      case 'uv_color_spot': return Icons.contrast;
      case 'uv_roughness': return Icons.waves;
      case 'skin_evenness': return Icons.equalizer;
      case 'brown_area': return Icons.brightness_6;
      case 'uv_spot': return Icons.wb_sunny_outlined;
      case 'skin_aging': return Icons.access_time;
      case 'skin_brightness': return Icons.light_mode;
      default: return Icons.analytics;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 50) return Colors.orange;
    return AppColors.error;
  }

  void _showMetricDetail(BuildContext context, String key, SkinScan scan) {
    final metric = scan.metricDetails[key];
    final viz = scan.visualizations[key];
    final value = metric?.value ?? scan.getMetricValue(key);
    final nameAr = metric?.nameAr ?? SkinScan.metricNamesAr[key] ?? key;
    final description = metric?.description ?? viz?.description ?? '';
    final tips = metric?.tips ?? viz?.tips ?? '';
    final isEstimated = metric?.isEstimated ?? false;
    final baseUrl = ApiClient.getBaseUrl();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (viz?.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: '$baseUrl${viz!.imageUrl}',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(nameAr, style: AppTextStyles.titleLarge),
                          if (isEstimated) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.aiAssistantLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'تقديري',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.aiAssistant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'النتيجة: ',
                            style: AppTextStyles.bodyMedium,
                          ),
                          Text(
                            '${100 - value}%',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: _getScoreColor(100 - value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (description.isNotEmpty) ...[
              Text('الوصف', style: AppTextStyles.titleSmall),
              SizedBox(height: 8),
              Text(description, style: AppTextStyles.bodyMedium),
              SizedBox(height: 16),
            ],
            if (tips.isNotEmpty) ...[
              Text('نصائح للتحسين', style: AppTextStyles.titleSmall),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.aiAssistantLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.aiAssistant, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text(tips, style: AppTextStyles.bodySmall)),
                  ],
                ),
              ),
            ],
            if (isEstimated) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تقدير من صورة RGB. ليس تشخيصاً طبياً.',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return ShineGlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.accentGold),
              const SizedBox(width: 8),
              Text(
                'ملخص التحليل',
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'تقدير من صورة RGB. ليس تشخيصاً طبياً. راجع طبيب جلدية للحالات الشديدة.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSection(SkinScan scan) {
    if (scan.routine != null && _generatedRoutine == null) {
      _generatedRoutine = scan.routine;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'روتين العناية المقترح',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (_generatedRoutine != null)
          _buildRoutineCard(_generatedRoutine!)
        else
          _buildRoutineGenerator(scan),
      ],
    );
  }

  Widget _buildRoutineGenerator(SkinScan scan) {
    return ShineGlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'حدد ميزانيتك الشهرية للعناية بالبشرة',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('25,000 د.ع', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text(
                '${_selectedBudget.toInt().toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (m) => '${m[1]},'
                )} د.ع',
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
              ),
              Text('200,000 د.ع', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          Slider(
            value: _selectedBudget,
            min: 25000,
            max: 200000,
            divisions: 7,
            activeColor: AppColors.primary,
            onChanged: (value) => setState(() => _selectedBudget = value),
          ),
          const SizedBox(height: 16),
          ShinePrimaryButton(
            label: _isGeneratingRoutine ? 'جاري إنشاء الروتين...' : 'إنشاء روتين مخصص',
            leadingIcon: _isGeneratingRoutine
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                  )
                : null,
            onPressed: _isGeneratingRoutine ? null : () => _generateRoutine(scan.id),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(String routine) {
    return ShineGlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'روتينك المخصص',
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            routine,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ShinePrimaryButton(
                  label: 'حفظ الروتين',
                  onPressed: () => _saveRoutine(routine),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _generatedRoutine = null),
                icon: Icon(Icons.refresh, color: AppColors.primary),
                label: Text('إنشاء جديد', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedProducts(List<ScanRecommendedProduct> products) {
    final baseUrl = ApiClient.getBaseUrl();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'منتجات مقترحة لبشرتك',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _routineRecommendedProducts.isNotEmpty
              ? 'بناءً على ميزانيتك والروتين المُنشأ'
              : 'بناءً على نتائج فحصك',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              final imgSrc = product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? (product.imageUrl!.startsWith('http')
                      ? product.imageUrl!
                      : '$baseUrl${product.imageUrl}')
                  : null;
              
              return GestureDetector(
                onTap: () => context.push('/product/${product.id}'),
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          color: AppColors.sectionHeader,
                          child: imgSrc != null
                              ? CachedNetworkImage(
                                  imageUrl: imgSrc,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Center(
                                    child: Icon(Icons.shopping_bag_outlined, color: AppColors.textMuted, size: 32),
                                  ),
                                )
                              : Center(
                                  child: Icon(Icons.shopping_bag_outlined, color: AppColors.textMuted, size: 32),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.brandName != null)
                                Text(
                                  product.brandName!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 2),
                              Expanded(
                                child: Text(
                                  product.nameAr,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 10,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              Text(
                                '${product.price.toStringAsFixed(0)} د.ع',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.w700,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  final cartNotifier =
                                      ref.read(cartProvider.notifier);
                                  cartNotifier.addToCart(
                                    Product(
                                      id: product.id,
                                      nameAr: product.nameAr,
                                      nameEn: product.nameEn ?? product.nameAr,
                                      brandId: 0,
                                      categoryId: '',
                                      brandName: product.brandName,
                                      descriptionAr:
                                          product.shortDescription ?? '',
                                      descriptionEn:
                                          product.shortDescription ?? '',
                                      price: product.price,
                                      imageUrl: product.imageUrl,
                                    ),
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'تمت إضافة ${product.nameAr} إلى السلة'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_shopping_cart,
                                          size: 12, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'أضف للسلة',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveRoutine(String routineText) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.saveRoutine(
        title: 'روتين فحص #${widget.scanId}',
        routineText: routineText,
        scanId: widget.scanId,
      );
      ref.invalidate(savedRoutinesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الروتين بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في حفظ الروتين'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _generateRoutine(int scanId) async {
    final allowed = await AiConsentService.ensureAiConsent(context);
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI action cancelled: consent not granted.')),
        );
      }
      return;
    }

    setState(() => _isGeneratingRoutine = true);

    try {
      final result = await ref.read(skinScanServiceProvider).generateRoutine(
        scanId: scanId,
        budget: _selectedBudget,
      );
      if (mounted) {
        setState(() {
          _generatedRoutine = result.routine;
          _routineRecommendedProducts = result.recommendedProducts;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorText = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText.isEmpty ? 'حدث خطأ في إنشاء الروتين' : errorText),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingRoutine = false);
      }
    }
  }
}
