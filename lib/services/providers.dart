import 'dart:io';
import 'dart:ui' show Locale;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/brand.dart';
import '../models/banner.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../models/notification.dart';
import '../models/shipping_settings.dart';
import '../models/ai_recommendation.dart';
import '../models/skin_scan.dart';
import '../models/product_review.dart';
import 'api_client.dart';

const String apiBaseUrl = 'https://shine-care.com';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: apiBaseUrl);
});

class AppLocaleNotifier extends StateNotifier<Locale> {
  AppLocaleNotifier() : super(const Locale('ar'));

  static const String _prefsKey = 'app_locale';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && (code == 'ar' || code == 'en')) {
        state = Locale(code);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = Locale(locale.languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
    } catch (_) {
      // ignore
    }
  }
}

final appLocaleProvider =
    StateNotifierProvider<AppLocaleNotifier, Locale>((ref) {
  return AppLocaleNotifier();
});

final bannersProvider = FutureProvider<List<HomeBanner>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getBanners();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getCategories();
});

final brandsProvider = FutureProvider<List<Brand>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getBrands();
});

final bestSellersProvider = FutureProvider<List<Product>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getBestSellers();
});

final productsProvider =
    FutureProvider.family<List<Product>, ProductFilter>((ref, filter) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getProducts(
    categoryId: filter.categoryId,
    brandId: filter.brandId,
    searchQuery: filter.searchQuery,
  );
});

final productDetailProvider =
    FutureProvider.family<Product?, int>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getProductById(id);
});

final shippingSettingsProvider = FutureProvider<ShippingSettings>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getShippingSettings();
});

class ProductFilter {
  final String? categoryId;
  final int? brandId;
  final String? searchQuery;

