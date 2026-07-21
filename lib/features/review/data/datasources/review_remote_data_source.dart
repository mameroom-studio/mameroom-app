import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_tables.dart';
import '../../../../core/config/env.dart';
import '../../../memory_engine/data/datasources/memory_engine_remote_data_source.dart';
import '../../../memory_engine/domain/entities/memory_engine_result.dart';
import '../../../quiz/data/models/question_model.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../domain/entities/review_schedule.dart';
import '../models/review_schedule_model.dart';

class ReviewRemoteDataSource {
  const ReviewRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<ReviewScheduleModel>> loadDueReviews() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to load reviews.');
    }

    if (Env.useMemoryEngineV2(user.id)) {
      final payload = await MemoryEngineRemoteDataSource(_client).loadDue();
      final items = payload['items'];
      if (items is! List) return const [];
      return items
          .map((raw) {
            final row = Map<String, dynamic>.from(raw as Map);
            final question = QuestionModel.fromJson({
              'id': row['question_id'],
              'material_id': row['material_id'],
              'concept_id': row['concept_id'],
              'section_id': row['section_id'],
              'type': row['type'],
              'question_text': row['question_text'],
              'options': row['options'],
              'answer': row['answer'],
              'explanation': row['explanation'],
              'evidence': row['evidence'],
              'difficulty': row['question_difficulty'],
              'order_index': row['order_index'],
            });
            return ReviewScheduleModel(
              id: row['memory_state_id'].toString(),
              materialId: row['material_id'].toString(),
              conceptId: row['concept_id'].toString(),
              memoryStateId: row['memory_state_id'].toString(),
              scheduledAt: DateTime.parse(row['due_at'].toString()).toUtc(),
              memoryScore: _doubleFrom(row['legacy_memory_score']),
              question: question,
            );
          })
          .toList(growable: false);
    }

    final now = DateTime.now().toUtc();
    final schedules = await _client
        .from(SupabaseTables.reviewSchedules)
        .select(
          'id,material_id,concept_id,memory_state_id,scheduled_at,memory_states!inner(memory_score,next_review_at)',
        )
        .eq('user_id', user.id)
        .eq('status', 'scheduled')
        .lte('scheduled_at', now.toIso8601String())
        .lte('memory_states.next_review_at', now.toIso8601String())
        .order('scheduled_at', ascending: true);

    if (schedules.isEmpty) {
      return const [];
    }

    final scheduleRows = schedules
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final materialIds = scheduleRows
        .map((row) => row['material_id'].toString())
        .toSet()
        .toList(growable: false);

    final questionRows = await _client
        .from(SupabaseTables.questions)
        .select(
          'id,material_id,concept_id,section_id,type,question_text,options,answer,explanation,evidence,difficulty,order_index',
        )
        .eq('user_id', user.id)
        .eq('initial_batch', true)
        .eq('type', 'multiple_choice')
        .inFilter('material_id', materialIds);

    final passFilter = await _loadPassFilter(userId: user.id);
    final questions = questionRows
        .map(
          (row) =>
              QuestionModel.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .where(passFilter.allowsQuestion)
        .where(_isEligibleMultipleChoice)
        .toList(growable: false);

    final items = <ReviewScheduleModel>[];
    for (final schedule in scheduleRows) {
      final question = questions
          .where((candidate) {
            return candidate.materialId == schedule['material_id'] &&
                candidate.conceptId == schedule['concept_id'];
          })
          .fold<QuestionModel?>(null, (current, candidate) {
            if (current == null || candidate.orderIndex < current.orderIndex) {
              return candidate;
            }
            return current;
          });

      if (question == null) {
        continue;
      }
      items.add(
        ReviewScheduleModel.fromParts(schedule: schedule, question: question),
      );
    }

    items.sort((a, b) {
      final overdueCompare = a.scheduledAt.compareTo(b.scheduledAt);
      if (overdueCompare != 0) {
        return overdueCompare;
      }
      return a.memoryScore.compareTo(b.memoryScore);
    });
    return items;
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

  Future<MemoryUpdate> completeReview({
    required ReviewSchedule item,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to complete reviews.');
    }

    if (Env.useMemoryEngineV2(user.id)) {
      final result = await MemoryEngineRemoteDataSource(_client).submit(
        MemoryEngineSubmission(
          questionId: item.question.id,
          selectedAnswer: selectedAnswer,
          isCorrect: isCorrect,
          responseTimeMs: responseTimeMs,
          retryCount: 0,
          hintLevel: 0,
        ),
      );
      return MemoryUpdate(
        conceptId: item.conceptId,
        previousMemoryScore: item.memoryScore,
        memoryScore: item.memoryScore,
        nextReviewAt: result.dueAt ?? result.reviewedAt,
      );
    }

    await _client.from(SupabaseTables.quizAttempts).insert({
      'user_id': user.id,
      'material_id': item.materialId,
      'question_id': item.question.id,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect,
      'response_time_ms': responseTimeMs,
    });

    await _client
        .from(SupabaseTables.reviewSchedules)
        .update({'status': 'completed'})
        .eq('id', item.id)
        .eq('user_id', user.id);

    return _upsertMemoryState(
      userId: user.id,
      materialId: item.materialId,
      conceptId: item.conceptId,
      difficulty: item.question.difficulty,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
    );
  }

  Future<void> passLearningItem({
    required ReviewSchedule item,
    required LearningPassType passType,
    required LearningPassReason reason,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to pass learning items.');
    }

    if (Env.useMemoryEngineV2(user.id)) {
      await MemoryEngineRemoteDataSource(_client).pass(
        MemoryEnginePass(questionId: item.question.id, reason: reason.value),
      );
      return;
    }

    var query = _client
        .from(SupabaseTables.learningPasses)
        .select('id')
        .eq('user_id', user.id)
        .eq('pass_type', passType.value);
    query = passType == LearningPassType.question
        ? query.eq('question_id', item.question.id)
        : query.eq('concept_id', item.conceptId);
    final existing = await query.maybeSingle();

    final row = {
      'user_id': user.id,
      'material_id': item.materialId,
      'question_id': passType == LearningPassType.question
          ? item.question.id
          : null,
      'concept_id': item.conceptId,
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
          .eq('material_id', item.materialId)
          .eq('concept_id', item.conceptId)
          .eq('status', 'scheduled');
    }
  }

  Future<_PassFilter> _loadPassFilter({required String userId}) async {
    final rows = await _client
        .from(SupabaseTables.learningPasses)
        .select('question_id,concept_id,pass_type')
        .eq('user_id', userId)
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

  Future<MemoryUpdate> _upsertMemoryState({
    required String userId,
    required String materialId,
    required String conceptId,
    required int difficulty,
    required bool isCorrect,
    required int responseTimeMs,
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
    const confidence = 0.5;

    final memoryScore = _clamp01(
      accuracy * 0.35 +
          responseTime * 0.15 +
          difficultyScore * 0.15 +
          forgettingCurve * 0.25 +
          confidence * 0.10,
    );
    final nextReviewAt = _nextReviewAt(now, memoryScore);

    final upserted = await _client
        .from(SupabaseTables.memoryStates)
        .upsert({
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
        }, onConflict: 'user_id,material_id,concept_id')
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
