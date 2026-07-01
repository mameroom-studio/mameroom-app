import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/datasources/upload_remote_data_source.dart';
import '../../data/repositories/upload_repository_impl.dart';
import '../../domain/repositories/upload_repository.dart';
import '../../domain/usecases/upload_usecase.dart';

final uploadRemoteDataSourceProvider = Provider<UploadRemoteDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return UploadRemoteDataSource(client);
});

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepositoryImpl(
    remoteDataSource: ref.watch(uploadRemoteDataSourceProvider),
  );
});

final uploadUseCaseProvider = Provider<UploadUseCase>((ref) {
  return UploadUseCase(ref.watch(uploadRepositoryProvider));
});