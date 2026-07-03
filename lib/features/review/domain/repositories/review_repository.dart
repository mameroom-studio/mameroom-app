import '../../../quiz/domain/entities/question.dart';
import '../entities/review_schedule.dart';

abstract interface class ReviewRepository {
  Future<List<ReviewSchedule>> loadDueReviews();

  Future<MemoryUpdate> completeReview({
    required ReviewSchedule item,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  });
  Future<void> passLearningItem({
    required ReviewSchedule item,
    required LearningPassType passType,
    required LearningPassReason reason,
  });
}