import '../entities/question.dart';
import '../repositories/quiz_repository.dart';

class QuizUseCase {
  const QuizUseCase(this.repository);

  final QuizRepository repository;

  Future<List<Question>> loadInitialQuestions({required String materialId}) {
    return repository.loadInitialQuestions(materialId: materialId);
  }

  Future<MemoryUpdate> saveAttempt({
    required String materialId,
    required String questionId,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  }) {
    return repository.saveAttempt(
      materialId: materialId,
      questionId: questionId,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
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
}