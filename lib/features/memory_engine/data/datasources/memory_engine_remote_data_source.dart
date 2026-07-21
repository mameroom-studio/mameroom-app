import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/memory_engine_result.dart';

class MemoryEngineRemoteDataSource {
  const MemoryEngineRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<MemoryEngineResult> submit(MemoryEngineSubmission submission) =>
      _invoke({
        'action': 'submit',
        'submissionId': submission.submissionId ?? _uuidV4(),
        'sessionId': submission.sessionId,
        'questionId': submission.questionId,
        'selectedAnswer': submission.selectedAnswer,
        'isCorrect': submission.isCorrect,
        'responseTimeMs': submission.responseTimeMs,
        'retryCount': submission.retryCount,
        'hintLevel': submission.hintLevel,
        'isPass': false,
      });

  Future<MemoryEngineResult> pass(MemoryEnginePass pass) => _invoke({
    'action': 'submit',
    'submissionId': pass.submissionId ?? _uuidV4(),
    'sessionId': pass.sessionId,
    'questionId': pass.questionId,
    'selectedAnswer': '',
    'isCorrect': false,
    'responseTimeMs': 0,
    'retryCount': 0,
    'hintLevel': 0,
    'isPass': true,
    'passReason': pass.reason,
  });

  Future<Map<String, dynamic>> loadDue({
    int limit = 20,
    bool countOnly = false,
  }) async {
    final response = await _client.functions.invoke(
      'memory-engine-v2',
      body: {'action': 'due', 'limit': limit, 'countOnly': countOnly},
    );
    return _map(response.data);
  }

  Future<MemoryEngineResult> _invoke(Map<String, dynamic> body) async {
    FunctionResponse? response;
    Object? firstError;
    for (var attempt = 0; attempt < 2; attempt += 1) {
      try {
        response = await _client.functions.invoke(
          'memory-engine-v2',
          body: body,
        );
        break;
      } catch (error) {
        firstError ??= error;
        if (attempt > 0) rethrow;
      }
    }
    if (response == null) throw firstError!;
    final data = _map(response.data);
    return MemoryEngineResult(
      submissionId:
          data['submission_id']?.toString() ?? body['submissionId'] as String,
      reviewedAt: DateTime.parse(data['reviewed_at'].toString()).toUtc(),
      scheduleChanged: data['schedule_changed'] == true,
      duplicate: data['duplicate'] == true,
      state: data['state']?.toString(),
      dueAt: DateTime.tryParse(data['due_at']?.toString() ?? '')?.toUtc(),
      stability: _double(data['stability']),
      difficulty: _double(data['difficulty']),
      stateVersion: _int(data['state_version']),
    );
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw StateError('Memory Engine returned an invalid response.');
  }

  static double? _double(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
