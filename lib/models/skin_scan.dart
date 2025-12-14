class SkinScan {
  final int id;
  final int customerId;
  final String? imageUrl;
  final String areaType;
  final Map<String, dynamic> metrics;
  final String? summary;
  final String? routine;
  final DateTime createdAt;

  SkinScan({
    required this.id,
    required this.customerId,
    this.imageUrl,
    required this.areaType,
    required this.metrics,
    this.summary,
    this.routine,
    required this.createdAt,
  });

  factory SkinScan.fromJson(Map<String, dynamic> json) {
    return SkinScan(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      imageUrl: json['image_url'] as String?,
      areaType: json['area_type'] as String? ?? 'face',
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
      summary: json['summary'] as String?,
      routine: json['routine'] as String?,
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
      'summary': summary,
      'routine': routine,
      'created_at': createdAt.toIso8601String(),
    };
  }

  int get overallScore {
    if (metrics.isEmpty) return 0;
    final scores = [
      (metrics['hydration'] as num?)?.toInt() ?? 0,
      (metrics['oiliness'] as num?)?.toInt() ?? 0,
      (metrics['texture'] as num?)?.toInt() ?? 0,
      (metrics['pores'] as num?)?.toInt() ?? 0,
      (metrics['spots'] as num?)?.toInt() ?? 0,
      (metrics['wrinkles'] as num?)?.toInt() ?? 0,
    ];
    return (scores.reduce((a, b) => a + b) / scores.length).round();
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
