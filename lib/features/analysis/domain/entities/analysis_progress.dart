typedef AnalysisProgressCallback = void Function(AnalysisProgress progress);

enum MaterialAnalysisStatus {
  uploading('uploading', 'Uploading'),
  parsing('parsing', 'Parsing PDF'),
  generating('generating', 'Generating'),
  completed('completed', 'Completed'),
  failed('failed', 'Failed');

  const MaterialAnalysisStatus(this.value, this.label);

  final String value;
  final String label;

  static MaterialAnalysisStatus fromValue(String value) {
    return MaterialAnalysisStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MaterialAnalysisStatus.uploading,
    );
  }
}

class AnalysisProgress {
  const AnalysisProgress({
    required this.materialId,
    required this.status,
    required this.progress,
    this.message = '',
    this.conceptCount = 0,
    this.usedCache = false,
  });

  final String materialId;
  final MaterialAnalysisStatus status;
  final double progress;
  final String message;
  final int conceptCount;
  final bool usedCache;

  bool get isCompleted => status == MaterialAnalysisStatus.completed;

  bool get isFailed => status == MaterialAnalysisStatus.failed;

  AnalysisProgress copyWith({
    MaterialAnalysisStatus? status,
    double? progress,
    String? message,
    int? conceptCount,
    bool? usedCache,
  }) {
    return AnalysisProgress(
      materialId: materialId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      conceptCount: conceptCount ?? this.conceptCount,
      usedCache: usedCache ?? this.usedCache,
    );
  }
}
