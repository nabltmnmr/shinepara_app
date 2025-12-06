import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'api_client.dart';

const String apiBaseUrl = 'https://shine-flutter-doc--nabltmnmr.replit.app';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: apiBaseUrl);
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

final productsProvider = FutureProvider.family<List<Product>, ProductFilter>((ref, filter) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getProducts(
    categoryId: filter.categoryId,
    brandId: filter.brandId,
    searchQuery: filter.searchQuery,
  );
});

final productDetailProvider = FutureProvider.family<Product?, int>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getProductById(id);
});

final shippingSettingsProvider = FutureProvider<ShippingSettings>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getShippingSettings();
});

class ProductFilter {
  final int? categoryId;
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
  int get hashCode => categoryId.hashCode ^ brandId.hashCode ^ searchQuery.hashCode;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product) {
    final existingIndex = state.indexWhere((item) => item.productId == product.id);
    if (existingIndex >= 0) {
      state = [
        ...state.sublist(0, existingIndex),
        state[existingIndex].copyWith(quantity: state[existingIndex].quantity + 1),
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
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, Set<int>>((ref) {
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

  AuthNotifier(this.apiClient) : super(null);

  Future<void> checkAuthStatus() async {
    isLoading = true;
    try {
      final user = await apiClient.getCurrentUser();
      state = user;
    } catch (e) {
      state = null;
    } finally {
      isLoading = false;
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

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
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
      final response = await apiClient.getAIRecommendation(query: content);
      
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

final aiChatProvider = StateNotifierProvider<AIChatNotifier, List<ChatMessage>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIChatNotifier(apiClient);
});

final searchQueryProvider = StateProvider<String>((ref) => '');
