import '../../../quiz/domain/entities/question.dart';
import '../../domain/entities/review_schedule.dart';
import '../../domain/repositories/review_repository.dart';
import '../fixtures/mock_review_fixture.dart';

final class MockReviewRepository implements ReviewRepository {
  MockReviewRepository({DateTime? clock})
    : _items = MockReviewFixture.dueReviews(clock: clock);
  final List<ReviewSchedule> _items;
  @override
  Future<List<ReviewSchedule>> loadDueReviews() async =>
      List.unmodifiable(_items);
  @override
  Future<MemoryUpdate> completeReview({
    required ReviewSchedule item,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  }) async => MemoryUpdate(
    conceptId: item.conceptId,
    previousMemoryScore: item.memoryScore,
    memoryScore: (item.memoryScore + (isCorrect ? .09 : -.02)).clamp(0, 1),
    nextReviewAt: DateTime.now().add(Duration(days: isCorrect ? 3 : 1)),
  );
  @override
  Future<void> passLearningItem({
    required ReviewSchedule item,
    required LearningPassType passType,
    required LearningPassReason reason,
  }) async {
    _items.removeWhere(
      (candidate) => passType == LearningPassType.question
          ? candidate.question.id == item.question.id
          : candidate.conceptId == item.conceptId,
    );
  }
}
