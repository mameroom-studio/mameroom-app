import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_tables.dart';
import '../../../../core/config/env.dart';
import '../../../memory_engine/data/datasources/memory_engine_remote_data_source.dart';
import '../../../memory_engine/domain/entities/memory_engine_result.dart';
import '../../domain/entities/question.dart';
import '../models/question_model.dart';

class QuizRemoteDataSource {
  const QuizRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<QuizInitialLoad> loadInitialQuestions({
    required String materialId,
    bool unlearnedOnly = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to load quiz questions.');
    }

    final material = await _client
        .from(SupabaseTables.studyMaterials)
        .select('id,status,title')
        .eq('id', materialId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (material == null) {
      throw StateError('Study material was not found.');
    }
    if (material['status'] != 'completed') {
      throw StateError(
        'Quiz is available only after material status is completed.',
      );
    }

    final rows = await _client
        .from(SupabaseTables.questions)
        .select(
          'id,material_id,concept_id,section_id,type,question_text,options,answer,explanation,evidence,difficulty,order_index',
        )
        .eq('user_id', user.id)
        .eq('material_id', materialId)
        .eq('initial_batch', true)
        .eq('type', 'multiple_choice')
        .order('order_index', ascending: true)
        .limit(10);

    final passFilter = await _loadPassFilter(
      userId: user.id,
      materialId: materialId,
    );

    final attemptedIds = unlearnedOnly
        ? await _loadAttemptedQuestionIds(user.id)
        : const <String>{};

    final questions = rows
        .map(
          (row) => QuestionModel.fromJson(
            _sanitizeQuestionRow(Map<String, dynamic>.from(row as Map)),
          ),
        )
        .where(passFilter.allowsQuestion)
        .where(_isEligibleMultipleChoice)
        .where((question) => !attemptedIds.contains(question.id))
        .toList(growable: false);

    return QuizInitialLoad(
      materialTitle: _safeDisplayText(material['title']) ?? '학습 자료',
      questions: questions,
    );
  }

  Future<Set<String>> _loadAttemptedQuestionIds(String userId) async {
    final rows = await _client
        .from(SupabaseTables.quizAttempts)
        .select('question_id')
        .eq('user_id', userId);
    return rows
        .map((row) => (row as Map)['question_id']?.toString())
        .whereType<String>()
        .toSet();
  }

  bool _isEligibleMultipleChoice(Question question) {
    if (question.type != QuizQuestionType.multipleChoice ||
        question.options.length < 2 ||
        question.answer.trim().isEmpty) {
      return false;
    }
    final answer = question.answer.trim().toLowerCase();
    return question.options.any(
      (option) => option.trim().toLowerCase() == answer,
    );
  }

  Map<String, dynamic> _sanitizeQuestionRow(Map<String, dynamic> row) {
    row['question_text'] =
        _safeDisplayText(row['question_text']) ?? '문제 문장을 다시 생성해야 합니다.';
    row['answer'] = _safeDisplayText(row['answer']) ?? '정답을 다시 생성해야 합니다.';
    row['explanation'] =
        _safeDisplayText(row['explanation']) ?? '해설을 다시 생성해야 합니다.';
    final evidence = row['evidence'];
    if (evidence is Map) {
      row['evidence'] = {
        ...evidence,
        'text': _safeDisplayText(evidence['text']) ?? '',
      };
    } else {
      row['evidence'] = {'text': _safeDisplayText(evidence) ?? ''};
    }
    final options = row['options'];
    if (options is List) {
      row['options'] = options
          .map(_safeDisplayText)
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false);
    }
    return row;
  }

