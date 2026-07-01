import '../entities/analysis_progress.dart';

abstract interface class AnalysisRepository {
  Future<AnalysisProgress> runFastPathAnalysis({
    required String materialId,
    AnalysisProgressCallback? onProgress,
  });
}