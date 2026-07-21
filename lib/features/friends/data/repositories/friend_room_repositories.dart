// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/foundation.dart';

import '../../../gamification/domain/entities/room_item.dart';
import '../../domain/entities/friend_room.dart';
import '../../domain/policies/friend_cheer_policy.dart';
import '../../domain/repositories/friend_room_repository.dart';

final class ProductionFriendRoomRepository implements FriendRoomRepository {
  const ProductionFriendRoomRepository();

  @override
  Future<FriendRoom> loadRoom(String friendId) {
    throw const FriendRoomUnavailableException();
  }

  @override
  Future<FriendCheerResult> sendCheer({
    required String friendId,
    required String idempotencyKey,
  }) {
    throw const FriendRoomUnavailableException();
  }
}

final class MockFriendRoomRepository implements FriendRoomRepository {
  MockFriendRoomRepository({
    this.loadDelay = const Duration(milliseconds: 750),
  });

  final Duration loadDelay;
  final Set<String> _sentKeys = <String>{};

  @override
  Future<FriendRoom> loadRoom(String friendId) async {
    if (loadDelay > Duration.zero) await Future<void>.delayed(loadDelay);
    if (friendId.trim().isEmpty || friendId == 'invalid') {
      throw const FriendRoomNotFoundException();
    }
    final visitState = switch (friendId) {
      'private-room' => FriendRoomVisitState.private,
      'unavailable-room' => FriendRoomVisitState.unavailable,
      _ => FriendRoomVisitState.loaded,
    };
    return FriendRoom(
      friendId: friendId,
      nickname: _nickname(friendId),
      level: 18,
      streakDays: 24,
      memoryRate: .84,
      schoolName: '마메고등학교',
      studyStatus: '공부 중이에요.',
      visitState: visitState,
      furnitureItems: visitState == FriendRoomVisitState.loaded
          ? _fixtures
          : const [],
      recentGrowthItems: const [
        FriendRecentGrowth(label: '기억씨앗 Lv.3 달성!', iconKey: 'seed'),
        FriendRecentGrowth(label: "새 가구 '스탠드' 획득", iconKey: 'lamp'),
      ],
      canCheer: true,
      rewardEligible: friendId != 'already-cheered',
      rewardAmount: FriendCheerPolicy.firstDailyReward,
      hasCheeredToday: friendId == 'already-cheered',
      isDecorated: friendId != 'empty-room',
      accessibilityLabel: _nickname(friendId) + '님의 따뜻한 공부방',
    );
  }

  @override
  Future<FriendCheerResult> sendCheer({
    required String friendId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (friendId == 'cheer-fails') throw const FriendCheerException();
    final first =
        _sentKeys.add(idempotencyKey) && friendId != 'already-cheered';
    return FriendCheerResult(
      rewardGranted: first,
      rewardAmount: first ? FriendCheerPolicy.firstDailyReward : 0,
    );
  }

  String _nickname(String id) => switch (id) {
    'friend-hyunwoo' => '박다은',
    'friend-minsu' => '최지인',
    'friend-haeun' => '이서준',
    _ => '김유이',
  };
}

class FriendRoomUnavailableException implements Exception {
  const FriendRoomUnavailableException();
}

class FriendRoomNotFoundException implements Exception {
  const FriendRoomNotFoundException();
}

class FriendCheerException implements Exception {
  const FriendCheerException();
}

const _fixtures = <UserRoomLayout>[
  UserRoomLayout(
    id: 'friend-bookshelf',
    item: RoomItem(
      id: 'bookshelf',
      itemCode: 'basic_bookshelf',
      name: '기본 책장',
      description: '책과 학습 기록을 정리해두는 따뜻한 원목 책장입니다.',
      itemType: 'shelf',
      rarity: 'Common',
      price: 0,
      assetKey: 'bookshelf',
      assetPath: '',
      defaultPositionX: .86,
      defaultPositionY: .34,
      isActive: true,
    ),
    positionX: .86,
    positionY: .34,
  ),
  UserRoomLayout(
    id: 'friend-desk',
    item: RoomItem(
      id: 'desk',
      itemCode: 'study_desk',
      name: '공부 책상',
      description: '집중할 수 있도록 정돈된 따뜻한 공부 책상입니다.',
      itemType: 'desk',
      rarity: 'Common',
      price: 0,
      assetKey: 'desk',
      assetPath: '',
      defaultPositionX: .72,
      defaultPositionY: .58,
      isActive: true,
    ),
    positionX: .72,
    positionY: .58,
  ),
];

FriendRoomRepository defaultFriendRoomRepository() {
  return kDebugMode
      ? MockFriendRoomRepository()
      : const ProductionFriendRoomRepository();
}