  String? _safeDisplayText(Object? value) {
    if (value == null) return null;
    final sanitized = value
        .toString()
        .replaceAll(_uuidPattern, '')
        .replaceAll(_storagePathPattern, '')
        .replaceAll(
          RegExp(
            r'\b(?:material|concept|question|section|source)[_-]?id\b\s*[:=]?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\b(?:materialId|conceptId|questionId|sectionId|sourceHash|storagePath|fileHash)\b\s*[:=]?\s*',
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (sanitized.isEmpty || _containsInternalIdentifier(sanitized)) {
      return null;
    }
    return sanitized;
  }

  bool _containsInternalIdentifier(String value) {
    return _uuidPattern.hasMatch(value) ||
        _storagePathPattern.hasMatch(value) ||
        RegExp(
          r'\b(?:material|concept|question|section|source)[_-]?id\b',
          caseSensitive: false,
        ).hasMatch(value) ||
        RegExp(
          r'\b(?:materialId|conceptId|questionId|sectionId|sourceHash|storagePath|fileHash)\b',
        ).hasMatch(value);
  }

  static final _uuidPattern = RegExp(
    r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
    caseSensitive: false,
  );

  static final _storagePathPattern = RegExp(
    r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/[\w.-]+\b',
    caseSensitive: false,
  );
  Future<MemoryUpdate> saveAttempt({
    required String materialId,
    required String questionId,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
    required int retryCount,
    required bool hintUsed,
    required int hintLevel,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to save quiz attempts.');
    }

    final question = await _loadQuestionForMemory(
      userId: user.id,
      materialId: materialId,
      questionId: questionId,
    );

    if (Env.useMemoryEngineV2(user.id)) {
      final previous = await _legacyMemoryScore(
        userId: user.id,
        materialId: materialId,
        conceptId: question.conceptId,
      );
      final result = await MemoryEngineRemoteDataSource(_client).submit(
        MemoryEngineSubmission(
          questionId: questionId,
          selectedAnswer: selectedAnswer,
          isCorrect: isCorrect,
          responseTimeMs: responseTimeMs,
          retryCount: retryCount,
          hintLevel: hintLevel,
        ),
      );
      return MemoryUpdate(
        conceptId: question.conceptId,
        previousMemoryScore: previous,
        memoryScore: previous,
        nextReviewAt: result.dueAt ?? result.reviewedAt,
      );
    }

    await _client.from(SupabaseTables.quizAttempts).insert({
      'user_id': user.id,
      'material_id': materialId,
      'question_id': questionId,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect,
      'response_time_ms': responseTimeMs,
      'success_attempt': isCorrect,
      'retry_count': retryCount,
      'hint_used': hintUsed,
      'hint_level': hintLevel,
    });

    return _upsertMemoryState(
      userId: user.id,
      materialId: materialId,
      conceptId: question.conceptId,
      difficulty: question.difficulty,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      retryCount: retryCount,
      hintUsed: hintUsed,
      hintLevel: hintLevel,
    );
  }

  Future<double> _legacyMemoryScore({
    required String userId,
    required String materialId,
    required String conceptId,
  }) async {
    final row = await _client
        .from(SupabaseTables.memoryStates)
        .select('memory_score')
        .eq('user_id', userId)
        .eq('material_id', materialId)
        .eq('concept_id', conceptId)
        .maybeSingle();
    return _doubleFrom(row?['memory_score']);
  }

  Future<void> saveFeedback({
    required String questionId,
    required String feedbackType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to save question feedback.');
    }

    await _client.from(SupabaseTables.questionFeedback).upsert({
      'user_id': user.id,
      'question_id': questionId,
      'feedback_type': feedbackType,
    }, onConflict: 'user_id,question_id,feedback_type');
  }

  Future<void> passLearningItem({
    required String materialId,
    required Question question,
    required LearningPassType passType,
    required LearningPassReason reason,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to pass learning items.');
    }

    if (Env.useMemoryEngineV2(user.id)) {
      await MemoryEngineRemoteDataSource(
        _client,
      ).pass(MemoryEnginePass(questionId: question.id, reason: reason.value));
      return;
    }

    var query = _client
        .from(SupabaseTables.learningPasses)
        .select('id')
        .eq('user_id', user.id)
        .eq('pass_type', passType.value);
    query = passType == LearningPassType.question
        ? query.eq('question_id', question.id)
        : query.eq('concept_id', question.conceptId);
    final existing = await query.maybeSingle();

    final row = {
      'user_id': user.id,
      'material_id': materialId,
      'question_id': passType == LearningPassType.question ? question.id : null,
      'concept_id': question.conceptId,
      'pass_type': passType.value,
      'reason': reason.value,
      'is_active': true,
      'restored_at': null,
    };

    if (existing == null) {
      await _client.from(SupabaseTables.learningPasses).insert(row);
    } else {
      await _client
          .from(SupabaseTables.learningPasses)
          .update(row)
          .eq('id', existing['id'])
          .eq('user_id', user.id);
    }

    if (passType == LearningPassType.concept) {
      await _client
          .from(SupabaseTables.reviewSchedules)
          .update({'status': 'skipped'})
          .eq('user_id', user.id)
          .eq('material_id', materialId)
          .eq('concept_id', question.conceptId)
          .eq('status', 'scheduled');
    }
  }

  Future<_PassFilter> _loadPassFilter({
    required String userId,
    required String materialId,
  }) async {
    final rows = await _client
        .from(SupabaseTables.learningPasses)
        .select('question_id,concept_id,pass_type')
        .eq('user_id', userId)
        .eq('material_id', materialId)
        .eq('is_active', true);

    final questionIds = <String>{};
    final conceptIds = <String>{};
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      if (map['pass_type'] == LearningPassType.question.value &&
          map['question_id'] != null) {
        questionIds.add(map['question_id'].toString());
      }
      if (map['pass_type'] == LearningPassType.concept.value &&
          map['concept_id'] != null) {
        conceptIds.add(map['concept_id'].toString());
      }
    }
    return _PassFilter(questionIds: questionIds, conceptIds: conceptIds);
  }

  Future<QuestionModel> _loadQuestionForMemory({
    required String userId,
    required String materialId,
    required String questionId,
  }) async {
    final row = await _client
        .from(SupabaseTables.questions)
        .select(
          'id,material_id,concept_id,section_id,type,question_text,options,answer,explanation,evidence,difficulty,order_index',
        )
        .eq('id', questionId)
        .eq('material_id', materialId)
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Question was not found for memory update.');
    }
    return QuestionModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<MemoryUpdate> _upsertMemoryState({
    required String userId,
    required String materialId,
    required String conceptId,
    required int difficulty,
    required bool isCorrect,
    required int responseTimeMs,
    required int retryCount,
    required bool hintUsed,
    required int hintLevel,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await _client
        .from(SupabaseTables.memoryStates)
        .select('id,memory_score,last_reviewed_at')
        .eq('user_id', userId)
        .eq('material_id', materialId)
        .eq('concept_id', conceptId)
        .maybeSingle();

    final previousMemoryScore = _doubleFrom(existing?['memory_score']);
    final lastReviewedAt = _dateFrom(existing?['last_reviewed_at']);

    final accuracy = isCorrect ? 1.0 : 0.0;
    final responseTime = _responseTimeScore(responseTimeMs);
    final difficultyScore = difficulty.clamp(1, 5).toDouble() / 5.0;
    final forgettingCurve = _forgettingCurveScore(lastReviewedAt, now);
    final confidence = _clamp01(0.5 - (hintLevel.clamp(0, 2) * 0.15));

    final memoryScore = _clamp01(
      accuracy * 0.35 +
          responseTime * 0.15 +
          difficultyScore * 0.15 +
          forgettingCurve * 0.25 +
          confidence * 0.10,
    );
    final nextReviewAt = _nextReviewAt(now, memoryScore);

    final memoryRow = {
      'user_id': userId,
      'material_id': materialId,
      'concept_id': conceptId,
      'memory_score': memoryScore,
      'accuracy_score': accuracy,
      'response_time_score': responseTime,
      'difficulty_score': difficultyScore,
      'forgetting_curve_score': forgettingCurve,
      'confidence_score': confidence,
      'last_reviewed_at': now.toIso8601String(),
      'next_review_at': nextReviewAt.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final upserted = await _client
        .from(SupabaseTables.memoryStates)
        .upsert(memoryRow, onConflict: 'user_id,material_id,concept_id')
        .select('id')
        .single();

    await _createOrUpdateScheduledReview(
      userId: userId,
      materialId: materialId,
      conceptId: conceptId,
      memoryStateId: upserted['id'].toString(),
      scheduledAt: nextReviewAt,
    );

    return MemoryUpdate(
      conceptId: conceptId,
      previousMemoryScore: previousMemoryScore,
      memoryScore: memoryScore,
      nextReviewAt: nextReviewAt,
    );
  }

  Future<void> _createOrUpdateScheduledReview({
    required String userId,
    required String materialId,
    required String conceptId,
    required String memoryStateId,
    required DateTime scheduledAt,
  }) async {
    final existing = await _client
        .from(SupabaseTables.reviewSchedules)
        .select('id')
        .eq('user_id', userId)
        .eq('material_id', materialId)
        .eq('concept_id', conceptId)
        .eq('status', 'scheduled')
        .maybeSingle();

    final row = {
      'user_id': userId,
      'material_id': materialId,
      'concept_id': conceptId,
      'memory_state_id': memoryStateId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': 'scheduled',
    };

    if (existing == null) {
      await _client.from(SupabaseTables.reviewSchedules).insert(row);
      return;
    }

    await _client
        .from(SupabaseTables.reviewSchedules)
        .update(row)
        .eq('id', existing['id'])
        .eq('user_id', userId);
  }

  double _responseTimeScore(int responseTimeMs) {
    final seconds = max(0, responseTimeMs) / 1000.0;
    return _clamp01(1 - (seconds / 30.0));
  }

  double _forgettingCurveScore(DateTime? lastReviewedAt, DateTime now) {
    if (lastReviewedAt == null) {
      return 1;
    }
    final hours = max(0, now.difference(lastReviewedAt).inMinutes) / 60.0;
    return _clamp01(exp(-hours / 24.0));
  }

  DateTime _nextReviewAt(DateTime now, double memoryScore) {
    if (memoryScore < 0.4) {
      return now.add(const Duration(minutes: 10));
    }
    if (memoryScore < 0.6) {
      return now.add(const Duration(days: 1));
    }
    if (memoryScore < 0.8) {
      return now.add(const Duration(days: 3));
    }
    return now.add(const Duration(days: 7));
  }

  double _doubleFrom(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _dateFrom(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  double _clamp01(double value) => value.clamp(0, 1).toDouble();
}

class _PassFilter {
  const _PassFilter({required this.questionIds, required this.conceptIds});

  final Set<String> questionIds;
  final Set<String> conceptIds;

  bool allowsQuestion(Question question) {
    return !questionIds.contains(question.id) &&
        !conceptIds.contains(question.conceptId);
  }
}
