import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      status: json['status'] as String? ?? 'generating',
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
    final response = await _invokeFunction(
      _client,
      functionName,
      materialId: materialId,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CoreConceptExtractionResult.fromJson(data);
    }
    if (data is Map) {
      return CoreConceptExtractionResult.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw StateError('extract-core-concepts returned an invalid response.');
  }
}

class FirstQuizGenerationResult {
  const FirstQuizGenerationResult({
    required this.materialId,
    required this.status,
    required this.questionCount,
    required this.reused,
    required this.message,
  });

  final String materialId;
  final String status;
  final int questionCount;
  final bool reused;
  final String message;

  factory FirstQuizGenerationResult.fromJson(Map<String, dynamic> json) {
    return FirstQuizGenerationResult(
      materialId: json['materialId'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      questionCount: CoreConceptExtractionResult._intFrom(
        json['questionCount'] ?? json['questionsCount'] ?? json['count'],
      ),
      reused: json['reused'] as bool? ?? json['usedCache'] as bool? ?? false,
      message: json['message'] as String? ?? 'First quiz generated.',
    );
  }
}

class FirstQuizGenerationDataSource {
  const FirstQuizGenerationDataSource(this._client);

  static const functionName = 'generate-first-quiz';

  final SupabaseClient _client;

  Future<FirstQuizGenerationResult> generateFirstQuiz({
    required String materialId,
  }) async {
    final response = await _invokeFunction(
      _client,
      functionName,
      materialId: materialId,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return FirstQuizGenerationResult.fromJson(data);
    }
    if (data is Map) {
      return FirstQuizGenerationResult.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw StateError('generate-first-quiz returned an invalid response.');
  }
}

Future<FunctionResponse> _invokeFunction(
  SupabaseClient client,
  String functionName, {
  required String materialId,
}) async {
  final stopwatch = Stopwatch()..start();
  _logEdgeStop(
    'STOP-15 edge.function.invoke.start',
    functionName: functionName,
    materialId: materialId,
    elapsedMs: 0,
  );
  try {
    final response = await client.functions.invoke(
      functionName,
      body: {'materialId': materialId},
    );
    _logEdgeStop(
      'STOP-16 edge.function.invoke.success',
      functionName: functionName,
      materialId: materialId,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );
    return response;
  } on FunctionException catch (error, stackTrace) {
    _logEdgeStop(
      'STOP-15 edge.function.invoke.start',
      functionName: functionName,
      materialId: materialId,
      elapsedMs: stopwatch.elapsedMilliseconds,
      exception: error,
      stackTrace: stackTrace,
    );
    throw StateError(_functionErrorMessage(functionName, error));
  } catch (error, stackTrace) {
    _logEdgeStop(
      'STOP-15 edge.function.invoke.start',
      functionName: functionName,
      materialId: materialId,
      elapsedMs: stopwatch.elapsedMilliseconds,
      exception: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

void _logEdgeStop(
  String stopPoint, {
  required String functionName,
  required String materialId,
  int? elapsedMs,
  Object? exception,
  StackTrace? stackTrace,
}) {
  final payload = jsonEncode({
    'stopPoint': stopPoint,
    'materialId': materialId,
    'materialTitle': null,
    'fileExtension': null,
    'fileSize': null,
    'bytesLength': null,
    'elapsedMs': elapsedMs,
    'rawTextLength': null,
    'structuredTextLength': null,
    'extractorName': functionName,
    'isFlutterWeb': kIsWeb,
    'exceptionMessage': exception?.toString(),
    'stackTrace': stackTrace?.toString(),
  });

  debugPrint('[upload-flow] $payload');
}

String _functionErrorMessage(String functionName, FunctionException error) {
  final details = error.details;
  if (details is Map) {
    final code = details['code']?.toString();
    final message =
        details['error']?.toString() ?? details['message']?.toString();
    final suffix = code == null || code.isEmpty ? '' : '$code: ';
    if (message != null && message.isNotEmpty) {
      return '$functionName failed (${error.status}): $suffix$message';
    }
  }
  if (details is String && details.isNotEmpty) {
    return '$functionName failed (${error.status}): $details';
  }
  return '$functionName failed (${error.status}).';
}
