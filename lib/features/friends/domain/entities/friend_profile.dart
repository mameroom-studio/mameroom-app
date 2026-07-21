enum FriendRelationshipState {
  none,
  outgoingPending,
  incomingPending,
  accepted,
  self,
  blockedByMe,
  blockedMe,
  rejected,
  expired,
  cancelled,
  unavailable,
}

enum FriendRequestStatus { pending, accepted, rejected, expired, cancelled }

enum FriendRoomVisibility { public, friends, private }

final class FriendProfile {
  const FriendProfile({
    required this.id,
    required this.nickname,
    required this.friendCode,
    required this.level,
    required this.statusMessage,
    required this.relationship,
    required this.roomVisibility,
    this.avatarKey,
    this.requestId,
    this.requestedAt,
    this.isProcessing = false,
  });

  final String id;
  final String nickname;
  final String friendCode;
  final int level;
  final String statusMessage;
  final FriendRelationshipState relationship;
  final FriendRoomVisibility roomVisibility;
  final String? avatarKey;
  final String? requestId;
  final DateTime? requestedAt;
  final bool isProcessing;

  bool get canVisitRoom =>
      relationship == FriendRelationshipState.accepted &&
      roomVisibility != FriendRoomVisibility.private;

  FriendProfile copyWith({
    FriendRelationshipState? relationship,
    String? requestId,
    bool? isProcessing,
  }) => FriendProfile(
    id: id,
    nickname: nickname,
    friendCode: friendCode,
    level: level,
    statusMessage: statusMessage,
    relationship: relationship ?? this.relationship,
    roomVisibility: roomVisibility,
    avatarKey: avatarKey,
    requestId: requestId ?? this.requestId,
    requestedAt: requestedAt,
    isProcessing: isProcessing ?? this.isProcessing,
  );
}

final class FriendPage<T> {
  const FriendPage({required this.items, this.nextCursor});
  final List<T> items;
  final String? nextCursor;
  bool get hasMore => nextCursor != null;
}