  ProductFilter({this.categoryId, this.brandId, this.searchQuery});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductFilter &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          brandId == other.brandId &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode =>
      categoryId.hashCode ^ brandId.hashCode ^ searchQuery.hashCode;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product) {
    final existingIndex =
        state.indexWhere((item) => item.productId == product.id);
    if (existingIndex >= 0) {
      state = [
        ...state.sublist(0, existingIndex),
        state[existingIndex]
            .copyWith(quantity: state[existingIndex].quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, CartItem(productId: product.id, product: product)];
    }
  }

  void removeFromCart(int productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    state = state.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalPrice => state.fold(0, (sum, item) => sum + item.totalPrice);

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class WishlistNotifier extends StateNotifier<Set<int>> {
  WishlistNotifier() : super({});

  void toggleWishlist(int productId) {
    if (state.contains(productId)) {
      state = {...state}..remove(productId);
    } else {
      state = {...state, productId};
    }
  }

  bool isInWishlist(int productId) => state.contains(productId);

  void clearWishlist() {
    state = {};
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, Set<int>>((ref) {
  return WishlistNotifier();
});

final wishlistProductsProvider = FutureProvider<List<Product>>((ref) async {
  final wishlistIds = ref.watch(wishlistProvider);
  if (wishlistIds.isEmpty) return [];

  final apiClient = ref.watch(apiClientProvider);
  final allProducts = await apiClient.getProducts();
  return allProducts.where((p) => wishlistIds.contains(p.id)).toList();
});

class AuthNotifier extends StateNotifier<User?> {
  final ApiClient apiClient;
  bool isLoading = false;
  bool _initialized = false;

  AuthNotifier(this.apiClient) : super(null);

  bool get isInitialized => _initialized;

  Future<void> checkAuthStatus() async {
    isLoading = true;
    try {
      final user = await apiClient.getCurrentUser();
      state = user;
    } catch (e) {
      state = null;
    } finally {
      isLoading = false;
      _initialized = true;
    }
  }

  Future<bool> tryAutoLogin() async {
    if (_initialized) return state != null;
    isLoading = true;
    try {
      final success = await apiClient.tryAutoLogin();
      if (success) {
        final user = await apiClient.getCurrentUser();
        state = user;
        return user != null;
      }
      state = null;
      return false;
    } catch (e) {
      state = null;
      return false;
    } finally {
      isLoading = false;
      _initialized = true;
    }
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    try {
      final user = await apiClient.login(email: email, password: password);
      state = user;
    } finally {
      isLoading = false;
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String location,
  }) async {
    isLoading = true;
    try {
      await apiClient.signup(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        location: location,
      );
      final user = await apiClient.login(email: email, password: password);
      state = user;
    } finally {
      isLoading = false;
    }
  }

  Future<void> socialLogin({
    required String provider,
    required String idToken,
    String? name,
  }) async {
    isLoading = true;
    try {
      final user = await apiClient.socialLogin(
        provider: provider,
        idToken: idToken,
        name: name,
      );
      state = user;
    } finally {
      isLoading = false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? location,
  }) async {
    isLoading = true;
    try {
      final updatedUser = await apiClient.updateProfile(
        fullName: fullName,
        phone: phone,
        location: location,
      );
      state = updatedUser;
    } finally {
      isLoading = false;
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    isLoading = true;
    try {
      final url = await apiClient.uploadProfilePicture(imageFile);
      if (state != null) {
        state = state!.copyWith(profilePictureUrl: url);
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> removeProfilePicture() async {
    isLoading = true;
    try {
      await apiClient.removeProfilePicture();
      if (state != null) {
        state = User(
          id: state!.id,
          email: state!.email,
          fullName: state!.fullName,
          phone: state!.phone,
          location: state!.location,
          profilePictureUrl: null,
          createdAt: state!.createdAt,
        );
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> logout() async {
    await apiClient.logout();
    state = null;
  }

  bool get isLoggedIn => state != null;
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getOrders();
});

final orderDetailProvider = FutureProvider.family<Order?, int>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getOrderById(id);
});

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getNotifications();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getUnreadNotificationCount();
});

class AIChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ApiClient apiClient;
  bool isLoading = false;

  AIChatNotifier(this.apiClient) : super([]);

  Future<void> sendMessage(String content) async {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMessage];

    isLoading = true;

    try {
      final history = state
          .where((m) => m.content.isNotEmpty)
          .map<Map<String, dynamic>>((m) => {
                'content': m.content,
                'isUser': m.isUser,
              })
          .toList();
      if (history.isNotEmpty) {
        history.removeLast();
      }

      final response = await apiClient.getAIRecommendation(
        query: content,
        conversationHistory: history,
      );

      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: response.answer,
        isUser: false,
        timestamp: DateTime.now(),
        recommendations: response.recommendations,
      );
      state = [...state, aiMessage];
    } catch (e) {
      final errorMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: 'عذراً، حدث خطأ. يرجى المحاولة مرة أخرى.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, errorMessage];
    } finally {
      isLoading = false;
    }
  }

  void clearChat() {
    state = [];
  }
}

final aiChatProvider =
    StateNotifierProvider<AIChatNotifier, List<ChatMessage>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIChatNotifier(apiClient);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

class ScanCreditsNotifier extends StateNotifier<AsyncValue<ScanCredits>> {
  final ApiClient apiClient;

  ScanCreditsNotifier(this.apiClient) : super(const AsyncValue.loading()) {
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    try {
      final data = await apiClient.getScanCredits();
      state = AsyncValue.data(ScanCredits.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> claimShareReward() async {
    final success = await apiClient.claimShareReward();
    if (success) {
      await _loadCredits();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadCredits();
  }
}

final scanCreditsProvider =
    StateNotifierProvider<ScanCreditsNotifier, AsyncValue<ScanCredits>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ScanCreditsNotifier(apiClient);
});

final scanHistoryProvider = FutureProvider<List<SkinScan>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final data = await apiClient.getScanHistory();
  return data.map((json) {
    if (json.containsKey('scan')) {
      return SkinScan.fromJson(json['scan'] as Map<String, dynamic>);
    }
    return SkinScan.fromJson(json);
  }).toList();
});

final skinScanProvider = FutureProvider.family<SkinScan?, int>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  final data = await apiClient.getScanById(id);
  if (data == null) return null;
  return SkinScan.fromJson(data);
});

class SkinScanService {
  final ApiClient apiClient;

  SkinScanService(this.apiClient);

  Future<SkinScan> analyzeSkin({
    required File imageFile,
    required String areaType,
  }) async {
    final data = await apiClient.analyzeSkin(
      areaType: areaType,
      imageFile: imageFile,
    );
    final scanData = data['scan'];
    if (scanData is Map<String, dynamic>) {
      return SkinScan.fromJson(scanData);
    }
    return SkinScan.fromJson(data);
  }

  Future<String> generateRoutine({
    required int scanId,
    required double budget,
  }) async {
    return await apiClient.generateRoutine(scanId: scanId, budget: budget);
  }

  Future<ScanComparison> compareScans({
    required int scanId1,
    required int scanId2,
  }) async {
    final data =
        await apiClient.compareScans(scanId1: scanId1, scanId2: scanId2);
    return ScanComparison.fromJson(data);
  }
}

final skinScanServiceProvider = Provider<SkinScanService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SkinScanService(apiClient);
});

