import '../../../quiz/domain/entities/question.dart';
import '../../domain/entities/review_schedule.dart';

class ReviewScheduleModel extends ReviewSchedule {
  const ReviewScheduleModel({
    required super.id,
    required super.materialId,
    required super.conceptId,
    required super.memoryStateId,
    required super.scheduledAt,
    required super.memoryScore,
    required super.question,
  });

  factory ReviewScheduleModel.fromParts({
    required Map<String, dynamic> schedule,
    required Question question,
  }) {
    final memoryState = schedule['memory_states'];
    final memoryStateMap = memoryState is Map ? memoryState : const <String, dynamic>{};
    return ReviewScheduleModel(
      id: schedule['id'] as String,
      materialId: schedule['material_id'] as String,
      conceptId: schedule['concept_id'] as String,
      memoryStateId: schedule['memory_state_id'] as String,
      scheduledAt: DateTime.parse(schedule['scheduled_at'].toString()).toUtc(),
      memoryScore: _doubleFrom(memoryStateMap['memory_score']),
      question: question,
    );
  }

  static double _doubleFrom(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}