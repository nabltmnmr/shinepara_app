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

  static String? _convertGoogleDriveUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Check if it's a Google Drive sharing link
    final drivePattern = RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
    final match = drivePattern.firstMatch(url);
    
    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    
    return url;
  }

  factory Brand.fromJson(Map<String, dynamic> json) {
    final rawLogoUrl = json['logo_url'] as String? ?? json['logoUrl'] as String?;
    return Brand(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String? ?? '',
      logoUrl: _convertGoogleDriveUrl(rawLogoUrl),
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
