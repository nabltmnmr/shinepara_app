import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/brand.dart';
import '../models/banner.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../models/notification.dart';
import '../models/shipping_settings.dart';
import '../models/ai_recommendation.dart';

class ApiClient {
  final Dio _dio;
  final String baseUrl;
  final CookieJar cookieJar;
  String? _deviceId;
  static String? _cachedDeviceId;
  String? _authToken;

  ApiClient({
    required this.baseUrl,
    Dio? dio,
    CookieJar? cookieJar,
  })  : cookieJar = cookieJar ?? CookieJar(),
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 120);
    _dio.options.receiveTimeout = const Duration(seconds: 120);
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
    _dio.interceptors.add(CookieManager(this.cookieJar));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isAuthRequest = options.path.contains('/api/auth/login') ||
            options.path.contains('/api/auth/signup') ||
            options.path.contains('/api/auth/social-login');
        if (_authToken == null) {
          final prefs = await SharedPreferences.getInstance();
          _authToken = prefs.getString('auth_token');
        }
        // Avoid sending stale auth cookies during login/signup.
        if (!isAuthRequest && _authToken != null) {
          options.headers['Cookie'] = 'customerToken=$_authToken';
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          for (final cookie in cookies) {
            if (cookie.contains('customerToken=')) {
              final match = RegExp(r'customerToken=([^;]+)').firstMatch(cookie);
              if (match != null) {
                _authToken = match.group(1);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('auth_token', _authToken!);
              }
            }
          }
        }
        handler.next(response);
      },
    ));
    _initDeviceId();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  Future<void> _initDeviceId() async {
    if (_cachedDeviceId != null) {
      _deviceId = _cachedDeviceId;
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString('device_id');

      if (_deviceId == null) {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          _deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          _deviceId = iosInfo.identifierForVendor;
        }
        _deviceId ??= DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString('device_id', _deviceId!);
      }
      _cachedDeviceId = _deviceId;
    } catch (e) {
      _deviceId = 'unknown';
    }
  }

  Future<String> getDeviceId() async {
    if (_deviceId == null) {
      await _initDeviceId();
    }
    return _deviceId ?? 'unknown';
  }

  Future<List<HomeBanner>> getBanners() async {
    try {
      final response = await _dio.get('/api/banners');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return _getDefaultBanners();
    }
  }

  List<HomeBanner> _getDefaultBanners() {
    return [
      HomeBanner(id: 1, title: 'Shine', subtitle: 'اشراقة تبدأ من هنا'),
    ];
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/api/categories');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Brand>> getBrands() async {
    try {
      final response = await _dio.get('/api/brands');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Brand.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Product>> getProducts({
    String? categoryId,
    int? brandId,
    String? searchQuery,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (brandId != null) queryParams['brandId'] = brandId;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response =
          await _dio.get('/api/products', queryParameters: queryParams);
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Product>> getBestSellers() async {
    try {
      final response = await _dio.get('/api/products/bestsellers');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final response = await _dio.get('/api/products/$id');
      return Product.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<ShippingSettings> getShippingSettings() async {
    try {
      final response = await _dio.get('/api/shipping');
      return ShippingSettings.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return ShippingSettings(shippingFee: 5000, freeShippingThreshold: 50000);
    }
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String location,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPassword = password.trim();
      final deviceId = await getDeviceId();
      final response = await _dio.post('/api/auth/signup', data: {
        'email': normalizedEmail,
        'password': normalizedPassword,
        'fullName': fullName,
        'phone': phone,
        'location': location,
        'deviceId': deviceId,
        'device_id': deviceId,
      });

      if (response.data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        if (response.data['customer'] != null) {
          await prefs.setInt('customer_id', response.data['customer']['id']);
        }
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل إنشاء الحساب');
      }
      throw Exception('فشل إنشاء الحساب');
    }
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPassword = password.trim();
      final deviceId = await getDeviceId();
      final response = await _dio.post('/api/auth/login', data: {
        'email': normalizedEmail,
        'password': normalizedPassword,
        'deviceId': deviceId,
        'device_id': deviceId,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      if (response.data['customer'] != null) {
        await prefs.setInt('customer_id', response.data['customer']['id']);
      }

      return User.fromJson(response.data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل تسجيل الدخول');
      }
      throw Exception('فشل تسجيل الدخول');
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post('/api/auth/forgot-password', data: {
        'email': email,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response!.data['error']);
      }
      throw Exception('حدث خطأ في الاتصال');
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post('/api/auth/reset-password', data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response!.data['error']);
      }
      throw Exception('حدث خطأ في الاتصال');
    }
  }

  Future<void> deleteAccount({String? currentPassword}) async {
    try {
      await _dio.delete(
        '/api/auth/delete-account',
        data: {
          if (currentPassword != null && currentPassword.trim().isNotEmpty)
            'currentPassword': currentPassword.trim(),
        },
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      final serverError = responseData is Map ? responseData['error'] : null;

      if (statusCode == 401) {
        throw Exception('جلسة تسجيل الدخول منتهية. يرجى تسجيل الدخول مرة أخرى.');
      }
      if (statusCode == 403) {
        throw Exception(
          serverError?.toString() ?? 'يلزم تسجيل دخول حديث قبل حذف الحساب.',
        );
      }
      if (statusCode == 408) {
        throw Exception('انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('تعذر الاتصال بالشبكة. تحقق من الإنترنت ثم حاول مرة أخرى.');
      }

      throw Exception(serverError?.toString() ?? 'فشل حذف الحساب. يرجى المحاولة مرة أخرى.');
    }
  }

  Future<User> socialLogin({
    required String provider,
    required String idToken,
    String? name,
  }) async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post('/api/auth/social-login', data: {
        'provider': provider,
        'idToken': idToken,
        'name': name ?? '',
        'deviceId': deviceId,
        'device_id': deviceId,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      if (response.data['customer'] != null) {
        await prefs.setInt('customer_id', response.data['customer']['id']);
      }

      final customer = response.data['customer'];
      if (customer is Map<String, dynamic>) {
        return User.fromJson(customer);
      }

      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        return currentUser;
      }
      throw Exception('حدث خطأ في تسجيل الدخول');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'حدث خطأ في تسجيل الدخول');
      }
      throw Exception('حدث خطأ في تسجيل الدخول');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (e) {
      // Ignore logout errors
    } finally {
      _authToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('customer_id');
      await prefs.remove('auth_token');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (!isLoggedIn) return false;

      final user = await getCurrentUser();
      if (user == null) {
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('customer_id');
        return false;
      }
      return true;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('customer_id');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/auth/me');
      return User.fromJson(response.data['customer'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? location,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['fullName'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (location != null) data['location'] = location;

      final response = await _dio.put('/api/auth/profile', data: data);
      return User.fromJson(response.data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل تحديث البيانات');
      }
      throw Exception('فشل تحديث البيانات');
    }
  }

  Future<Map<String, dynamic>> validateCoupon(
      String code, double orderTotal) async {
    try {
      final response = await _dio.post('/api/coupons/validate', data: {
        'code': code,
        'orderTotal': orderTotal,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'كود الخصم غير صالح');
      }
      throw Exception('كود الخصم غير صالح');
    }
  }

  Future<Order> placeOrder({
    required String customerName,
    required String customerPhone,
    required String customerLocation,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? couponCode,
  }) async {
    try {
      final response = await _dio.post('/api/orders', data: {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerLocation': customerLocation,
        'items': items,
        'notes': notes,
        'paymentMethod': 'COD',
        if (couponCode != null) 'couponCode': couponCode,
      });
      return Order.fromJson(response.data['order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل إنشاء الطلب');
      }
      throw Exception('فشل إنشاء الطلب');
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await _dio.get('/api/orders');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Order?> getOrderById(int id) async {
    try {
      final response = await _dio.get('/api/orders/$id');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _dio.get('/api/notifications');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get('/api/notifications/unread-count');
      return response.data['count'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    try {
      await _dio.put('/api/notifications/$id/read');
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.put('/api/notifications/read-all');
    } catch (e) {
      // Ignore errors
    }
  }

  Future<AIResponse> getAIRecommendation({
    required String query,
    String locale = 'ar',
    List<Map<String, dynamic>> conversationHistory = const [],
  }) async {
    try {
      final response = await _dio.post(
        '/api/ai/recommend',
        data: {
          'query': query,
          'locale': locale,
          'conversationHistory': conversationHistory,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return AIResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('AI Error: $e');
      return _getMockAIResponse(query);
    }
  }

  AIResponse _getMockAIResponse(String query) {
    return AIResponse(
      answer:
          'مرحباً! أنا مساعدك الذكي للعناية بالبشرة. كيف يمكنني مساعدتك اليوم؟',
      recommendations: [],
    );
  }

  Future<Response> post(String path, Map<String, dynamic> data) async {
    return await _dio.post(path, data: data);
  }

  Future<String?> getAuthToken() async {
    try {
      final cookies = await cookieJar.loadForRequest(Uri.parse(baseUrl));
      final tokenCookie = cookies.firstWhere(
        (c) => c.name == 'customer_token',
        orElse: () => Cookie('', ''),
      );
      return tokenCookie.value.isNotEmpty ? tokenCookie.value : null;
    } catch (e) {
      return null;
    }
  }

  static ApiClient? _instance;

  static ApiClient get instance {
    _instance ??=
        ApiClient(baseUrl: 'https://shine-flutter-doc--nabltmnmr.replit.app');
    return _instance!;
  }

  static void initialize(String baseUrl) {
    _instance = ApiClient(baseUrl: baseUrl);
  }

  static String getBaseUrl() {
    return _instance?.baseUrl ??
        'https://shine-flutter-doc--nabltmnmr.replit.app';
  }

  Future<Map<String, dynamic>> getScanCredits() async {
    try {
      final response = await _dio.get('/api/skin-scan/credits');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'credits': 0, 'can_claim_share_reward': true};
    }
  }

  Future<List<Map<String, dynamic>>> getScanHistory() async {
    try {
      final response = await _dio.get('/api/skin-scan/history');
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getScanById(int scanId) async {
    try {
      final response = await _dio.get('/api/skin-scan/$scanId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> analyzeSkin({
    required String areaType,
    String? imageBase64,
    File? imageFile,
  }) async {
    try {
      FormData formData;

      if (imageFile != null) {
        formData = FormData.fromMap({
          'area_type': areaType,
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'skin_image.jpg',
          ),
        });
      } else {
        formData = FormData.fromMap({
          'area_type': areaType,
          if (imageBase64 != null) 'image_base64': imageBase64,
        });
      }

      final response = await _dio.post(
        '/api/skin-scan/analyze',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      if (response.data == null) {
        throw Exception('Empty response from server');
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('Skin scan DioException: ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('انتهى وقت الاتصال - تأكد من اتصال الإنترنت');
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('انتهى وقت الاستجابة - حاول مرة أخرى');
      }
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل تحليل البشرة');
      }
      throw Exception('فشل تحليل البشرة: ${e.message}');
    }
  }

  Future<String> generateRoutine({
    required int scanId,
    required double budget,
  }) async {
    try {
      final response = await _dio.post(
        '/api/skin-scan/$scanId/routine',
        data: {'budget': budget},
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return response.data['routine'] as String? ?? '';
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل إنشاء الروتين');
      }
      throw Exception('فشل إنشاء الروتين');
    }
  }

  Future<Map<String, dynamic>> compareScans({
    required int scanId1,
    required int scanId2,
  }) async {
    try {
      final response = await _dio.post(
        '/api/skin-scan/compare',
        data: {
          'scan_id_1': scanId1,
          'scan_id_2': scanId2,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل مقارنة الفحوصات');
      }
      throw Exception('فشل مقارنة الفحوصات');
    }
  }

  Future<bool> claimShareReward() async {
    try {
      final response = await _dio.post('/api/skin-scan/claim-share-reward');
      return response.data['success'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      final response =
          await _dio.post('/api/auth/profile-picture', data: formData);
      return response.data['profilePictureUrl'] as String? ?? '';
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل رفع الصورة');
      }
      throw Exception('فشل رفع الصورة');
    }
  }

  Future<void> removeProfilePicture() async {
    try {
      await _dio.delete('/api/auth/profile-picture');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل حذف الصورة');
      }
      throw Exception('فشل حذف الصورة');
    }
  }

  Future<List<Map<String, dynamic>>> getRoutines() async {
    try {
      final response = await _dio.get('/api/routines');
      final routines = response.data['routines'] as List<dynamic>? ?? [];
      return routines.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> saveRoutine({
    int? scanId,
    required String routineText,
    String? title,
  }) async {
    try {
      final response = await _dio.post('/api/routines', data: {
        'scanId': scanId,
        'routineText': routineText,
        'title': title ?? 'روتين مخصص',
      });
      return response.data['routine'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل حفظ الروتين');
      }
      throw Exception('فشل حفظ الروتين');
    }
  }

  Future<void> deleteRoutine(int id) async {
    try {
      await _dio.delete('/api/routines/$id');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل حذف الروتين');
      }
      throw Exception('فشل حذف الروتين');
    }
  }
}
