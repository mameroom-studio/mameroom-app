class StudyMaterial {
  const StudyMaterial({
    required this.id,
    required this.title,
    required this.sectionCount,
    required this.progressPercent,
    required this.memoryPercent,
    required this.nextReviewLabel,
    this.totalQuestionCount = 0,
    this.completedQuestionCount = 0,
    this.dueReviewCount = 0,
    this.seedLabel = '씨앗',
    this.seedEmoji = '🌱',
    this.recentStudyLabel = '아직 학습 전',
    this.currentStreak = 0,
    this.status = 'uploaded',
  });

  final String id;
  final String title;
  final int sectionCount;
  final int progressPercent;
  final int memoryPercent;
  final String nextReviewLabel;
  final int totalQuestionCount;
  final int completedQuestionCount;
  final int dueReviewCount;
  final String seedLabel;
  final String seedEmoji;
  final String recentStudyLabel;
  final int currentStreak;
  final String status;

  bool get canStartQuiz => status == 'completed';
}
