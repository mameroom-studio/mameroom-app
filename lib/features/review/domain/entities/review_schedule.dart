import '../../../quiz/domain/entities/question.dart';

class ReviewSchedule {
  const ReviewSchedule({
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

  bool get isOverdue => scheduledAt.isBefore(DateTime.now().toUtc());
}

class ReviewAnswerResult {
  const ReviewAnswerResult({
    required this.item,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
  });

  final ReviewSchedule item;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTimeMs;
}

class ReviewResultSummary {
  const ReviewResultSummary({required this.answers});

  final List<ReviewAnswerResult> answers;

  int get totalCount => answers.length;
  int get correctCount => answers.where((answer) => answer.isCorrect).length;
  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;
}