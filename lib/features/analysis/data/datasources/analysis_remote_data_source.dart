import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/analysis_progress.dart';
import 'openai_concept_data_source.dart';

class AnalysisRemoteDataSource {
  const AnalysisRemoteDataSource({
    required SupabaseClient client,
    required CoreConceptExtractionDataSource conceptDataSource,
  })  : _client = client,
        _conceptDataSource = conceptDataSource;

  final SupabaseClient _client;
  final CoreConceptExtractionDataSource _conceptDataSource;

  Future<AnalysisProgress> runFastPathAnalysis({
    required String materialId,
    AnalysisProgressCallback? onProgress,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to analyze materials.');
    }

    try {
      final material = await _loadMaterial(materialId: materialId, userId: user.id);
      final currentStatus = MaterialAnalysisStatus.fromValue(
        material['status'] as String? ?? 'uploaded',
      );

      if (currentStatus == MaterialAnalysisStatus.conceptsCompleted ||
          currentStatus == MaterialAnalysisStatus.completed) {
        final conceptCount = await _countConcepts(materialId: materialId);
        return AnalysisProgress(
          materialId: materialId,
          status: MaterialAnalysisStatus.conceptsCompleted,
          progress: 1,
          message: 'Core concepts are already extracted.',
          conceptCount: conceptCount,
        );
      }

      onProgress?.call(AnalysisProgress(
        materialId: materialId,
        status: MaterialAnalysisStatus.extracting,
        progress: 0.25,
        message: 'Requesting server-side text extraction.',
      ));
      onProgress?.call(AnalysisProgress(
        materialId: materialId,
        status: MaterialAnalysisStatus.analyzing,
        progress: 0.55,
        message: 'Calling extract-core-concepts Edge Function.',
      ));

      final result = await _conceptDataSource.extractConcepts(materialId: materialId);

      onProgress?.call(AnalysisProgress(
        materialId: materialId,
        status: MaterialAnalysisStatus.conceptsCompleted,
        progress: 1,
        message: 'Core concepts saved on the server.',
        conceptCount: result.conceptCount,
        usedCache: result.usedCache,
      ));

      return AnalysisProgress(
        materialId: materialId,
        status: MaterialAnalysisStatus.conceptsCompleted,
        progress: 1,
        message: result.message,
        conceptCount: result.conceptCount,
        usedCache: result.usedCache,
      );
    } catch (error) {
      await _safeMarkFailed(materialId: materialId, error: error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _loadMaterial({
    required String materialId,
    required String userId,
  }) async {
    final material = await _client
        .from(SupabaseTables.studyMaterials)
        .select('id,user_id,status')
        .eq('id', materialId)
        .eq('user_id', userId)
        .maybeSingle();

    if (material == null) {
      throw StateError('Study material was not found.');
    }
    return Map<String, dynamic>.from(material);
  }

  Future<int> _countConcepts({required String materialId}) async {
    final rows = await _client
        .from(SupabaseTables.concepts)
        .select('id')
        .eq('material_id', materialId);
    return rows.length;
  }

  Future<void> _safeMarkFailed({required String materialId, required Object error}) async {
    try {
      await _client.from(SupabaseTables.studyMaterials).update({
        'status': MaterialAnalysisStatus.failed.value,
        'analysis_error': error.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', materialId);
    } catch (_) {
      // Preserve the original failure for the caller.
    }
  }
}