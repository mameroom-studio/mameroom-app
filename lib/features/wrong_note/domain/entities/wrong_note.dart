enum WrongNoteStatus { wrong, repeated, passed, reviewed }

class WrongNote {
  const WrongNote({
    required this.id,
    required this.questionText,
    required this.materialName,
    required this.lastWrongAt,
    required this.wrongCount,
    required this.memoryRate,
    required this.status,
    required this.isBookmarked,
    this.nextReviewAt,
    this.source,
  });
  final String id;
  final String questionText;
  final String materialName;
  final DateTime lastWrongAt;
  final int wrongCount;
  final double memoryRate;
  final WrongNoteStatus status;
  final bool isBookmarked;
  final DateTime? nextReviewAt;
  final String? source;
}

enum WrongNoteFilter { all, today, repeated, passed, bookmarked, lowMemory }

enum WrongNoteSort { recent, wrongCount, lowMemory, nextReview }
