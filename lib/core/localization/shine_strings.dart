import 'package:flutter/widgets.dart';

/// Lightweight string localization (no codegen).
///
/// Add keys here and replace hard-coded strings with `context.tr('key')`.
class ShineStrings {
  static const Map<String, Map<String, String>> _values = {
    'en': {
      'view_all': 'View All',
      'trending_brands': 'Trending Brands',
      'new_arrivals': 'New Arrivals',
      'my_profile': 'My Profile',
      'language': 'Language',
      'english': 'English',
      'arabic': 'Arabic',
      'wishlist': 'Wishlist',
      'wishlist_empty_title': 'Wishlist is empty',
      'wishlist_empty_subtitle': 'Add products to wishlist to find them here',
      'browse_products': 'Browse products',
      'skin_scan': 'Skin Scan',
      'my_routine': 'My Routine',
      'orders': 'Orders',
      'payment_methods': 'Payment Methods',
      'logout': 'Logout',
      'scan_preview': 'Scan preview',
      'scan_credits': 'Scan credits',
      'share_reward': 'Share and get +2 scans',
      'reward_claimed_today': 'Reward claimed today',
      'start_scan': 'Start scan',
      'preview_scan': 'Preview scan',
      'scan_preview_notice': 'You can preview the camera, but you can’t start a scan without credits.',
      'ai_highlights_title': 'Advanced AI analysis',
      'feature_12_metrics': '12 skin metrics',
      'feature_analysis_images': 'Analysis images',
      'feature_custom_routine': 'Custom routine',
      'feature_progress_compare': 'Progress comparison',
      'scan_history': 'Scan history',
      'compare': 'Compare',
      'history_load_error': 'Failed to load history',
      'no_scans_yet': 'No previous scans',
      'start_first_scan': 'Start your first scan now',
      'skin_scan_item_title': 'Skin scan',
      'analysis_images_count': '{count} analysis images',

      // Cart
      'cart_title': 'My Bag',
      'cart_items_count': 'Items {count}',
      'cart_empty_title': 'Your bag is empty',
      'cart_empty_subtitle': 'Add products to get started.',
      'cart_shop_now': 'Shop Now',
      'cart_added_to_bag': 'Added to bag',
      'cart_view': 'View',

      // Search
      'search_clear_all': 'Clear All',
      'search_recent_searches': 'Recent Searches',
      'search_top_brands': 'Top Brands',
      'search_recommended_for_you': 'Recommended for You',

      // Brands directory
      'brands_directory': 'Brands Directory',
      'brands_search_hint': 'Find a boutique brand...',
      'brands_load_error': 'Failed to load brands',

      // Profile CTA + skin card
      'chat_with_us': 'Chat with us',
      'full_report': 'Full report',

      // Auth
      'login_title': 'Welcome back',
      'login_subtitle': 'Sign in to access your account',
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'no_account': 'Don’t have an account?',
      'create_account': 'Create account',
      'signup_title': 'Welcome to Shine',
      'signup_subtitle': 'Create your account for the best shopping experience',
      'full_name': 'Full name',
      'phone': 'Phone number',
      'location': 'Location / Address',
      'confirm_password': 'Confirm password',
      'signup': 'Sign up',
      'forgot_password': 'Forgot Password?',
      'forgot_password_title': 'Reset Password',
      'forgot_password_subtitle': 'Enter your email to receive a reset code',
      'send_code': 'Send Code',
      'enter_code_title': 'Enter Reset Code',
      'enter_code_subtitle': 'Enter the 6-digit code sent to your email',
      'reset_code': 'Reset Code',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'reset_password': 'Reset Password',
      'password_reset_success': 'Password changed successfully!',
      'code_sent_success': 'Reset code sent. Check with the admin.',
      'passwords_dont_match': 'Passwords do not match',
      'back_to_login': 'Back to Login',
      'resend_code': 'Resend Code',
      'code_expires_in': 'Code expires in 15 minutes',
      'privacy_ai': 'Privacy & AI',
      'ai_consent_status': 'AI consent status',
      'granted': 'Granted',
      'not_granted': 'Not granted',
      'withdraw_ai_consent': 'Withdraw AI consent',
      'account': 'Account',
      'delete_account': 'Delete Account',
      'delete_account_title': 'Delete Account',
      'delete_account_body': 'Deleting your account will permanently remove your profile and associated data from Shine, including saved preferences, uploaded analysis data, and account history, except where retention is required by law.\n\nThis action cannot be undone.',
      'delete_my_account': 'Delete My Account',

      // Hero banner
      'hero_badge': 'NEW COLLECTION',
      'hero_title_1': 'Awaken Your',
      'hero_title_2': 'Inner ',
      'hero_title_accent': 'Glow',
      'hero_subtitle': 'Discover the new nightly repair\nserum designed for radiant\nmornings',
      'hero_cta': 'Start Your Routine',

      // Cart details
      'cart_subtotal': 'Subtotal',
      'cart_shipping': 'Shipping',
      'cart_total': 'Total',
      'cart_promo_hint': 'Enter Promo Code',
      'cart_promo_apply': 'Apply',
      'cart_confirm': 'Confirm Order',
      'cart_free_shipping': 'Free',

      // Search
      'search_hint': 'Search serums, creams...',

      // Categories
      'categories': 'Categories',

      // AI assistant
      'ai_clear_chat': 'Clear chat',
      'ai_title': 'Skin Assistant',
      'ai_subtitle': 'Ask about your skin, routines, or ingredients.',
      'ai_example': 'Example: “What is Hyaluronic Acid good for?”',
      'today': 'Today',
      'yesterday': 'Yesterday',

      // Skin health card
      'skin_health': 'Skin Health',
      'last_scan': 'Last Scan',
      'hydration': 'HYDRATION',
      'texture': 'TEXTURE',
      'glow': 'GLOW',
      'login_required_for_report': 'Please login to view your scan report',

      // Profile picture
      'take_photo': 'Take Photo',
      'choose_from_gallery': 'Choose from Gallery',
      'remove_photo': 'Remove Photo',
      'profile_picture_updated': 'Profile picture updated',
      'profile_picture_removed': 'Profile picture removed',
      'profile_picture_error': 'Failed to update profile picture',

      // Routines
      'my_routines': 'My Routines',
      'no_routines_yet': 'No saved routines yet',
      'no_routines_subtitle': 'Get a skin scan and AI will suggest a personalized routine for you',
      'start_skin_scan': 'Start Skin Scan',
      'create_routine': 'Create Custom Routine',
      'save_routine': 'Save Routine',
      'routine_saved': 'Routine saved successfully',
      'routine_deleted': 'Routine deleted',
      'delete_routine': 'Delete Routine',
      'delete_routine_confirm': 'Are you sure you want to delete this routine?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'saved_on': 'Saved on',
    },
    'ar': {
      'view_all': 'عرض الكل',
      'trending_brands': 'العلامات الرائجة',
      'new_arrivals': 'وصل حديثاً',
      'my_profile': 'ملفي',
      'language': 'اللغة',
      'english': 'الإنجليزية',
      'arabic': 'العربية',
      'wishlist': 'المفضلة',
      'wishlist_empty_title': 'قائمة المفضلة فارغة',
      'wishlist_empty_subtitle': 'أضف منتجات إلى المفضلة لتجدها هنا',
      'browse_products': 'تصفح المنتجات',
      'skin_scan': 'فحص البشرة',
      'my_routine': 'روتيني',
      'orders': 'الطلبات',
      'payment_methods': 'طرق الدفع',
      'logout': 'تسجيل الخروج',
      'scan_preview': 'معاينة الفحص',
      'scan_credits': 'رصيد الفحوصات',
      'share_reward': 'شارك واحصل على +2 فحص',
      'reward_claimed_today': 'تم الحصول على المكافأة اليوم',
      'start_scan': 'ابدأ الفحص',
      'preview_scan': 'معاينة الفحص',
      'scan_preview_notice': 'يمكنك معاينة الكاميرا، لكن لا يمكنك بدء الفحص بدون رصيد.',
      'ai_highlights_title': 'تحليل متقدم بالذكاء الاصطناعي',
      'feature_12_metrics': '12 مؤشر للبشرة',
      'feature_analysis_images': 'صور تحليلية',
      'feature_custom_routine': 'روتين مخصص',
      'feature_progress_compare': 'مقارنة التقدم',
      'scan_history': 'سجل الفحوصات',
      'compare': 'مقارنة',
      'history_load_error': 'حدث خطأ في تحميل السجل',
      'no_scans_yet': 'لا توجد فحوصات سابقة',
      'start_first_scan': 'ابدأ فحصك الأول الآن',
      'skin_scan_item_title': 'فحص البشرة',
      'analysis_images_count': '{count} صورة تحليلية',

      // Cart
      'cart_title': 'سلة التسوق',
      'cart_items_count': 'عدد المنتجات {count}',
      'cart_empty_title': 'سلتك فارغة',
      'cart_empty_subtitle': 'أضف منتجات للبدء.',
      'cart_shop_now': 'تسوق الآن',
      'cart_added_to_bag': 'تمت الإضافة إلى السلة',
      'cart_view': 'عرض',

      // Search
      'search_clear_all': 'مسح الكل',
      'search_recent_searches': 'عمليات البحث الأخيرة',
      'search_top_brands': 'أفضل العلامات',
      'search_recommended_for_you': 'مقترح لك',

      // Brands directory
      'brands_directory': 'دليل العلامات التجارية',
      'brands_search_hint': 'ابحث عن علامة...',
      'brands_load_error': 'حدث خطأ في تحميل العلامات التجارية',

      // Profile CTA + skin card
      'chat_with_us': 'تواصل معنا',
      'full_report': 'التقرير الكامل',

      // Auth
      'login_title': 'مرحباً بعودتك',
      'login_subtitle': 'سجل دخولك للوصول إلى حسابك',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول',
      'no_account': 'ليس لديك حساب؟',
      'create_account': 'إنشاء حساب',
      'signup_title': 'مرحباً بك في Shine',
      'signup_subtitle': 'أنشئ حسابك للحصول على أفضل تجربة تسوق',
      'full_name': 'الاسم الكامل',
      'phone': 'رقم الهاتف',
      'location': 'الموقع / العنوان',
      'confirm_password': 'تأكيد كلمة المرور',
      'signup': 'إنشاء حساب',
      'forgot_password': 'نسيت كلمة المرور؟',
      'forgot_password_title': 'إعادة تعيين كلمة المرور',
      'forgot_password_subtitle': 'أدخل بريدك الإلكتروني لاستلام رمز إعادة التعيين',
      'send_code': 'إرسال الرمز',
      'enter_code_title': 'أدخل رمز التحقق',
      'enter_code_subtitle': 'أدخل الرمز المكون من 6 أرقام',
      'reset_code': 'رمز التحقق',
      'new_password': 'كلمة المرور الجديدة',
      'confirm_new_password': 'تأكيد كلمة المرور',
      'reset_password': 'إعادة تعيين كلمة المرور',
      'password_reset_success': 'تم تغيير كلمة المرور بنجاح!',
      'code_sent_success': 'تم إرسال رمز التحقق. تواصل مع الإدارة للحصول عليه.',
      'passwords_dont_match': 'كلمات المرور غير متطابقة',
      'back_to_login': 'العودة لتسجيل الدخول',
      'resend_code': 'إعادة إرسال الرمز',
      'code_expires_in': 'صلاحية الرمز 15 دقيقة',
      'privacy_ai': 'الخصوصية والذكاء الاصطناعي',
      'ai_consent_status': 'حالة موافقة الذكاء الاصطناعي',
      'granted': 'ممنوحة',
      'not_granted': 'غير ممنوحة',
      'withdraw_ai_consent': 'سحب موافقة الذكاء الاصطناعي',
      'account': 'الحساب',
      'delete_account': 'حذف الحساب',
      'delete_account_title': 'حذف الحساب',
      'delete_account_body': 'حذف حسابك سيؤدي إلى إزالة ملفك الشخصي والبيانات المرتبطة به بشكل دائم من Shine، بما في ذلك التفضيلات المحفوظة وبيانات التحليل المرفوعة وسجل الحساب، باستثناء ما يلزم الاحتفاظ به قانونياً.\n\nلا يمكن التراجع عن هذا الإجراء.',
      'delete_my_account': 'احذف حسابي',

      // Hero banner
      'hero_badge': 'مجموعة جديدة',
      'hero_title_1': 'أيقظي',
      'hero_title_2': 'إشراقك ',
      'hero_title_accent': 'الداخلي',
      'hero_subtitle': 'اكتشفي سيروم الإصلاح الليلي\nالجديد المصمم لصباحات\nمشرقة',
      'hero_cta': 'ابدأي روتينك',

      // Cart details
      'cart_subtotal': 'المجموع الفرعي',
      'cart_shipping': 'التوصيل',
      'cart_total': 'المجموع',
      'cart_promo_hint': 'أدخل رمز الخصم',
      'cart_promo_apply': 'تطبيق',
      'cart_confirm': 'تأكيد الطلب',
      'cart_free_shipping': 'مجاني',

      // Search
      'search_hint': 'ابحث عن سيروم، كريم...',

      // Categories
      'categories': 'التصنيفات',

      // AI assistant
      'ai_clear_chat': 'مسح المحادثة',
      'ai_title': 'مساعد البشرة',
      'ai_subtitle': 'اسأل عن بشرتك أو الروتين أو المكونات.',
      'ai_example': 'مثال: "ما فائدة حمض الهيالورونيك؟"',
      'today': 'اليوم',
      'yesterday': 'أمس',

      // Skin health card
      'skin_health': 'صحة البشرة',
      'last_scan': 'آخر فحص',
      'hydration': 'الترطيب',
      'texture': 'الملمس',
      'glow': 'الإشراق',
      'login_required_for_report': 'يرجى تسجيل الدخول لعرض تقرير الفحص',

      // Profile picture
      'take_photo': 'التقاط صورة',
      'choose_from_gallery': 'اختيار من المعرض',
      'remove_photo': 'حذف الصورة',
      'profile_picture_updated': 'تم تحديث صورة الملف الشخصي',
      'profile_picture_removed': 'تم حذف صورة الملف الشخصي',
      'profile_picture_error': 'فشل تحديث صورة الملف الشخصي',

      // Routines
      'my_routines': 'روتيناتي',
      'no_routines_yet': 'لا توجد روتينات محفوظة',
      'no_routines_subtitle': 'احصل على فحص بشرة وسيقترح الذكاء الاصطناعي روتيناً مخصصاً لك',
      'start_skin_scan': 'ابدأ فحص البشرة',
      'create_routine': 'إنشاء روتين مخصص',
      'save_routine': 'حفظ الروتين',
      'routine_saved': 'تم حفظ الروتين بنجاح',
      'routine_deleted': 'تم حذف الروتين',
      'delete_routine': 'حذف الروتين',
      'delete_routine_confirm': 'هل أنت متأكد من حذف هذا الروتين؟',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'saved_on': 'حُفظ في',
    },
  };

  static String of(BuildContext context, String key) {
    final code = Localizations.localeOf(context).languageCode;
    return _values[code]?[key] ?? _values['en']?[key] ?? key;
  }

  static String format(BuildContext context, String key, Map<String, String> vars) {
    var s = of(context, key);
    for (final entry in vars.entries) {
      s = s.replaceAll('{${entry.key}}', entry.value);
    }
    return s;
  }
}

extension ShineStringsX on BuildContext {
  String tr(String key) => ShineStrings.of(this, key);
  String trf(String key, Map<String, String> vars) => ShineStrings.format(this, key, vars);
}

