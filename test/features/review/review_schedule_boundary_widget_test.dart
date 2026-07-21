import 'package:ai_memory_coach/features/quiz/domain/entities/question.dart';
import 'package:ai_memory_coach/features/review/domain/entities/review_schedule.dart';
import 'package:ai_memory_coach/features/review/domain/repositories/review_repository.dart';
import 'package:ai_memory_coach/features/review/domain/usecases/review_usecase.dart';
import 'package:ai_memory_coach/features/review/presentation/pages/review_page.dart';
import 'package:ai_memory_coach/features/review/presentation/providers/review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements ReviewRepository {
  const _Repository(this.items);
  final List<ReviewSchedule> items;

  @override
  Future<List<ReviewSchedule>> loadDueReviews() async => items;

  @override
  Future<MemoryUpdate> completeReview({
    required ReviewSchedule item,
    required String selectedAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  }) async => MemoryUpdate(
    conceptId: item.conceptId,
    previousMemoryScore: item.memoryScore,
    memoryScore: item.memoryScore,
    nextReviewAt: item.scheduledAt,
  );

  @override
  Future<void> passLearningItem({
    required ReviewSchedule item,
    required LearningPassType passType,
    required LearningPassReason reason,
  }) async {}
}

ReviewSchedule _schedule(int index) => ReviewSchedule(
  id: 'schedule-$index',
  materialId: 'material-1',
  conceptId: 'concept-$index',
  memoryStateId: 'memory-$index',
  scheduledAt: DateTime.utc(2026, 7, index + 1),
  memoryScore: .3 + index * .1,
  question: Question(
    id: 'question-$index',
    materialId: 'material-1',
    conceptId: 'concept-$index',
    type: QuizQuestionType.multipleChoice,
    questionText: 'Review question $index',
    options: const ['A', 'B'],
    answer: 'A',
    explanation: 'Explanation',
    evidence: 'Evidence',
    difficulty: 2,
    orderIndex: index,
  ),
);

Future<void> _pump(WidgetTester tester, List<ReviewSchedule> items) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reviewRepositoryProvider.overrideWithValue(_Repository(items)),
        reviewUseCaseProvider.overrideWithValue(
          ReviewUseCase(_Repository(items)),
        ),
      ],
      child: MaterialApp(home: ReviewPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('today review accepts zero domain schedules', (tester) async {
    await _pump(tester, const []);
    expect(
      find.text(String.fromCharCodes([50724, 45720, 51032, 32, 48373, 49845])),
      findsWidgets,
    );
    expect(find.text('Review data unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('today review accepts one domain schedule', (tester) async {
    await _pump(tester, [_schedule(0)]);
    expect(
      find.text(String.fromCharCodes([50724, 45720, 51032, 32, 48373, 49845])),
      findsWidgets,
    );
    expect(find.text('Review data unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('today review reduces multiple domain schedules safely', (
    tester,
  ) async {
    await _pump(tester, [_schedule(2), _schedule(0), _schedule(1)]);
    expect(
      find.text(String.fromCharCodes([50724, 45720, 51032, 32, 48373, 49845])),
      findsWidgets,
    );
    expect(find.text('Review data unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