// -----------------------------
// Product reviews (local)
// -----------------------------

class ProductReviewsNotifier
    extends StateNotifier<AsyncValue<List<ProductReview>>> {
  ProductReviewsNotifier(this._productId) : super(const AsyncValue.loading()) {
    _load();
  }

  static const String _prefsKey = 'product_reviews_v1';
  final int _productId;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.trim().isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        state = const AsyncValue.data([]);
        return;
      }
      final listRaw = decoded[_productId.toString()];
      if (listRaw is! List) {
        state = const AsyncValue.data([]);
        return;
      }
      final reviews = listRaw
          .whereType<Map>()
          .map((e) => ProductReview.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(reviews);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addReview({
    required int rating,
    required String comment,
    required String userName,
    int? userId,
  }) async {
    final trimmed = comment.trim();
    if (trimmed.isEmpty) return;

    final review = ProductReview(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: _productId,
      userId: userId,
      userName: userName.trim().isEmpty ? 'User' : userName.trim(),
      rating: rating.clamp(1, 5),
      comment: trimmed,
      createdAt: DateTime.now(),
    );

    final current = state.asData?.value ?? const <ProductReview>[];
    final next = [review, ...current];
    state = AsyncValue.data(next);

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      final decoded = raw == null || raw.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw);
      final map =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

      map[_productId.toString()] = next.map((r) => r.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (_) {
      // Keep UI state updated even if persistence fails.
      // (We intentionally don't surface this as an error to avoid breaking the screen.)
    }
  }

  Future<void> refresh() => _load();
}

final productReviewsProvider = StateNotifierProvider.family<
    ProductReviewsNotifier,
    AsyncValue<List<ProductReview>>,
    int>((ref, productId) {
  return ProductReviewsNotifier(productId);
});

// -----------------------------
// Saved Routines
// -----------------------------

class SavedRoutine {
  final int id;
  final int customerId;
  final int? scanId;
  final String title;
  final String routineText;
  final DateTime createdAt;

  SavedRoutine({
    required this.id,
    required this.customerId,
    this.scanId,
    required this.title,
    required this.routineText,
    required this.createdAt,
  });

  factory SavedRoutine.fromJson(Map<String, dynamic> json) {
    return SavedRoutine(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      customerId: json['customer_id'] is String
          ? int.parse(json['customer_id'])
          : json['customer_id'] as int,
      scanId: json['scan_id'] != null
          ? (json['scan_id'] is String
              ? int.tryParse(json['scan_id'])
              : json['scan_id'] as int?)
          : null,
      title: json['title'] as String? ?? 'روتين مخصص',
      routineText: json['routine_text'] as String? ?? '',
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

final savedRoutinesProvider = FutureProvider<List<SavedRoutine>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final data = await apiClient.getRoutines();
  return data.map((json) => SavedRoutine.fromJson(json)).toList();
});
