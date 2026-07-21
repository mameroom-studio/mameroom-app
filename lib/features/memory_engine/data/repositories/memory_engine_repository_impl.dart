import '../../domain/entities/memory_engine_result.dart';
import '../../domain/repositories/memory_engine_repository.dart';
import '../datasources/memory_engine_remote_data_source.dart';

class MemoryEngineRepositoryImpl implements MemoryEngineRepository {
  const MemoryEngineRepositoryImpl(this._remote);
  final MemoryEngineRemoteDataSource _remote;
  @override
  Future<MemoryEngineResult> submit(MemoryEngineSubmission submission) =>
      _remote.submit(submission);
  @override
  Future<MemoryEngineResult> pass(MemoryEnginePass pass) => _remote.pass(pass);
  @override
  Future<Map<String, dynamic>> loadDue({
    int limit = 20,
    bool countOnly = false,
  }) => _remote.loadDue(limit: limit, countOnly: countOnly);
}
