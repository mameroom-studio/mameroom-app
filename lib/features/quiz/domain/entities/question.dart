enum QuizQuestionType {
  shortAnswer('short_answer'),
  multipleChoice('multiple_choice'),
  fillBlank('fill_blank');

  const QuizQuestionType(this.value);

  final String value;

  static QuizQuestionType fromValue(String value) {
    return QuizQuestionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QuizQuestionType.shortAnswer,
    );
  }
}

enum LearningPassType {
  question('question'),
  concept('concept');

  const LearningPassType(this.value);

  final String value;
}

enum LearningPassReason {
  alreadyKnown('already_known', '이미 알고 있음'),
  outOfScope('out_of_scope', '시험 범위 아님'),
  lowQuality('low_quality', '문제 품질 낮음'),
  reviewLater('review_later', '나중에 다시 볼 예정');

  const LearningPassReason(this.value, this.label);

  final String value;
  final String label;
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

class QuizInitialLoad {
  const QuizInitialLoad({required this.materialTitle, required this.questions});

  final String materialTitle;
  final List<Question> questions;
}

class QuizAnswerResult {
  const QuizAnswerResult({
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.attemptNumber,
    required this.retryCount,
    required this.hintUsed,
    required this.hintLevel,
  });

  final Question question;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTimeMs;
  final int attemptNumber;
  final int retryCount;
  final bool hintUsed;
  final int hintLevel;

  bool get isRetry => retryCount > 0;
  bool get successAttempt => isCorrect;
}

class QuizResultSummary {
  const QuizResultSummary({required this.answers});

  final List<QuizAnswerResult> answers;

  int get totalCount => answers.length;
  int get correctCount => answers.where((answer) => answer.isCorrect).length;
  int get firstAttemptCount =>
      answers.where((answer) => !answer.isRetry).length;
  int get firstAttemptCorrectCount =>
      answers.where((answer) => !answer.isRetry && answer.isCorrect).length;
  int get retryCount => answers.where((answer) => answer.isRetry).length;
  int get retryCorrectCount =>
      answers.where((answer) => answer.isRetry && answer.isCorrect).length;
  int get hintUsedCount => answers.where((answer) => answer.hintUsed).length;
  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;
  double get firstAttemptAccuracy =>
      firstAttemptCount == 0 ? 0 : firstAttemptCorrectCount / firstAttemptCount;
  double get retrySuccessRate =>
      retryCount == 0 ? 0 : retryCorrectCount / retryCount;
  double get memoryConsolidationRate {
    final uniqueQuestions = answers.map((answer) => answer.question.id).toSet();
    if (uniqueQuestions.isEmpty) {
      return 0;
    }
    final correctQuestions = answers
        .where((answer) => answer.isCorrect)
        .map((answer) => answer.question.id)
        .toSet();
    return correctQuestions.length / uniqueQuestions.length;
  }

  double get averageResponseTimeMs {
    if (answers.isEmpty) {
      return 0;
    }
    final total = answers.fold<int>(
      0,
      (sum, answer) => sum + answer.responseTimeMs,
    );
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
