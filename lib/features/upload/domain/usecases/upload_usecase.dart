import '../entities/upload_job.dart';
import '../entities/upload_result.dart';
import '../repositories/upload_repository.dart';

class UploadUseCase {
  const UploadUseCase(this.repository);

  final UploadRepository repository;

  Future<UploadResult> createMaterialFromDraft(UploadJob job) {
    return repository.createMaterialFromDraft(job);
  }
}