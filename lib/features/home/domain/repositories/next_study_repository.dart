abstract interface class NextStudyRepository {
  Future<String?> findUnlearnedMaterialId();
}
