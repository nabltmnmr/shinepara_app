import 'dart:convert';

class SkinScan {
  final int id;
  final int customerId;
  final String? imageUrl;
  final String areaType;
  final Map<String, dynamic> metrics;
  final int serverOverallScore;
  final String? summary;
  final String? routine;
  final String? modelUsed;
  final double? confidence;
  final DateTime createdAt;

  SkinScan({
    required this.id,
    required this.customerId,
    this.imageUrl,
    required this.areaType,
    required this.metrics,
    this.serverOverallScore = 0,
    this.summary,
    this.routine,
    this.modelUsed,
    this.confidence,
    required this.createdAt,
  });

  factory SkinScan.fromJson(Map<String, dynamic> json) {
    // Handle metrics - could be a string (JSON) or already a Map
    Map<String, dynamic> metricsMap = {};
    final metricsData = json['metrics'];
    if (metricsData is Map<String, dynamic>) {
      metricsMap = metricsData;
    } else if (metricsData is Map) {
      metricsMap = Map<String, dynamic>.from(metricsData);
    } else if (metricsData is String && metricsData.isNotEmpty) {
      try {
        final decoded = jsonDecode(metricsData);
        if (decoded is Map) {
          metricsMap = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        metricsMap = {};
      }
    }
    
    return SkinScan(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      imageUrl: json['image_url'] as String?,
      areaType: json['area_type'] as String? ?? 'face',
      metrics: metricsMap,
      serverOverallScore: json['overall_score'] as int? ?? 0,
      summary: json['summary_text'] as String? ?? json['summary'] as String?,
      routine: json['routine'] as String?,
      modelUsed: json['model_used'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'image_url': imageUrl,
      'area_type': areaType,
      'metrics': metrics,
      'overall_score': serverOverallScore,
      'summary_text': summary,
      'routine': routine,
      'model_used': modelUsed,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }

  int get overallScore {
    // Use server-provided score if available
    if (serverOverallScore > 0) return serverOverallScore;
    
    // Fallback calculation if server score not available
    if (metrics.isEmpty) return 50;
    
    // Calculate from metrics (lower values = better skin)
    final issueKeys = ['acne', 'redness', 'hyperpigmentation', 'pores', 'texture', 'wrinkles', 'oiliness', 'dryness', 'sensitivity'];
    int total = 0;
    int count = 0;
    for (final key in issueKeys) {
      final value = (metrics[key] as num?)?.toInt();
      if (value != null) {
        total += (100 - value); // Convert issue score to health score
        count++;
      }
    }
    return count > 0 ? (total / count).round() : 50;
  }

  int getMetricValue(String key) {
    return (metrics[key] as num?)?.toInt() ?? 0;
  }
}

class ScanCredits {
  final int credits;
  final bool canClaimShareReward;

  ScanCredits({
    required this.credits,
    required this.canClaimShareReward,
  });

  factory ScanCredits.fromJson(Map<String, dynamic> json) {
    return ScanCredits(
      credits: json['credits'] as int? ?? 0,
      canClaimShareReward: json['can_claim_share_reward'] as bool? ?? true,
    );
  }
}

class ScanComparison {
  final int id;
  final SkinScan scan1;
  final SkinScan scan2;
  final Map<String, dynamic> delta;
  final String? aiInsights;
  final DateTime createdAt;

  ScanComparison({
    required this.id,
    required this.scan1,
    required this.scan2,
    required this.delta,
    this.aiInsights,
    required this.createdAt,
  });

  factory ScanComparison.fromJson(Map<String, dynamic> json) {
    return ScanComparison(
      id: json['id'] as int,
      scan1: SkinScan.fromJson(json['scan1'] as Map<String, dynamic>),
      scan2: SkinScan.fromJson(json['scan2'] as Map<String, dynamic>),
      delta: json['delta'] as Map<String, dynamic>? ?? {},
      aiInsights: json['ai_insights'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
