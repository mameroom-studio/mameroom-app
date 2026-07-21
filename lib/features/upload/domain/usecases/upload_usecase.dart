import '../entities/upload_job.dart';
import '../entities/upload_material_draft.dart';
import '../entities/upload_result.dart';
import '../repositories/upload_repository.dart';

class UploadUseCase {
  const UploadUseCase(this.repository);

  final UploadRepository repository;

  Future<UploadResult> createMaterialFromDraft(
    UploadJob job, {
    void Function(UploadTransferStage stage)? onStage,
  }) {
    return repository.createMaterialFromDraft(job, onStage: onStage);
  }

  Future<UploadMaterialDraft> loadMaterialDraft(String materialId) {
    return repository.loadMaterialDraft(materialId);
  }

  Future<void> updateMaterialDraft({
    required String materialId,
    required String title,
    required String content,
  }) {
    return repository.updateMaterialDraft(
      materialId: materialId,
      title: title,
      content: content,
    );
  }
}
