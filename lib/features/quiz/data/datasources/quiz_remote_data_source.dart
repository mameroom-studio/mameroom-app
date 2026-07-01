import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/question.dart';
import '../models/question_model.dart';

class QuizRemoteDataSource {
  const QuizRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<QuestionModel>> loadInitialQuestions({required String materialId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to load quiz questions.');
    }

    final material = await _client
        .from(SupabaseTables.studyMaterials)
        .select('id,status')
        .eq('id', materialId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (material == null) {
      throw StateError('Study material was not found.');
    }
    if (material['status'] != 'completed') {
      throw StateError('Quiz is available only after material status is completed.');
    }

    final rows = await _client
        .from(SupabaseTables.questions)
        .select('id,material_id,concept_id,section_id,type,question_text,options,answer,explanation,evidence,difficulty,order_index')
        .eq('user_id', user.id)
        .eq('material_id', materialId)
        .eq('initial_batch', true)
        .order('order_index', ascending: true)
        .limit(10);

    return rows
        .map((row) => QuestionModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<MemoryUpdate> saveAttempt({
    required String materialId,
    required String questionId,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
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

    await _client.from(SupabaseTables.quizAttempts).insert({
      'user_id': user.id,
      'material_id': materialId,
      'question_id': questionId,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect,
      'response_time_ms': responseTimeMs,
    });

    return _upsertMemoryState(
      userId: user.id,
      materialId: materialId,
      conceptId: question.conceptId,
      difficulty: question.difficulty,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
    );
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

  Future<QuestionModel> _loadQuestionForMemory({
    required String userId,
    required String materialId,
    required String questionId,
  }) async {
    final row = await _client
        .from(SupabaseTables.questions)
        .select('id,material_id,concept_id,section_id,type,question_text,options,answer,explanation,evidence,difficulty,order_index')
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