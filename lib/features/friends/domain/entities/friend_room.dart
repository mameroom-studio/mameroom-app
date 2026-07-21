// ignore_for_file: prefer_interpolation_to_compose_strings

import '../../../gamification/domain/entities/room_item.dart';

enum FriendRoomVisitState {
  visitable,
  private,
  unavailable,
  loading,
  loaded,
  failed;

  static FriendRoomVisitState fromValue(String? value) => switch (value) {
    'visitable' => visitable,
    'private' => private,
    'loaded' => loaded,
    'loading' => loading,
    'failed' => failed,
    _ => unavailable,
  };
}

enum FriendCheerStatus {
  idle,
  sending,
  sentRewardGranted,
  sentNoReward,
  failed,
}

class RoomCapabilities {
  const RoomCapabilities({
    required this.canEdit,
    required this.canMoveFurniture,
    required this.canDeleteFurniture,
    required this.canOpenInventory,
    required this.canSave,
    required this.canPurchase,
    required this.canInspectFurniture,
    required this.canInteractWithCharacter,
    required this.canCheer,
  });
  static const friendReadOnly = RoomCapabilities(
    canEdit: false,
    canMoveFurniture: false,
    canDeleteFurniture: false,
    canOpenInventory: false,
    canSave: false,
    canPurchase: false,
    canInspectFurniture: true,
    canInteractWithCharacter: true,
    canCheer: true,
  );
  final bool canEdit,
      canMoveFurniture,
      canDeleteFurniture,
      canOpenInventory,
      canSave,
      canPurchase,
      canInspectFurniture,
      canInteractWithCharacter,
      canCheer;
}

class FriendRecentGrowth {
  const FriendRecentGrowth({required this.label, required this.iconKey});
  final String label;
  final String iconKey;
}

class FriendRoom {
  const FriendRoom({
    required this.friendId,
    required this.nickname,
    required this.level,
    required this.streakDays,
    required this.memoryRate,
    required this.schoolName,
    required this.studyStatus,
    required this.visitState,
    required this.furnitureItems,
    required this.recentGrowthItems,
    required this.canCheer,
    required this.rewardEligible,
    required this.rewardAmount,
    required this.hasCheeredToday,
    required this.isDecorated,
    this.profileImageUrl,
    this.accessibilityLabel,
  });
  final String friendId, nickname;
  final String? profileImageUrl;
  final int level, streakDays;
  final double memoryRate;
  final String schoolName, studyStatus;
  final FriendRoomVisitState visitState;
  final List<UserRoomLayout> furnitureItems;
  final List<FriendRecentGrowth> recentGrowthItems;
  final bool canCheer, rewardEligible, hasCheeredToday, isDecorated;
  final int rewardAmount;
  final String? accessibilityLabel;
  String get roomTitle => nickname + '의 방';
}
