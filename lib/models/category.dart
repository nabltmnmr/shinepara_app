class Category {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? iconUrl;
  final String? imageUrl;
  final int sortOrder;

  Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.iconUrl,
    this.imageUrl,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      nameAr: json['name_ar'] as String? ?? json['nameAr'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String? ?? '',
      iconUrl: json['icon_url'] as String? ?? json['iconUrl'] as String?,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'icon_url': iconUrl,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    };
  }
}
