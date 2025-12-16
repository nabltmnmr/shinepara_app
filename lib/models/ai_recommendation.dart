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
      productId: (json['product_id'] ?? json['productId'] ?? '').toString(),
      productName: (json['product_name'] ?? json['productName'] ?? 'منتج').toString(),
      brand: (json['brand'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      usage: (json['usage'] ?? '').toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
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
  
  bool get isValid => productId.isNotEmpty && productName.isNotEmpty;
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
    final List<AIRecommendation> recs = [];
    final rawRecs = json['recommendations'] as List?;
    if (rawRecs != null) {
      for (final item in rawRecs) {
        try {
          if (item is Map<String, dynamic>) {
            final rec = AIRecommendation.fromJson(item);
            if (rec.isValid) {
              recs.add(rec);
            }
          }
        } catch (e) {
          print('Error parsing recommendation: $e');
        }
      }
    }
    
    return AIResponse(
      answer: (json['answer'] ?? 'عذراً، لم أتمكن من معالجة طلبك').toString(),
      recommendations: recs,
    );
  }
}
