class CoreConceptModel {
  const CoreConceptModel({
    required this.name,
    required this.description,
    required this.importance,
    required this.evidence,
  });

  final String name;
  final String description;
  final int importance;
  final String evidence;

  factory CoreConceptModel.fromJson(Map<String, dynamic> json) {
    return CoreConceptModel(
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      importance: _importanceFrom(json['importance']),
      evidence: (json['evidence'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toInsertJson({
    required String userId,
    required String materialId,
  }) {
    return {
      'user_id': userId,
      'material_id': materialId,
      'name': name,
      'description': description,
      'importance': importance,
      'evidence': {'text': evidence},
    };
  }

  static int _importanceFrom(Object? value) {
    if (value is int) {
      return value.clamp(1, 5).toInt();
    }
    if (value is num) {
      return value.round().clamp(1, 5).toInt();
    }
    return (int.tryParse(value?.toString() ?? '') ?? 3).clamp(1, 5).toInt();
  }
}