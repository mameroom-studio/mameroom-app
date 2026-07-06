import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/datasources/memory_seed_remote_data_source.dart';
import '../../domain/entities/memory_seed.dart';

final memorySeedRemoteDataSourceProvider = Provider<MemorySeedRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return MemorySeedRemoteDataSource(client);
});


final completedMemorySeedsProvider = FutureProvider<List<MemorySeed>>((ref) {
  return ref.watch(memorySeedRemoteDataSourceProvider).loadCompletedSeeds();
});
final memorySeedControllerProvider =
    StateNotifierProvider<MemorySeedController, AsyncValue<MemorySeed?>>((ref) {
  final controller = MemorySeedController(ref);
  Future.microtask(controller.load);
  return controller;
});

class MemorySeedController extends StateNotifier<AsyncValue<MemorySeed?>> {
  MemorySeedController(this._ref) : super(const AsyncLoading());

  final Ref _ref;

  Future<void> load() async {
    try {
      final seed = await _ref.read(memorySeedRemoteDataSourceProvider).loadCurrentSeed();
      state = AsyncData(seed);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<MemorySeedGrowthResult> applyQuizResultGrowth({
    required int correctCount,
    required int totalCount,
    required double accuracy,
  }) async {
    final result = await _ref.read(memorySeedRemoteDataSourceProvider).applyQuizResultGrowth(
          correctCount: correctCount,
          totalCount: totalCount,
          accuracy: accuracy,
        );
    state = AsyncData(result.seed);
    return result;
  }
}
