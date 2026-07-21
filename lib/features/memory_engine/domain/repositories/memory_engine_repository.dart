import '../entities/memory_engine_result.dart';

abstract interface class MemoryEngineRepository {
  Future<MemoryEngineResult> submit(MemoryEngineSubmission submission);
  Future<MemoryEngineResult> pass(MemoryEnginePass pass);
  Future<Map<String, dynamic>> loadDue({
    int limit = 20,
    bool countOnly = false,
  });
}
