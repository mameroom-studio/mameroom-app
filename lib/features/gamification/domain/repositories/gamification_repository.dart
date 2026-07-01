import '../entities/room_item.dart';

abstract interface class GamificationRepository {
  Future<MyRoomState> loadMyRoom();
  Future<MyRoomState> purchaseItem({required String itemId});
  Future<MyRoomState> placeItem({required RoomItem item});
}