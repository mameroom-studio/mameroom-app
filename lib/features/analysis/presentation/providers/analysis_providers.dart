import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/datasources/analysis_remote_data_source.dart';
import '../../data/datasources/openai_concept_data_source.dart';
import '../../data/repositories/analysis_repository_impl.dart';
import '../../domain/entities/analysis_progress.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../../domain/usecases/analysis_usecase.dart';

final coreConceptExtractionDataSourceProvider =
    Provider<CoreConceptExtractionDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return CoreConceptExtractionDataSource(client);
});

final analysisRemoteDataSourceProvider = Provider<AnalysisRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }

  return AnalysisRemoteDataSource(
    client: client,
    conceptDataSource: ref.watch(coreConceptExtractionDataSourceProvider),
  );
});

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return AnalysisRepositoryImpl(
    remoteDataSource: ref.watch(analysisRemoteDataSourceProvider),
  );
});

final analysisUseCaseProvider = Provider<AnalysisUseCase>((ref) {
  return AnalysisUseCase(ref.watch(analysisRepositoryProvider));
});

final analysisControllerProvider =
    StateNotifierProvider.autoDispose<AnalysisController, AsyncValue<AnalysisProgress?>>((ref) {
  return AnalysisController(ref);
});

class AnalysisController extends StateNotifier<AsyncValue<AnalysisProgress?>> {
  AnalysisController(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  String? _startedMaterialId;

  Future<void> start({required String materialId}) async {
    if (_startedMaterialId == materialId && state.isLoading) {
      return;
    }
    _startedMaterialId = materialId;

    state = AsyncData(
      AnalysisProgress(
        materialId: materialId,
        status: MaterialAnalysisStatus.uploaded,
        progress: 0.08,
        message: 'Preparing analysis.',
      ),
    );

    try {
      final result = await _ref.read(analysisUseCaseProvider).runFastPathAnalysis(
            materialId: materialId,
            onProgress: (progress) => state = AsyncData(progress),
          );
      state = AsyncData(result);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}