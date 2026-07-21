import '../entities/upload_job.dart';
import '../entities/upload_material_draft.dart';
import '../entities/upload_result.dart';

abstract interface class UploadRepository {
  Future<UploadResult> createMaterialFromDraft(
    UploadJob job, {
    void Function(UploadTransferStage stage)? onStage,
  });

  Future<UploadMaterialDraft> loadMaterialDraft(String materialId);

  Future<void> updateMaterialDraft({
    required String materialId,
    required String title,
    required String content,
  });
}
