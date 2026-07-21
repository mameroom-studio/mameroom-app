import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/repositories/friend_room_repositories.dart';
import '../../data/repositories/supabase_friend_room_repository.dart';
import '../../domain/entities/friend_room.dart';
import '../../domain/policies/friend_cheer_policy.dart';
import '../../domain/repositories/friend_room_repository.dart';

class FriendRoomState {
  const FriendRoomState({
    required this.room,
    this.cheerStatus = FriendCheerStatus.idle,
    this.rewardAmount = 0,
    this.characterMessage,
  });

  final FriendRoom room;
  final FriendCheerStatus cheerStatus;
  final int rewardAmount;
  final String? characterMessage;

  FriendRoomState copyWith({
    FriendCheerStatus? cheerStatus,
    int? rewardAmount,
    String? characterMessage,
    bool clearMessage = false,
  }) => FriendRoomState(
    room: room,
    cheerStatus: cheerStatus ?? this.cheerStatus,
    rewardAmount: rewardAmount ?? this.rewardAmount,
    characterMessage: clearMessage
        ? null
        : characterMessage ?? this.characterMessage,
  );
}

final friendRoomRepositoryProvider = Provider<FriendRoomRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? MockFriendRoomRepository()
      : SupabaseFriendRoomRepository(client);
});

final friendRoomControllerProvider = StateNotifierProvider.autoDispose
    .family<FriendRoomController, AsyncValue<FriendRoomState>, String>(
      (ref, friendId) => FriendRoomController(
        repository: ref.watch(friendRoomRepositoryProvider),
        friendId: friendId,
      )..load(),
    );

class FriendRoomController extends StateNotifier<AsyncValue<FriendRoomState>> {
  FriendRoomController({
    required FriendRoomRepository repository,
    required this.friendId,
  }) : _repository = repository,
       super(const AsyncLoading());

  final FriendRoomRepository _repository;
  final String friendId;
  bool _cheerInFlight = false;
  DateTime? _lastCharacterTap;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final room = await _repository.loadRoom(friendId);
      state = AsyncData(
        FriendRoomState(
          room: room,
          cheerStatus: room.hasCheeredToday
              ? FriendCheerStatus.sentNoReward
              : FriendCheerStatus.idle,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void interactWithCharacter() {
    final value = state.asData?.value;
    if (value == null) return;
    final now = DateTime.now();
    if (_lastCharacterTap != null &&
        now.difference(_lastCharacterTap!) < const Duration(seconds: 1)) {
      return;
    }
    _lastCharacterTap = now;
    state = AsyncData(value.copyWith(characterMessage: '어서 와요!'));
  }

  void clearCharacterMessage() {
    final value = state.asData?.value;
    if (value != null) state = AsyncData(value.copyWith(clearMessage: true));
  }

  Future<void> sendCheer() async {
    final value = state.asData?.value;
    if (value == null || _cheerInFlight || !value.room.canCheer) return;
    _cheerInFlight = true;
    state = AsyncData(
      value.copyWith(
        cheerStatus: FriendCheerStatus.sending,
        characterMessage: '좋은 하루 보내요! 💜',
        rewardAmount: 0,
      ),
    );
    try {
      final result = await _repository.sendCheer(
        friendId: friendId,
        idempotencyKey: FriendCheerPolicy.idempotencyKey(
          visitorId: 'current-user',
          friendId: friendId,
          localDate: DateTime.now(),
        ),
      );
      final current = state.asData?.value ?? value;
      state = AsyncData(
        current.copyWith(
          cheerStatus: result.rewardGranted
              ? FriendCheerStatus.sentRewardGranted
              : FriendCheerStatus.sentNoReward,
          rewardAmount: result.rewardAmount,
          characterMessage: '응원 고마워요!',
        ),
      );
    } catch (_) {
      final current = state.asData?.value ?? value;
      state = AsyncData(
        current.copyWith(
          cheerStatus: FriendCheerStatus.failed,
          characterMessage: '응원을 보내지 못했어요.',
        ),
      );
    } finally {
      _cheerInFlight = false;
    }
  }
}
