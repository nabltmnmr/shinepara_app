import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
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

  ApiClient({
    required this.baseUrl,
    Dio? dio,
    CookieJar? cookieJar,
  }) : cookieJar = cookieJar ?? CookieJar(),
       _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
    _dio.interceptors.add(CookieManager(this.cookieJar));
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

      final response = await _dio.get('/api/products', queryParameters: queryParams);
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
      final response = await _dio.post('/api/auth/signup', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'location': location,
      });
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
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      return User.fromJson(response.data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? 'فشل تسجيل الدخول');
      }
      throw Exception('فشل تسجيل الدخول');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (e) {
      // Ignore logout errors
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

  Future<Order> placeOrder({
    required String customerName,
    required String customerPhone,
    required String customerLocation,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/api/orders', data: {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerLocation': customerLocation,
        'items': items,
        'notes': notes,
        'paymentMethod': 'COD',
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
  }) async {
    try {
      final response = await _dio.post('/api/ai/recommend', data: {
        'message': query,
        'locale': locale,
      });
      return AIResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return _getMockAIResponse(query);
    }
  }

  AIResponse _getMockAIResponse(String query) {
    return AIResponse(
      answer: 'مرحباً! أنا مساعدك الذكي للعناية بالبشرة. كيف يمكنني مساعدتك اليوم؟',
      recommendations: [],
    );
  }
}
