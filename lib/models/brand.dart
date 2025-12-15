class Brand {
  final int id;
  final String name;
  final String? logoUrl;
  final String? description;
  final bool hasNewProducts;

  Brand({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
    this.hasNewProducts = false,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? json['logoUrl'] as String?,
      description: json['description'] as String?,
      hasNewProducts: json['has_new_products'] as bool? ?? json['hasNewProducts'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'description': description,
      'has_new_products': hasNewProducts,
    };
  }
}
