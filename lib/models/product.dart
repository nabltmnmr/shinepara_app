class Product {
  final int id;
  final String nameAr;
  final String nameEn;
  final int brandId;
  final int categoryId;
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
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      nameAr: json['name_ar'] as String? ?? json['nameAr'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String? ?? '',
      brandId: json['brand_id'] is String ? int.parse(json['brand_id']) : (json['brand_id'] as int? ?? json['brandId'] as int? ?? 0),
      categoryId: json['category_id'] is String ? int.parse(json['category_id']) : (json['category_id'] as int? ?? json['categoryId'] as int? ?? 0),
      brandName: json['brand_name'] as String?,
      categoryName: json['category_name'] as String?,
      descriptionAr: json['description_ar'] as String? ?? json['descriptionAr'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? json['descriptionEn'] as String? ?? '',
      price: _parseDouble(json['price']),
      salePrice: json['sale_price'] != null ? _parseDouble(json['sale_price']) : null,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      stock: json['stock'] as int? ?? 0,
      skinTypes: _parseStringList(json['skin_types'] ?? json['skinTypes']),
      concerns: _parseStringList(json['concerns']),
      usage: json['usage'] as String?,
      ingredients: json['ingredients'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
      'name_ar': nameAr,
      'name_en': nameEn,
      'brand_id': brandId,
      'category_id': categoryId,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'price': price,
      'sale_price': salePrice,
      'image_url': imageUrl,
      'stock': stock,
      'skin_types': skinTypes,
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
