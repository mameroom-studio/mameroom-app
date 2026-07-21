import '../../../quiz/domain/entities/question.dart';
import '../../domain/entities/review_schedule.dart';

class ReviewScheduleModel {
  const ReviewScheduleModel({
    required this.id,
    required this.materialId,
    required this.conceptId,
    required this.memoryStateId,
    required this.scheduledAt,
    required this.memoryScore,
    required this.question,
  });

  final String id;
  final String materialId;
  final String conceptId;
  final String memoryStateId;
  final DateTime scheduledAt;
  final double memoryScore;
  final Question question;

  factory ReviewScheduleModel.fromParts({
    required Map<String, dynamic> schedule,
    required Question question,
  }) {
    final memoryState = schedule['memory_states'];
    final memoryStateMap = memoryState is Map
        ? memoryState
        : const <String, dynamic>{};
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

  ReviewSchedule toEntity() => ReviewSchedule(
    id: id,
    materialId: materialId,
    conceptId: conceptId,
    memoryStateId: memoryStateId,
    scheduledAt: scheduledAt,
    memoryScore: memoryScore,
    question: question,
  );

  static double _doubleFrom(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
