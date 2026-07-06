class MemorySeed {
  const MemorySeed({
    required this.id,
    required this.userId,
    required this.seedType,
    required this.growthStage,
    required this.growthValue,
    required this.maxGrowthValue,
    required this.status,
    required this.assetKey,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory MemorySeed.fromJson(Map<String, dynamic> json) {
    return MemorySeed(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      seedType: json['seed_type'] as String? ?? 'blossom',
      growthStage: json['growth_stage'] as String? ?? 'seed',
      growthValue: _intFrom(json['growth_value']),
      maxGrowthValue: _intFrom(json['max_growth_value'], fallback: 100),
      status: json['status'] as String? ?? 'growing',
      assetKey: json['asset_key'] as String? ?? 'seed_blossom_seed',
      createdAt: _dateFrom(json['created_at']) ?? DateTime.now(),
      updatedAt: _dateFrom(json['updated_at']) ?? DateTime.now(),
      completedAt: _dateFrom(json['completed_at']),
    );
  }

  final String id;
  final String userId;
  final String seedType;
  final String growthStage;
  final int growthValue;
  final int maxGrowthValue;
  final String status;
  final String assetKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  double get progress => maxGrowthValue <= 0 ? 0 : (growthValue / maxGrowthValue).clamp(0, 1).toDouble();
  bool get isCompleted => status == 'completed';

  String get stageLabel {
    return switch (growthStage) {
      'seed' => '씨앗',
      'sprout' => '새싹',
      'leaf' => '잎새',
      'flower' => '개화',
      'complete' => '완성',
      _ => growthStage,
    };
  }

  String get seedTypeLabel {
    return switch (seedType) {
      'blossom' => '벚꽃 기억씨앗',
      'baobab' => '바오밥 기억씨앗',
      'maple' => '단풍 기억씨앗',
      'ginkgo' => '은행 기억씨앗',
      'aurora' => '오로라 기억씨앗',
      _ => '기억씨앗',
    };
  }

  static int _intFrom(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _dateFrom(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class MemorySeedGrowthResult {
  const MemorySeedGrowthResult({
    required this.seed,
    required this.growthDelta,
    required this.completedNow,
  });

  final MemorySeed seed;
  final int growthDelta;
  final bool completedNow;
}
