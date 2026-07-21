import '../../domain/entities/quiz_session_checkpoint.dart';

class QuizSessionCheckpointModel {
  const QuizSessionCheckpointModel({
    required this.materialId,
    required this.materialTitle,
    required this.questionIds,
    required this.currentIndex,
    required this.initialQuestionCount,
    required this.answers,
    required this.incorrectQueue,
    required this.hintLevelsByQuestion,
    required this.passedQuestionIds,
    required this.passedConceptIds,
    required this.memoryUpdates,
    required this.selectedAnswer,
    required this.isAnswerChecked,
    required this.updatedAt,
    this.failedQuestionId,
  });

  factory QuizSessionCheckpointModel.fromEntity(
    QuizSessionCheckpoint checkpoint,
  ) {
    return QuizSessionCheckpointModel(
      materialId: checkpoint.materialId,
      materialTitle: checkpoint.materialTitle,
      questionIds: checkpoint.questionIds,
      currentIndex: checkpoint.currentIndex,
      initialQuestionCount: checkpoint.initialQuestionCount,
      answers: checkpoint.answers
          .map(QuizAnswerCheckpointModel.fromEntity)
          .toList(growable: false),
      incorrectQueue: checkpoint.incorrectQueue
          .map(QuizReinforcementCheckpointModel.fromEntity)
          .toList(growable: false),
      hintLevelsByQuestion: checkpoint.hintLevelsByQuestion,
      passedQuestionIds: checkpoint.passedQuestionIds,
      passedConceptIds: checkpoint.passedConceptIds,
      memoryUpdates: checkpoint.memoryUpdates
          .map(QuizMemoryCheckpointModel.fromEntity)
          .toList(growable: false),
      selectedAnswer: checkpoint.selectedAnswer,
      isAnswerChecked: checkpoint.isAnswerChecked,
      updatedAt: checkpoint.updatedAt,
      failedQuestionId: checkpoint.failedQuestionId,
    );
  }

  factory QuizSessionCheckpointModel.fromJson(Map<String, dynamic> json) {
    return QuizSessionCheckpointModel(
      materialId: json['material_id'] as String? ?? '',
      materialTitle: json['material_title'] as String? ?? '',
      questionIds: _strings(json['question_ids']),
      currentIndex: _integer(json['current_index']),
      initialQuestionCount: _integer(json['initial_question_count']),
      answers: _maps(
        json['answers'],
      ).map(QuizAnswerCheckpointModel.fromJson).toList(growable: false),
      incorrectQueue: _maps(
        json['incorrect_queue'],
      ).map(QuizReinforcementCheckpointModel.fromJson).toList(growable: false),
      hintLevelsByQuestion: _integerMap(json['hint_levels_by_question']),
      passedQuestionIds: _strings(json['passed_question_ids']).toSet(),
      passedConceptIds: _strings(json['passed_concept_ids']).toSet(),
      memoryUpdates: _maps(
        json['memory_updates'],
      ).map(QuizMemoryCheckpointModel.fromJson).toList(growable: false),
      selectedAnswer: json['selected_answer'] as String? ?? '',
      isAnswerChecked: json['is_answer_checked'] as bool? ?? false,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      failedQuestionId: json['failed_question_id'] as String?,
    );
  }

  final String materialId;
  final String materialTitle;
  final List<String> questionIds;
  final int currentIndex;
  final int initialQuestionCount;
  final List<QuizAnswerCheckpointModel> answers;
  final List<QuizReinforcementCheckpointModel> incorrectQueue;
  final Map<String, int> hintLevelsByQuestion;
  final Set<String> passedQuestionIds;
  final Set<String> passedConceptIds;
  final List<QuizMemoryCheckpointModel> memoryUpdates;
  final String selectedAnswer;
  final bool isAnswerChecked;
  final DateTime updatedAt;
  final String? failedQuestionId;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'material_id': materialId,
    'material_title': materialTitle,
    'question_ids': questionIds,
    'current_index': currentIndex,
    'initial_question_count': initialQuestionCount,
    'answers': answers.map((answer) => answer.toJson()).toList(growable: false),
    'incorrect_queue': incorrectQueue
        .map((item) => item.toJson())
        .toList(growable: false),
    'hint_levels_by_question': hintLevelsByQuestion,
    'passed_question_ids': passedQuestionIds.toList(growable: false),
    'passed_concept_ids': passedConceptIds.toList(growable: false),
    'memory_updates': memoryUpdates
        .map((update) => update.toJson())
        .toList(growable: false),
    'selected_answer': selectedAnswer,
    'is_answer_checked': isAnswerChecked,
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'failed_question_id': failedQuestionId,
  };

  QuizSessionCheckpoint toEntity() => QuizSessionCheckpoint(
    materialId: materialId,
    materialTitle: materialTitle,
    questionIds: questionIds,
    currentIndex: currentIndex,
    initialQuestionCount: initialQuestionCount,
    answers: answers.map((answer) => answer.toEntity()).toList(growable: false),
    incorrectQueue: incorrectQueue
        .map((item) => item.toEntity())
        .toList(growable: false),
    hintLevelsByQuestion: hintLevelsByQuestion,
    passedQuestionIds: passedQuestionIds,
    passedConceptIds: passedConceptIds,
    memoryUpdates: memoryUpdates
        .map((update) => update.toEntity())
        .toList(growable: false),
    selectedAnswer: selectedAnswer,
    isAnswerChecked: isAnswerChecked,
    updatedAt: updatedAt,
    failedQuestionId: failedQuestionId,
  );
}

