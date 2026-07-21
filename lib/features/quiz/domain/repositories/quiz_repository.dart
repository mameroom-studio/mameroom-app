import '../entities/question.dart';

abstract interface class QuizRepository {
  Future<QuizInitialLoad> loadInitialQuestions({
    required String materialId,
    bool unlearnedOnly = false,
  });

  Future<MemoryUpdate> saveAttempt({
    required String materialId,
    required String questionId,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
    required int retryCount,
    required bool hintUsed,
    required int hintLevel,
  });

  Future<void> saveFeedback({
    required String questionId,
    required String feedbackType,
  });

  Future<void> passLearningItem({
    required String materialId,
    required Question question,
    required LearningPassType passType,
    required LearningPassReason reason,
  });
}
