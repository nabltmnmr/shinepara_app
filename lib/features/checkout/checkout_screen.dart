import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';
import 'package:intl/intl.dart';

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
  bool _isProcessing = false;
  String? _error;

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
    super.dispose();
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
      );

      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 64),
                const SizedBox(height: 16),
                Text(
                  'تم إرسال طلبك بنجاح!',
                  style: AppTextStyles.titleMedium,
                  textDirection: ui.TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(
                  'سنتواصل معك قريباً لتأكيد الطلب',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textDirection: ui.TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الدفع عند الاستلام',
                    style: AppTextStyles.labelMedium.copyWith(color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
                child: const Text('متابعة التسوق'),
              ),
              if (ref.read(authProvider) != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/orders');
                  },
                  child: const Text('عرض طلباتي'),
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
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text('إتمام الطلب', style: AppTextStyles.titleLarge),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text('السلة فارغة', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('تسوق الآن'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('إتمام الطلب', style: AppTextStyles.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                    textDirection: ui.TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ملخص الطلب', style: AppTextStyles.titleMedium, textDirection: ui.TextDirection.rtl),
                    const SizedBox(height: 12),
                    ...cartItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${formatter.format(item.totalPrice)} د.ع',
                            style: AppTextStyles.bodyMedium,
                          ),
                          Expanded(
                            child: Text(
                              '${item.product.nameAr} × ${item.quantity}',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.right,
                              textDirection: ui.TextDirection.rtl,
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
                        final total = subtotal + shipping;
                        
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${formatter.format(subtotal)} د.ع',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                Text('المجموع الفرعي', style: AppTextStyles.bodyMedium, textDirection: ui.TextDirection.rtl),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  shipping > 0 ? '${formatter.format(shipping)} د.ع' : 'مجاني',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: shipping > 0 ? null : Colors.green,
                                  ),
                                ),
                                Text('رسوم التوصيل', style: AppTextStyles.bodyMedium, textDirection: ui.TextDirection.rtl),
                              ],
                            ),
                            if (shipping == 0 && settings.freeShippingThreshold > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'توصيل مجاني للطلبات أكثر من ${formatter.format(settings.freeShippingThreshold)} د.ع',
                                style: AppTextStyles.labelSmall.copyWith(color: Colors.green),
                                textDirection: ui.TextDirection.rtl,
                              ),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${formatter.format(total)} د.ع',
                                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                                ),
                                Text('الإجمالي', style: AppTextStyles.titleMedium, textDirection: ui.TextDirection.rtl),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${formatter.format(cartNotifier.totalPrice)} د.ع',
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                          ),
                          Text('المجموع', style: AppTextStyles.titleMedium, textDirection: ui.TextDirection.rtl),
                        ],
                      ),
                      error: (_, __) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${formatter.format(cartNotifier.totalPrice)} د.ع',
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                          ),
                          Text('المجموع', style: AppTextStyles.titleMedium, textDirection: ui.TextDirection.rtl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('معلومات التوصيل', style: AppTextStyles.titleMedium, textDirection: ui.TextDirection.rtl),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'الدفع عند الاستلام',
                            style: AppTextStyles.titleSmall.copyWith(color: Colors.green.shade800),
                            textDirection: ui.TextDirection.rtl,
                          ),
                          Text(
                            'ادفع نقداً عند استلام طلبك',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.green.shade700),
                            textDirection: ui.TextDirection.rtl,
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
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                    )
                  : Text('تأكيد الطلب', style: AppTextStyles.buttonText),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
