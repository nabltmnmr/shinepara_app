import 'dart:convert';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final s = v.trim();
    return int.tryParse(s) ?? double.tryParse(s)?.toInt();
  }
  return null;
}

bool? _toBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
  }
  if (v is num) return v != 0;
  return null;
}

class SkinMetric {
  final int value;
  final double confidence;
  final bool isEstimated;
  final String? notes;
  final String nameAr;
  final String nameEn;
  final String description;
  final String tips;

  SkinMetric({
    required this.value,
    required this.confidence,
    required this.isEstimated,
    this.notes,
    required this.nameAr,
    required this.nameEn,
    required this.description,
    required this.tips,
  });

  factory SkinMetric.fromJson(Map<String, dynamic> json) {
    return SkinMetric(
      value: _toInt(json['value']) ?? 0,
      confidence: _toDouble(json['confidence']) ?? 0.8,
      isEstimated: _toBool(json['isEstimated']) ?? false,
      notes: json['notes'] as String?,
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tips: json['tips'] as String? ?? '',
    );
  }
}

class SkinVisualization {
  final String imageUrl;
  final String nameAr;
  final String nameEn;
  final String description;
  final String tips;
  final bool isEstimated;

  SkinVisualization({
    required this.imageUrl,
    required this.nameAr,
    required this.nameEn,
    required this.description,
    required this.tips,
    required this.isEstimated,
  });

  factory SkinVisualization.fromJson(Map<String, dynamic> json) {
    return SkinVisualization(
      imageUrl: json['imageUrl'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tips: json['tips'] as String? ?? '',
      isEstimated: _toBool(json['isEstimated']) ?? false,
    );
  }
}

class ScanRecommendedProduct {
  final int id;
  final String nameAr;
  final String? nameEn;
  final String? brandName;
  final double price;
  final String? imageUrl;
  final String? shortDescription;
  final List<String> matchedConcerns;

  ScanRecommendedProduct({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.brandName,
    required this.price,
    this.imageUrl,
    this.shortDescription,
    this.matchedConcerns = const [],
  });

  factory ScanRecommendedProduct.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    String? imgUrl;
    if (images is List && images.isNotEmpty) {
      imgUrl = images[0] as String?;
    } else if (images is String && images.isNotEmpty) {
      imgUrl = images;
    }

    List<String> concerns = [];
    if (json['matchedConcerns'] is List) {
      concerns = (json['matchedConcerns'] as List).map((e) => e.toString()).toList();
    }

