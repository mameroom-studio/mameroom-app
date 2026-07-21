import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecase.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return AuthRemoteDataSource(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

final authUseCaseProvider = Provider<AuthUseCase>((ref) {
  return AuthUseCase(ref.watch(authRepositoryProvider));
});

final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final useCase = ref.watch(authUseCaseProvider);
  yield useCase.currentUser;
  yield* useCase.authStateChanges;
});