class QuizAnswerCheckpointModel {
  const QuizAnswerCheckpointModel({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.attemptNumber,
    required this.retryCount,
    required this.hintUsed,
    required this.hintLevel,
  });

  factory QuizAnswerCheckpointModel.fromEntity(QuizAnswerCheckpoint answer) =>
      QuizAnswerCheckpointModel(
        questionId: answer.questionId,
        selectedAnswer: answer.selectedAnswer,
        isCorrect: answer.isCorrect,
        responseTimeMs: answer.responseTimeMs,
        attemptNumber: answer.attemptNumber,
        retryCount: answer.retryCount,
        hintUsed: answer.hintUsed,
        hintLevel: answer.hintLevel,
      );

  factory QuizAnswerCheckpointModel.fromJson(Map<String, dynamic> json) =>
      QuizAnswerCheckpointModel(
        questionId: json['question_id'] as String? ?? '',
        selectedAnswer: json['selected_answer'] as String? ?? '',
        isCorrect: json['is_correct'] as bool? ?? false,
        responseTimeMs: _integer(json['response_time_ms']),
        attemptNumber: _integer(json['attempt_number']),
        retryCount: _integer(json['retry_count']),
        hintUsed: json['hint_used'] as bool? ?? false,
        hintLevel: _integer(json['hint_level']),
      );

  final String questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTimeMs;
  final int attemptNumber;
  final int retryCount;
  final bool hintUsed;
  final int hintLevel;

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'selected_answer': selectedAnswer,
    'is_correct': isCorrect,
    'response_time_ms': responseTimeMs,
    'attempt_number': attemptNumber,
    'retry_count': retryCount,
    'hint_used': hintUsed,
    'hint_level': hintLevel,
  };

  QuizAnswerCheckpoint toEntity() => QuizAnswerCheckpoint(
    questionId: questionId,
    selectedAnswer: selectedAnswer,
    isCorrect: isCorrect,
    responseTimeMs: responseTimeMs,
    attemptNumber: attemptNumber,
    retryCount: retryCount,
    hintUsed: hintUsed,
    hintLevel: hintLevel,
  );
}

class QuizReinforcementCheckpointModel {
  const QuizReinforcementCheckpointModel({
    required this.questionId,
    required this.availableAfterIndex,
    required this.failedAttempts,
  });

  factory QuizReinforcementCheckpointModel.fromEntity(
    QuizReinforcementCheckpoint item,
  ) => QuizReinforcementCheckpointModel(
    questionId: item.questionId,
    availableAfterIndex: item.availableAfterIndex,
    failedAttempts: item.failedAttempts,
  );

  factory QuizReinforcementCheckpointModel.fromJson(
    Map<String, dynamic> json,
  ) => QuizReinforcementCheckpointModel(
    questionId: json['question_id'] as String? ?? '',
    availableAfterIndex: _integer(json['available_after_index']),
    failedAttempts: _integer(json['failed_attempts']),
  );

  final String questionId;
  final int availableAfterIndex;
  final int failedAttempts;

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'available_after_index': availableAfterIndex,
    'failed_attempts': failedAttempts,
  };

  QuizReinforcementCheckpoint toEntity() => QuizReinforcementCheckpoint(
    questionId: questionId,
    availableAfterIndex: availableAfterIndex,
    failedAttempts: failedAttempts,
  );
}

class QuizMemoryCheckpointModel {
  const QuizMemoryCheckpointModel({
    required this.conceptId,
    required this.previousMemoryScore,
    required this.memoryScore,
    required this.nextReviewAt,
  });

  factory QuizMemoryCheckpointModel.fromEntity(QuizMemoryCheckpoint update) =>
      QuizMemoryCheckpointModel(
        conceptId: update.conceptId,
        previousMemoryScore: update.previousMemoryScore,
        memoryScore: update.memoryScore,
        nextReviewAt: update.nextReviewAt,
      );

  factory QuizMemoryCheckpointModel.fromJson(Map<String, dynamic> json) =>
      QuizMemoryCheckpointModel(
        conceptId: json['concept_id'] as String? ?? '',
        previousMemoryScore: _number(json['previous_memory_score']),
        memoryScore: _number(json['memory_score']),
        nextReviewAt:
            DateTime.tryParse(json['next_review_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String conceptId;
  final double previousMemoryScore;
  final double memoryScore;
  final DateTime nextReviewAt;

  Map<String, dynamic> toJson() => {
    'concept_id': conceptId,
    'previous_memory_score': previousMemoryScore,
    'memory_score': memoryScore,
    'next_review_at': nextReviewAt.toUtc().toIso8601String(),
  };

  QuizMemoryCheckpoint toEntity() => QuizMemoryCheckpoint(
    conceptId: conceptId,
    previousMemoryScore: previousMemoryScore,
    memoryScore: memoryScore,
    nextReviewAt: nextReviewAt,
  );
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

Map<String, int> _integerMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), _integer(item)));
}

int _integer(Object? value) => value is num ? value.toInt() : 0;

double _number(Object? value) => value is num ? value.toDouble() : 0;
