import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_data_source.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl(this._remoteDataSource);
  final LibraryRemoteDataSource _remoteDataSource;
  @override
  Future<void> deleteStudyMaterial(String materialId) =>
      _remoteDataSource.deleteStudyMaterial(materialId);
}
