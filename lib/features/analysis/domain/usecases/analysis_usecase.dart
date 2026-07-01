import '../entities/analysis_progress.dart';
import '../repositories/analysis_repository.dart';

class AnalysisUseCase {
  const AnalysisUseCase(this.repository);

  final AnalysisRepository repository;

  Future<AnalysisProgress> runFastPathAnalysis({
    required String materialId,
    AnalysisProgressCallback? onProgress,
  }) {
    return repository.runFastPathAnalysis(
      materialId: materialId,
      onProgress: onProgress,
    );
  }
}