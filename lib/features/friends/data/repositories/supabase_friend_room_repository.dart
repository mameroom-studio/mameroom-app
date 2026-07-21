import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../gamification/domain/entities/room_item.dart';
import '../../domain/entities/friend_room.dart';
import '../../domain/repositories/friend_room_repository.dart';
import 'friend_room_repositories.dart';

final class SupabaseFriendRoomRepository implements FriendRoomRepository {
  const SupabaseFriendRoomRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<FriendRoom> loadRoom(String friendId) async {
    try {
      final response = await _client.rpc(
        'get_friend_room',
        params: {'p_friend_id': friendId},
      );
      if (response is! Map) throw const FormatException('invalid_friend_room');
      final json = Map<String, dynamic>.from(response);
      final furniture = (json['furniture'] as List<dynamic>? ?? const [])
          .map((value) => _layout(Map<String, dynamic>.from(value as Map)))
          .toList(growable: false);
      final nickname = json['nickname'] as String? ?? '';
      return FriendRoom(
        friendId: json['friend_id'] as String? ?? friendId,
        nickname: nickname,
        profileImageUrl: json['avatar_key'] as String?,
        level: (json['level'] as num?)?.toInt() ?? 1,
        streakDays: 0,
        memoryRate: 0,
        schoolName: '',
        studyStatus: json['status_message'] as String? ?? '',
        visitState: FriendRoomVisitState.fromValue(
          json['visit_state'] as String?,
        ),
        furnitureItems: furniture,
        recentGrowthItems: const [],
        canCheer: false,
        rewardEligible: false,
        rewardAmount: 0,
        hasCheeredToday: false,
        isDecorated: json['is_decorated'] as bool? ?? furniture.isNotEmpty,
        accessibilityLabel: '$nickname님의 읽기 전용 방',
      );
    } on PostgrestException catch (error) {
      if (error.message.contains('friend_room_unavailable')) {
        throw const FriendRoomNotFoundException();
      }
      if (error.code == '42501' ||
          error.message.contains('friend_room_not_friend') ||
          error.message.contains('friend_room_private') ||
          error.message.contains('friend_room_access_denied')) {
        throw const FriendRoomAccessDeniedException();
      }
      rethrow;
    }
  }

  @override
  Future<FriendCheerResult> sendCheer({
    required String friendId,
    required String idempotencyKey,
  }) {
    throw const FriendRoomUnavailableException();
  }

  static UserRoomLayout _layout(Map<String, dynamic> json) => UserRoomLayout(
    id: json['layout_id'] as String,
    positionX: (json['position_x'] as num).toDouble(),
    positionY: (json['position_y'] as num).toDouble(),
    item: RoomItem(
      id: json['item_id'] as String,
      itemCode: json['item_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      itemType: json['item_type'] as String? ?? '',
      rarity: json['rarity'] as String? ?? 'common',
      price: 0,
      assetKey: json['asset_key'] as String? ?? '',
      assetPath: json['asset_path'] as String? ?? '',
      defaultPositionX: (json['default_position_x'] as num?)?.toDouble() ?? .5,
      defaultPositionY: (json['default_position_y'] as num?)?.toDouble() ?? .5,
      isActive: true,
    ),
  );
}

class FriendRoomAccessDeniedException implements Exception {
  const FriendRoomAccessDeniedException();
}
