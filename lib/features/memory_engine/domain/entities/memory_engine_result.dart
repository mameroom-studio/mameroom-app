class MemoryEngineResult {
  const MemoryEngineResult({
    required this.submissionId,
    required this.reviewedAt,
    required this.scheduleChanged,
    required this.duplicate,
    this.state,
    this.dueAt,
    this.stability,
    this.difficulty,
    this.stateVersion,
  });
  final String submissionId;
  final DateTime reviewedAt;
  final bool scheduleChanged;
  final bool duplicate;
  final String? state;
  final DateTime? dueAt;
  final double? stability;
  final double? difficulty;
  final int? stateVersion;
}

class MemoryEngineSubmission {
  const MemoryEngineSubmission({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.retryCount,
    required this.hintLevel,
    this.sessionId,
    this.submissionId,
  });
  final String questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTimeMs;
  final int retryCount;
  final int hintLevel;
  final String? sessionId;
  final String? submissionId;
}

class MemoryEnginePass {
  const MemoryEnginePass({
    required this.questionId,
    required this.reason,
    this.sessionId,
    this.submissionId,
  });
  final String questionId;
  final String? reason;
  final String? sessionId;
  final String? submissionId;
}
