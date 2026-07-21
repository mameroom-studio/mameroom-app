import '../entities/question.dart';
import '../repositories/quiz_repository.dart';

class QuizUseCase {
  const QuizUseCase(this.repository);

  final QuizRepository repository;

  Future<QuizInitialLoad> loadInitialQuestions({
    required String materialId,
    bool unlearnedOnly = false,
  }) {
    return repository.loadInitialQuestions(
      materialId: materialId,
      unlearnedOnly: unlearnedOnly,
    );
  }

  Future<MemoryUpdate> saveAttempt({
    required String materialId,
    required String questionId,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
    required int retryCount,
    required bool hintUsed,
    required int hintLevel,
  }) {
    return repository.saveAttempt(
      materialId: materialId,
      questionId: questionId,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      retryCount: retryCount,
      hintUsed: hintUsed,
      hintLevel: hintLevel,
    );
  }

  Future<void> saveFeedback({
    required String questionId,
    required String feedbackType,
  }) {
    return repository.saveFeedback(
      questionId: questionId,
      feedbackType: feedbackType,
    );
  }

  Future<void> passLearningItem({
    required String materialId,
    required Question question,
    required LearningPassType passType,
    required LearningPassReason reason,
  }) {
    return repository.passLearningItem(
      materialId: materialId,
      question: question,
      passType: passType,
      reason: reason,
    );
  }
}
