import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/room_item.dart';
import '../models/room_item_model.dart';

class GamificationRemoteDataSource {
  const GamificationRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<MyRoomState> loadMyRoom() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to load My Room.');
    }

    final wallet = await _client
        .from(SupabaseTables.userWallets)
        .select('balance')
        .eq('user_id', user.id)
        .maybeSingle();

    final itemRows = await _client
        .from(SupabaseTables.roomItems)
        .select('id,item_code,name,description,item_type,rarity,price,asset_key,asset_path,default_position_x,default_position_y,is_active')
        .eq('is_active', true)
        .order('price', ascending: true);

    final items = itemRows
        .map((row) => RoomItemModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
    final itemsById = {for (final item in items) item.id: item};

    final ownedRows = await _client
        .from(SupabaseTables.userItems)
        .select('item_id')
        .eq('user_id', user.id);
    final ownedItemIds = ownedRows
        .map((row) => (row as Map)['item_id'].toString())
        .toSet();

    final layoutRows = await _client
        .from(SupabaseTables.userRoomLayouts)
        .select('id,item_id,position_x,position_y')
        .eq('user_id', user.id);
    final layoutsByItemId = <String, UserRoomLayout>{};
    for (final row in layoutRows) {
      final json = Map<String, dynamic>.from(row as Map);
      final itemId = json['item_id']?.toString();
      final item = itemId == null ? null : itemsById[itemId];
      if (item == null) {
        continue;
      }
      layoutsByItemId[item.id] = UserRoomLayoutModel.fromJson(json: json, item: item);
    }

    for (final itemId in ownedItemIds) {
      final item = itemsById[itemId];
      if (item == null || layoutsByItemId.containsKey(itemId)) {
        continue;
      }
      layoutsByItemId[itemId] = UserRoomLayout(
        id: 'default:$itemId',
        item: item,
        positionX: item.defaultPositionX,
        positionY: item.defaultPositionY,
      );
    }

    return MyRoomState(
      walletBalance: _intFrom(wallet?['balance']),
      shopItems: items,
      ownedItemIds: ownedItemIds,
      layouts: layoutsByItemId.values.toList(growable: false),
    );
  }

  Future<MyRoomState> purchaseItem({required String itemId}) async {
    await _client.rpc('purchase_room_item', params: {'p_item_id': itemId});
    return loadMyRoom();
  }

  Future<MyRoomState> placeItem({required RoomItem item}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to place room items.');
    }

    await _client.from(SupabaseTables.userRoomLayouts).upsert({
      'user_id': user.id,
      'item_id': item.id,
      'position_x': item.defaultPositionX,
      'position_y': item.defaultPositionY,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,item_id');

    return loadMyRoom();
  }

  int _intFrom(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
