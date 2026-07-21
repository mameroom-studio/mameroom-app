class QuizSessionCheckpoint {
  const QuizSessionCheckpoint({
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

  final String materialId;
  final String materialTitle;
  final List<String> questionIds;
  final int currentIndex;
  final int initialQuestionCount;
  final List<QuizAnswerCheckpoint> answers;
  final List<QuizReinforcementCheckpoint> incorrectQueue;
  final Map<String, int> hintLevelsByQuestion;
  final Set<String> passedQuestionIds;
  final Set<String> passedConceptIds;
  final List<QuizMemoryCheckpoint> memoryUpdates;
  final String selectedAnswer;
  final bool isAnswerChecked;
  final DateTime updatedAt;
  final String? failedQuestionId;
}

class QuizAnswerCheckpoint {
  const QuizAnswerCheckpoint({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.attemptNumber,
    required this.retryCount,
    required this.hintUsed,
    required this.hintLevel,
  });

  final String questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTimeMs;
  final int attemptNumber;
  final int retryCount;
  final bool hintUsed;
  final int hintLevel;
}

class QuizReinforcementCheckpoint {
  const QuizReinforcementCheckpoint({
    required this.questionId,
    required this.availableAfterIndex,
    required this.failedAttempts,
  });

  final String questionId;
  final int availableAfterIndex;
  final int failedAttempts;
}

class QuizMemoryCheckpoint {
  const QuizMemoryCheckpoint({
    required this.conceptId,
    required this.previousMemoryScore,
    required this.memoryScore,
    required this.nextReviewAt,
  });

  final String conceptId;
  final double previousMemoryScore;
  final double memoryScore;
  final DateTime nextReviewAt;
}