    return ScanRecommendedProduct(
      id: _toInt(json['id']) ?? 0,
      nameAr: json['name_ar'] as String? ?? json['nameAr'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String?,
      brandName: json['brand_name'] as String? ?? json['brandName'] as String?,
      price: _toDouble(json['price']) ?? 0,
      imageUrl: imgUrl,
      shortDescription: json['short_description'] as String? ?? json['shortDescription'] as String?,
      matchedConcerns: concerns,
    );
  }
}

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
  final double? qualityScore;
  final double? lightingScore;
  final Map<String, SkinMetric> metricDetails;
  final Map<String, SkinVisualization> visualizations;
  final List<ScanRecommendedProduct> recommendedProducts;
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
    this.qualityScore,
    this.lightingScore,
    this.metricDetails = const {},
    this.visualizations = const {},
    this.recommendedProducts = const [],
    required this.createdAt,
  });

  factory SkinScan.fromJson(Map<String, dynamic> json) {
    // ---- metrics parsing (supports Map or JSON string) ----
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

    // ---- metricDetails parsing ----
    Map<String, SkinMetric> metricDetails = {};
    final detailsAny = json['metricDetails'];
    if (detailsAny is Map) {
      for (final entry in detailsAny.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (val is Map) {
          metricDetails[key] = SkinMetric.fromJson(Map<String, dynamic>.from(val));
        }
      }
    }

    // ---- visualizations parsing ----
    Map<String, SkinVisualization> visualizations = {};
    final vizAny = json['visualizations'];
    if (vizAny is Map) {
      for (final entry in vizAny.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (val is Map) {
          visualizations[key] =
              SkinVisualization.fromJson(Map<String, dynamic>.from(val));
        }
      }
    }

    final id = _toInt(json['id']) ?? 0;
    final customerId = _toInt(json['customer_id']) ?? 0;

    DateTime createdAt;
    try {
      final raw = json['created_at'];
      if (raw is String && raw.isNotEmpty) {
        createdAt = DateTime.parse(raw);
      } else {
        createdAt = DateTime.now();
      }
    } catch (_) {
      createdAt = DateTime.now();
    }

    // ---- recommendations parsing ----
    List<ScanRecommendedProduct> recommendedProducts = [];
    final recsAny = json['recommendations'];
    if (recsAny is Map) {
      final productsList = recsAny['products'];
      if (productsList is List) {
        for (final p in productsList) {
          if (p is Map) {
            recommendedProducts.add(ScanRecommendedProduct.fromJson(Map<String, dynamic>.from(p)));
          }
        }
      }
    }

    return SkinScan(
      id: id,
      customerId: customerId,
      imageUrl: json['image_url'] as String?,
      areaType: json['area_type'] as String? ?? 'face',
      metrics: metricsMap,
      serverOverallScore: _toInt(json['overall_score']) ?? 0,
      summary: (json['summary_text'] as String?) ?? (json['summary'] as String?),
      routine: json['routine'] as String?,
      modelUsed: json['model_used'] as String?,
      confidence: _toDouble(json['confidence']),
      qualityScore: _toDouble(json['quality_score']),
      lightingScore: _toDouble(json['lighting_score']),
      metricDetails: metricDetails,
      visualizations: visualizations,
      recommendedProducts: recommendedProducts,
      createdAt: createdAt,
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
      'quality_score': qualityScore,
      'lighting_score': lightingScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  int get overallScore {
    if (serverOverallScore > 0) return serverOverallScore;
    if (metrics.isEmpty) return 50;

    int total = 0;
    int count = 0;
    for (final entry in metrics.entries) {
      final value = _toInt(entry.value);
      if (value != null) {
        total += (100 - value);
        count++;
      }
    }
    return count > 0 ? (total / count).round() : 50;
  }

  int getMetricValue(String key) {
    if (metricDetails.containsKey(key)) {
      return metricDetails[key]!.value;
    }
    return _toInt(metrics[key]) ?? 0;
  }

  static const List<String> metricKeys = [
    'rgb_pores',
    'rgb_color_spot',
    'rgb_texture',
    'pl_roughness',
    'uv_acne',
    'uv_color_spot',
    'uv_roughness',
    'skin_evenness',
    'brown_area',
    'uv_spot',
    'skin_aging',
    'skin_brightness',
  ];

  static const Map<String, String> metricNamesAr = {
    'rgb_pores': 'المسام',
    'rgb_color_spot': 'البقع اللونية',
    'rgb_texture': 'ملمس البشرة',
    'pl_roughness': 'خشونة البشرة',
    'uv_acne': 'حب الشباب',
    'uv_color_spot': 'التصبغات العميقة',
    'uv_roughness': 'الخشونة العميقة',
    'skin_evenness': 'تجانس اللون',
    'brown_area': 'المناطق الداكنة',
    'uv_spot': 'البقع الشمسية',
    'skin_aging': 'علامات الشيخوخة',
    'skin_brightness': 'إشراقة البشرة',
  };
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
      credits: _toInt(json['credits']) ?? 0,
      canClaimShareReward: _toBool(json['can_claim_share_reward']) ?? true,
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
      id: _toInt(json['id']) ?? 0,
      scan1: SkinScan.fromJson(Map<String, dynamic>.from(json['scan1'] as Map)),
      scan2: SkinScan.fromJson(Map<String, dynamic>.from(json['scan2'] as Map)),
      delta: (json['delta'] is Map)
          ? Map<String, dynamic>.from(json['delta'] as Map)
          : <String, dynamic>{},
      aiInsights: json['ai_insights'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
