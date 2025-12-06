class AIRecommendation {
  final String productId;
  final String productName;
  final String brand;
  final String reason;
  final String usage;
  final String? imageUrl;

  AIRecommendation({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.reason,
    required this.usage,
    this.imageUrl,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      brand: json['brand'] as String,
      reason: json['reason'] as String,
      usage: json['usage'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'brand': brand,
      'reason': reason,
      'usage': usage,
      'image_url': imageUrl,
    };
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<AIRecommendation>? recommendations;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.recommendations,
  });
}

class AIResponse {
  final String answer;
  final List<AIRecommendation> recommendations;

  AIResponse({
    required this.answer,
    required this.recommendations,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      answer: json['answer'] as String,
      recommendations: (json['recommendations'] as List?)
              ?.map((e) => AIRecommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
