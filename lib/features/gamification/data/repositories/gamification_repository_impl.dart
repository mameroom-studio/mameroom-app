import '../../domain/entities/room_item.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/gamification_remote_data_source.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  const GamificationRepositoryImpl({required GamificationRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final GamificationRemoteDataSource _remoteDataSource;

  @override
  Future<MyRoomState> loadMyRoom() {
    return _remoteDataSource.loadMyRoom();
  }

  @override
  Future<MyRoomState> purchaseItem({required String itemId}) {
    return _remoteDataSource.purchaseItem(itemId: itemId);
  }

  @override
  Future<MyRoomState> placeItem({required RoomItem item}) {
    return _remoteDataSource.placeItem(item: item);
  }
}