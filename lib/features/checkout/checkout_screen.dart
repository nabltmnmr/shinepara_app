import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/widgets/shine_scaffold.dart';
import '../../core/widgets/shine_glass_panel.dart';
import '../../core/widgets/shine_primary_button.dart';
import '../../services/providers.dart';
import 'package:intl/intl.dart' hide TextDirection;

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();
  bool _isProcessing = false;
  bool _isValidatingCoupon = false;
  String? _error;
  String? _couponError;
  String? _appliedCoupon;
  double _couponDiscount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
    });
  }

  void _prefillUserData() {
    final user = ref.read(authProvider);
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _locationController.text = user.location ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponError = 'يرجى إدخال كود الخصم';
      });
      return;
    }

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final result = await apiClient.validateCoupon(code, cartNotifier.totalPrice);
      
      setState(() {
        _appliedCoupon = result['code'];
        _couponDiscount = (result['discount'] as num).toDouble();
        _couponError = null;
      });
    } catch (e) {
      setState(() {
        _couponError = e.toString().replaceAll('Exception: ', '');
        _appliedCoupon = null;
        _couponDiscount = 0;
      });
    } finally {
      setState(() {
        _isValidatingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponDiscount = 0;
      _couponController.clear();
      _couponError = null;
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final cartItems = ref.read(cartProvider);
      final apiClient = ref.read(apiClientProvider);
      
      final items = cartItems.map((item) => {
        'productId': item.productId,
        'quantity': item.quantity,
      }).toList();

      await apiClient.placeOrder(
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        customerLocation: _locationController.text.trim(),
        items: items,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        couponCode: _appliedCoupon,
      );

      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: AppColors.success, size: 64),
                ),
                const SizedBox(height: 20),
                Text(
                  'تم إرسال طلبك بنجاح!',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(
                  'سنتواصل معك قريباً لتأكيد الطلب',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_outlined, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'الدفع عند الاستلام',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
                child: Text('متابعة التسوق', style: TextStyle(color: AppColors.primary)),
              ),
              if (ref.read(authProvider) != null)
                ShinePrimaryButton(
                  label: 'عرض طلباتي',
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/orders');
                  },
                ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final shippingSettings = ref.watch(shippingSettingsProvider);
    final formatter = NumberFormat('#,###', 'ar');

    if (cartItems.isEmpty) {
      return ShineScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('إتمام الطلب', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary)),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => context.safeGoBack(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('السلة فارغة', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'أضف منتجات للسلة لإتمام الطلب',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 24),
              ShinePrimaryButton(
                label: 'تسوق الآن',
                leadingIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.white, size: 22),
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      );
    }

    return ShineScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('إتمام الطلب', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.safeGoBack(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildSectionCard(
                title: 'كود الخصم',
                icon: Icons.local_offer_outlined,
                child: Column(
                  children: [
                    if (_appliedCoupon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تم تطبيق الكود: $_appliedCoupon',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                            TextButton(
                              onPressed: _removeCoupon,
                              child: Text('إزالة', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _couponController,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'أدخل كود الخصم',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                filled: true,
                                fillColor: AppColors.surfaceDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.divider),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ShinePrimaryButton(
                            label: 'تطبيق',
                            onPressed: _isValidatingCoupon ? null : _validateCoupon,
                          ),
                        ],
                      ),
                      if (_couponError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _couponError!,
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildSectionCard(
                title: 'ملخص الطلب',
                icon: Icons.receipt_long_outlined,
                child: Column(
                  children: [
                    ...cartItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${formatter.format(item.totalPrice)} د.ع',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              '${item.product.nameAr} × ${item.quantity}',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const Divider(height: 24),
                    shippingSettings.when(
                      data: (settings) {
                        final subtotal = cartNotifier.totalPrice;
                        final shipping = settings.calculateShipping(subtotal);
                        final total = subtotal + shipping - _couponDiscount;
                        
                        return Column(
                          children: [
                            _buildPriceRow('المجموع الفرعي', subtotal, formatter),
                            const SizedBox(height: 8),
                            _buildPriceRow(
                              'رسوم التوصيل',
                              shipping,
                              formatter,
                              isFree: shipping == 0,
                            ),
                            if (shipping == 0 && settings.freeShippingThreshold > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'توصيل مجاني للطلبات أكثر من ${formatter.format(settings.freeShippingThreshold)} د.ع',
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.success),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            if (_couponDiscount > 0) ...[
                              const SizedBox(height: 8),
                              _buildPriceRow(
                                'خصم الكوبون',
                                -_couponDiscount,
                                formatter,
                                isDiscount: true,
                              ),
                            ],
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${formatter.format(total)} د.ع',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'الإجمالي',
                                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => _buildPriceRow('المجموع', cartNotifier.totalPrice, formatter),
                      error: (_, __) => _buildPriceRow('المجموع', cartNotifier.totalPrice, formatter),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildSectionCard(
                title: 'معلومات التوصيل',
                icon: Icons.local_shipping_outlined,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'يرجى إدخال الاسم';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'يرجى إدخال رقم الهاتف';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationController,
                      label: 'العنوان / الموقع',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'يرجى إدخال العنوان';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _notesController,
                      label: 'ملاحظات إضافية (اختياري)',
                      icon: Icons.note_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              ShineGlassPanel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.payments_outlined, color: AppColors.success, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'الدفع عند الاستلام',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ادفع نقداً عند استلام طلبك',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.95),
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ShinePrimaryButton(
              label: 'تأكيد الطلب',
              leadingIcon: _isProcessing
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline, color: AppColors.white, size: 22),
              onPressed: _isProcessing ? null : _placeOrder,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return ShineGlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(width: 8),
              Icon(icon, color: AppColors.primary, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, NumberFormat formatter, {bool isFree = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isFree
              ? 'مجاني'
              : isDiscount
                  ? '-${formatter.format(amount.abs())} د.ع'
                  : '${formatter.format(amount)} د.ع',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isFree || isDiscount ? AppColors.success : AppColors.textPrimary,
            fontWeight: isFree || isDiscount ? FontWeight.w600 : null,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      textDirection: textDirection ?? TextDirection.rtl,
      textAlign: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
