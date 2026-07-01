import '../repositories/library_repository.dart';

class LibraryUseCase {
  const LibraryUseCase(this.repository);

  final LibraryRepository repository;
}