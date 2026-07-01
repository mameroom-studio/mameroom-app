import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../data/datasources/gamification_remote_data_source.dart';
import '../../data/repositories/gamification_repository_impl.dart';
import '../../domain/entities/room_item.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/usecases/gamification_usecase.dart';

final gamificationRemoteDataSourceProvider = Provider<GamificationRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return GamificationRemoteDataSource(client);
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepositoryImpl(
    remoteDataSource: ref.watch(gamificationRemoteDataSourceProvider),
  );
});

final gamificationUseCaseProvider = Provider<GamificationUseCase>((ref) {
  return GamificationUseCase(ref.watch(gamificationRepositoryProvider));
});

final myRoomControllerProvider =
    StateNotifierProvider<MyRoomController, AsyncValue<MyRoomState>>((ref) {
  final controller = MyRoomController(ref);
  Future.microtask(controller.load);
  return controller;
});

class MyRoomController extends StateNotifier<AsyncValue<MyRoomState>> {
  MyRoomController(this._ref) : super(const AsyncLoading());

  final Ref _ref;

  Future<void> load() async {
    try {
      final stateValue = await _ref.read(gamificationUseCaseProvider).loadMyRoom();
      state = AsyncData(stateValue);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> purchase(RoomItem item) async {
    final previous = state;
    state = const AsyncLoading();
    try {
      final stateValue = await _ref
          .read(gamificationUseCaseProvider)
          .purchaseItem(itemId: item.id);
      _ref.invalidate(coinWalletProvider);
      state = AsyncData(stateValue);
    } catch (error, stackTrace) {
      state = previous;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> place(RoomItem item) async {
    final previous = state;
    state = const AsyncLoading();
    try {
      final stateValue = await _ref.read(gamificationUseCaseProvider).placeItem(item: item);
      state = AsyncData(stateValue);
    } catch (error, stackTrace) {
      state = previous;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}