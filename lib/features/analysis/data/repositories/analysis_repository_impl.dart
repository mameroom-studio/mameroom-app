import '../../domain/entities/analysis_progress.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../datasources/analysis_remote_data_source.dart';

class AnalysisRepositoryImpl implements AnalysisRepository {
  const AnalysisRepositoryImpl({required AnalysisRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final AnalysisRemoteDataSource _remoteDataSource;

  @override
  Future<AnalysisProgress> runFastPathAnalysis({
    required String materialId,
    AnalysisProgressCallback? onProgress,
  }) {
    return _remoteDataSource.runFastPathAnalysis(
      materialId: materialId,
      onProgress: onProgress,
    );
  }
}