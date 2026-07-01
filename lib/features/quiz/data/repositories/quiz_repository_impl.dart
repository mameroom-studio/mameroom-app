import '../../domain/entities/question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_data_source.dart';

class QuizRepositoryImpl implements QuizRepository {
  const QuizRepositoryImpl({required QuizRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final QuizRemoteDataSource _remoteDataSource;

  @override
  Future<List<Question>> loadInitialQuestions({required String materialId}) {
    return _remoteDataSource.loadInitialQuestions(materialId: materialId);
  }

  @override
  Future<MemoryUpdate> saveAttempt({
    required String materialId,
    required String questionId,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  }) {
    return _remoteDataSource.saveAttempt(
      materialId: materialId,
      questionId: questionId,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
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
}