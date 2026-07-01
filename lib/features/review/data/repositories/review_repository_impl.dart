import '../../../quiz/domain/entities/question.dart';
import '../../domain/entities/review_schedule.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl({required ReviewRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final ReviewRemoteDataSource _remoteDataSource;

  @override
  Future<List<ReviewSchedule>> loadDueReviews() {
    return _remoteDataSource.loadDueReviews();
  }

  @override
  Future<MemoryUpdate> completeReview({
    required ReviewSchedule item,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  }) {
    return _remoteDataSource.completeReview(
      item: item,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
    );
  }
}