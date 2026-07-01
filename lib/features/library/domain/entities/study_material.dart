class StudyMaterial {
  const StudyMaterial({
    required this.id,
    required this.title,
    required this.sectionCount,
    required this.progressPercent,
    required this.memoryPercent,
    required this.nextReviewLabel,
  });

  final String id;
  final String title;
  final int sectionCount;
  final int progressPercent;
  final int memoryPercent;
  final String nextReviewLabel;
}