import '../../../quiz/domain/entities/question.dart';
import '../entities/review_schedule.dart';
import '../repositories/review_repository.dart';

class ReviewUseCase {
  const ReviewUseCase(this.repository);

  final ReviewRepository repository;

  Future<List<ReviewSchedule>> loadDueReviews() {
    return repository.loadDueReviews();
  }

  Future<MemoryUpdate> completeReview({
    required ReviewSchedule item,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  }) {
    return repository.completeReview(
      item: item,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
    );
  }
  Future<void> passLearningItem({
    required ReviewSchedule item,
    required LearningPassType passType,
    required LearningPassReason reason,
  }) {
    return repository.passLearningItem(
      item: item,
      passType: passType,
      reason: reason,
    );
  }
}