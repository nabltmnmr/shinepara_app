class Product {
  final int id;
  final String nameAr;
  final String nameEn;
  final int brandId;
  final String categoryId;
  final String? brandName;
  final String? categoryName;
  final String descriptionAr;
  final String descriptionEn;
  final double price;
  final double? salePrice;
  final String? imageUrl;
  final int stock;
  final List<String> skinTypes;
  final List<String> concerns;
  final String? usage;
  final String? ingredients;
  final bool isActive;

  Product({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.brandId,
    required this.categoryId,
    this.brandName,
    this.categoryName,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.price,
    this.salePrice,
    this.imageUrl,
    this.stock = 0,
    this.skinTypes = const [],
    this.concerns = const [],
    this.usage,
    this.ingredients,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _parseInt(json['id']),
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? json['name_en'] as String? ?? '',
      brandId: _parseInt(json['brandId'] ?? json['brand_id']),
      categoryId: (json['categoryId'] ?? json['category_id'] ?? '').toString(),
      brandName: json['brandName'] as String? ?? json['brand_name'] as String?,
      categoryName: json['categoryName'] as String? ?? json['category_name'] as String?,
      descriptionAr: json['descriptionAr'] as String? ?? json['description_ar'] as String? ?? json['full_description'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? json['description_en'] as String? ?? '',
      price: _parseDouble(json['price']),
      salePrice: _parseSalePrice(json),
      imageUrl: _parseImageUrl(json),
      stock: json['stock'] as int? ?? 0,
      skinTypes: _parseStringList(json['skinTypes'] ?? json['skin_types']),
      concerns: _parseStringList(json['concerns']),
      usage: json['usage'] as String?,
      ingredients: json['ingredients'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _parseSalePrice(Map<String, dynamic> json) {
    final salePrice = json['salePrice'] ?? json['sale_price'] ?? json['oldPrice'] ?? json['old_price'];
    if (salePrice == null) return null;
    return _parseDouble(salePrice);
  }

  static String? _parseImageUrl(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl'] ?? json['image_url'];
    if (imageUrl != null) return imageUrl as String;
    
    final images = json['images'];
    if (images != null && images is List && images.isNotEmpty) {
      return images[0].toString();
    }
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      if (value.isEmpty) return [];
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'brandId': brandId,
      'categoryId': categoryId,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'price': price,
      'salePrice': salePrice,
      'imageUrl': imageUrl,
      'stock': stock,
      'skinTypes': skinTypes,
      'concerns': concerns,
      'usage': usage,
      'ingredients': ingredients,
    };
  }

  bool get hasDiscount => salePrice != null && salePrice! < price;
  
  double get displayPrice => salePrice ?? price;
  
  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((price - salePrice!) / price * 100).roundToDouble();
  }
}
