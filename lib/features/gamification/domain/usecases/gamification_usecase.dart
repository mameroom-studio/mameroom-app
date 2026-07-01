import '../entities/room_item.dart';
import '../repositories/gamification_repository.dart';

class GamificationUseCase {
  const GamificationUseCase(this.repository);

  final GamificationRepository repository;

  Future<MyRoomState> loadMyRoom() => repository.loadMyRoom();

  Future<MyRoomState> purchaseItem({required String itemId}) {
    return repository.purchaseItem(itemId: itemId);
  }

  Future<MyRoomState> placeItem({required RoomItem item}) {
    return repository.placeItem(item: item);
  }
}