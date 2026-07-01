import 'package:supabase_flutter/supabase_flutter.dart';

class CoreConceptExtractionResult {
  const CoreConceptExtractionResult({
    required this.materialId,
    required this.status,
    required this.conceptCount,
    required this.usedCache,
    required this.message,
  });

  final String materialId;
  final String status;
  final int conceptCount;
  final bool usedCache;
  final String message;

  factory CoreConceptExtractionResult.fromJson(Map<String, dynamic> json) {
    return CoreConceptExtractionResult(
      materialId: json['materialId'] as String? ?? '',
      status: json['status'] as String? ?? 'concepts_completed',
      conceptCount: _intFrom(json['conceptCount']),
      usedCache: json['usedCache'] as bool? ?? false,
      message: json['message'] as String? ?? 'Core concepts extracted.',
    );
  }

  static int _intFrom(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CoreConceptExtractionDataSource {
  const CoreConceptExtractionDataSource(this._client);

  static const functionName = 'extract-core-concepts';

  final SupabaseClient _client;

  Future<CoreConceptExtractionResult> extractConcepts({
    required String materialId,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: {'materialId': materialId},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CoreConceptExtractionResult.fromJson(data);
    }
    if (data is Map) {
      return CoreConceptExtractionResult.fromJson(Map<String, dynamic>.from(data));
    }

    throw StateError('extract-core-concepts returned an invalid response.');
  }
}