import '../../domain/entities/question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_data_source.dart';

class QuizRepositoryImpl implements QuizRepository {
  const QuizRepositoryImpl({required QuizRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final QuizRemoteDataSource _remoteDataSource;

  @override
  Future<QuizInitialLoad> loadInitialQuestions({
    required String materialId,
    bool unlearnedOnly = false,
  }) {
    return _remoteDataSource.loadInitialQuestions(
      materialId: materialId,
      unlearnedOnly: unlearnedOnly,
    );
  }

  @override
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
    return _remoteDataSource.saveAttempt(
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

  @override
  Future<void> saveFeedback({
    required String questionId,
    required String feedbackType,
  }) {
    return _remoteDataSource.saveFeedback(
      questionId: questionId,
      feedbackType: feedbackType,
    );
  }

  @override
  Future<void> passLearningItem({
    required String materialId,
    required Question question,
    required LearningPassType passType,
    required LearningPassReason reason,
  }) {
    return _remoteDataSource.passLearningItem(
      materialId: materialId,
      question: question,
      passType: passType,
      reason: reason,
    );
  }
}
