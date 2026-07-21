import '../entities/friend_room.dart';

class FriendCheerResult {
  const FriendCheerResult({
    required this.rewardGranted,
    required this.rewardAmount,
  });
  final bool rewardGranted;
  final int rewardAmount;
}

abstract interface class FriendRoomRepository {
  Future<FriendRoom> loadRoom(String friendId);
  Future<FriendCheerResult> sendCheer({
    required String friendId,
    required String idempotencyKey,
  });
}
