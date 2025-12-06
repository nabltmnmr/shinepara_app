class Category {
  final String id;
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
      id: (json['id'] ?? '').toString(),
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? json['name_en'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? json['icon_url'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
    };
  }
}
