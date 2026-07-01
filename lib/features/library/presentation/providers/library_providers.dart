import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/library_repository_impl.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/usecases/library_usecase.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return const LibraryRepositoryImpl();
});

final libraryUseCaseProvider = Provider<LibraryUseCase>((ref) {
  return LibraryUseCase(ref.watch(libraryRepositoryProvider));
});