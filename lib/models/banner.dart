class HomeBanner {
  final int id;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int sortOrder;

  HomeBanner({
    required this.id,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.linkUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      linkUrl: json['link_url'] as String? ?? json['linkUrl'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
