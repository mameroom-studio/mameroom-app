import '../entities/question.dart';

abstract interface class QuizRepository {
  Future<List<Question>> loadInitialQuestions({required String materialId});

  Future<MemoryUpdate> saveAttempt({
    required String materialId,
    required String questionId,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  });

  Future<void> saveFeedback({
    required String questionId,
    required String feedbackType,
  });
}