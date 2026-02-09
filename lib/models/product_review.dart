class ProductReview {
  final String id;
  final int productId;
  final int? userId;
  final String userName;
  final int rating; // 1..5
  final String comment;
  final DateTime createdAt;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userId,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: (json['id'] ?? '').toString(),
      productId: _parseInt(json['productId'] ?? json['product_id']),
      userId: json['userId'] == null ? null : _parseInt(json['userId']),
      userName: (json['userName'] ?? json['user_name'] ?? '').toString(),
      rating: _parseInt(json['rating']).clamp(1, 5),
      comment: (json['comment'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(
            _parseInt(json['created_at_ms']),
            isUtc: false,
          ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

