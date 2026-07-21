import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/datasources/library_remote_data_source.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/usecases/library_usecase.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase client is not initialized.');
  return LibraryRepositoryImpl(LibraryRemoteDataSource(client));
});
final libraryUseCaseProvider = Provider<LibraryUseCase>((ref) {
  return LibraryUseCase(ref.watch(libraryRepositoryProvider));
});
