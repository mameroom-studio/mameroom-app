import 'package:ai_memory_coach/features/quiz/domain/entities/question.dart';
import 'package:ai_memory_coach/features/review/data/models/review_schedule_model.dart';
import 'package:ai_memory_coach/features/review/domain/entities/review_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

const _question = Question(
  id: 'question-1',
  materialId: 'material-1',
  conceptId: 'concept-1',
  type: QuizQuestionType.multipleChoice,
  questionText: 'Question?',
  options: ['A', 'B'],
  answer: 'A',
  explanation: 'Explanation',
  evidence: 'Evidence',
  difficulty: 2,
  orderIndex: 0,
);

ReviewScheduleModel _model(int day, double score) => ReviewScheduleModel(
  id: 'schedule-$day',
  materialId: 'material-1',
  conceptId: 'concept-1',
  memoryStateId: 'memory-$day',
  scheduledAt: DateTime.utc(2026, 7, day),
  memoryScore: score,
  question: _question,
);

void main() {
  test('model converts to a standalone domain entity', () {
    final model = _model(2, .4);
    final entity = model.toEntity();

    expect(entity, isA<ReviewSchedule>());
    expect(entity.runtimeType, ReviewSchedule);
    expect(entity.id, model.id);
    expect(entity.scheduledAt, model.scheduledAt);
  });

  test(
    'zero, one and multiple entity schedules keep domain callback types',
    () {
      for (final models in <List<ReviewScheduleModel>>[
        const [],
        [_model(2, .4)],
        [_model(3, .2), _model(1, .8), _model(2, .4)],
      ]) {
        final schedules = models.map((model) => model.toEntity()).toList();
        schedules.sort(
          (ReviewSchedule a, ReviewSchedule b) =>
              a.scheduledAt.compareTo(b.scheduledAt),
        );

        final earliest = schedules.isEmpty
            ? null
            : schedules.reduce(
                (ReviewSchedule a, ReviewSchedule b) =>
                    a.scheduledAt.isBefore(b.scheduledAt) ? a : b,
              );
        expect(
          schedules.every((item) => item.runtimeType == ReviewSchedule),
          isTrue,
        );
        if (schedules.length > 1) {
          expect(earliest?.id, 'schedule-1');
        }
      }
    },
  );
}
