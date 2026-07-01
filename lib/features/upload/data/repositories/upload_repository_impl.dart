import '../../domain/entities/upload_job.dart';
import '../../domain/entities/upload_result.dart';
import '../../domain/repositories/upload_repository.dart';
import '../datasources/upload_remote_data_source.dart';

class UploadRepositoryImpl implements UploadRepository {
  const UploadRepositoryImpl({this.remoteDataSource});

  final UploadRemoteDataSource? remoteDataSource;

  @override
  Future<UploadResult> createMaterialFromDraft(UploadJob job) {
    final dataSource = remoteDataSource;
    if (dataSource == null) {
      throw StateError('Supabase is not configured. Check .env values.');
    }

    return dataSource.createMaterialFromDraft(job);
  }
}