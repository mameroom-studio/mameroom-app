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
        .select('id,item_code,name,item_type,price,asset_path,is_active')
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
    final layouts = <UserRoomLayout>[];
    for (final row in layoutRows) {
      final json = Map<String, dynamic>.from(row as Map);
      final item = itemsById[json['item_id']];
      if (item == null) {
        continue;
      }
      layouts.add(UserRoomLayoutModel.fromJson(json: json, item: item));
    }

    return MyRoomState(
      walletBalance: _intFrom(wallet?['balance']),
      shopItems: items,
      ownedItemIds: ownedItemIds,
      layouts: layouts,
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

    final position = _defaultPosition(item.itemType);
    await _client.from(SupabaseTables.userRoomLayouts).upsert({
      'user_id': user.id,
      'item_id': item.id,
      'position_x': position.$1,
      'position_y': position.$2,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,item_id');

    return loadMyRoom();
  }

  (double, double) _defaultPosition(String itemType) {
    return switch (itemType) {
      'desk' => (0.50, 0.66),
      'chair' => (0.34, 0.72),
      'plant' => (0.78, 0.64),
      'lamp' => (0.18, 0.58),
      _ => (0.50, 0.70),
    };
  }

  int _intFrom(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}