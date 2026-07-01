enum QuizQuestionType {
  multipleChoice('multiple_choice'),
  ox('ox'),
  fillBlank('fill_blank');

  const QuizQuestionType(this.value);

  final String value;

  static QuizQuestionType fromValue(String value) {
    return QuizQuestionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QuizQuestionType.multipleChoice,
    );
  }
}

class Question {
  const Question({
    required this.id,
    required this.materialId,
    required this.conceptId,
    required this.type,
    required this.questionText,
    required this.options,
    required this.answer,
    required this.explanation,
    required this.evidence,
    required this.difficulty,
    required this.orderIndex,
    this.sectionId,
  });

  final String id;
  final String materialId;
  final String conceptId;
  final String? sectionId;
  final QuizQuestionType type;
  final String questionText;
  final List<String> options;
  final String answer;
  final String explanation;
  final String evidence;
  final int difficulty;
  final int orderIndex;
}

class QuizAnswerResult {
  const QuizAnswerResult({
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
  });

  final Question question;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTimeMs;
}

class QuizResultSummary {
  const QuizResultSummary({required this.answers});

  final List<QuizAnswerResult> answers;

  int get totalCount => answers.length;
  int get correctCount => answers.where((answer) => answer.isCorrect).length;
  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;
  double get averageResponseTimeMs {
    if (answers.isEmpty) {
      return 0;
    }
    final total = answers.fold<int>(0, (sum, answer) => sum + answer.responseTimeMs);
    return total / answers.length;
  }
}
class MemoryUpdate {
  const MemoryUpdate({
    required this.conceptId,
    required this.previousMemoryScore,
    required this.memoryScore,
    required this.nextReviewAt,
  });

  final String conceptId;
  final double previousMemoryScore;
  final double memoryScore;
  final DateTime nextReviewAt;

  double get delta => memoryScore - previousMemoryScore;
}