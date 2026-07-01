import '../entities/upload_job.dart';
import '../entities/upload_result.dart';

abstract interface class UploadRepository {
  Future<UploadResult> createMaterialFromDraft(UploadJob job);
}