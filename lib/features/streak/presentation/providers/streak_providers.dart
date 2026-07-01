import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../data/datasources/streak_remote_data_source.dart';
import '../../data/repositories/streak_repository_impl.dart';
import '../../domain/entities/streak_state.dart';
import '../../domain/repositories/streak_repository.dart';
import '../../domain/usecases/streak_usecase.dart';

final streakRemoteDataSourceProvider = Provider<StreakRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return StreakRemoteDataSource(client);
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepositoryImpl(
    remoteDataSource: ref.watch(streakRemoteDataSourceProvider),
  );
});

final streakUseCaseProvider = Provider<StreakUseCase>((ref) {
  return StreakUseCase(ref.watch(streakRepositoryProvider));
});

final streakProvider = FutureProvider<StreakState>((ref) {
  return ref.watch(streakUseCaseProvider).loadStreak();
});

Future<StreakState> recordStreakCompletion(
  Ref ref, {
  required String sourceType,
  required String sourceId,
}) async {
  final result = await ref.read(streakUseCaseProvider).recordStudyCompletion(
        sourceType: sourceType,
        sourceId: sourceId,
      );
  ref.invalidate(streakProvider);
  if (result.milestoneReward > 0) {
    ref.invalidate(coinWalletProvider);
  }
  return result;
}