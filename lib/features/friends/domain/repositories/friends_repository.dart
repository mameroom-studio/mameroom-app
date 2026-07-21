import '../entities/friend_profile.dart';

abstract interface class FriendsRepository {
  Future<FriendPage<FriendProfile>> search({
    required String query,
    String? cursor,
  });
  Future<List<FriendProfile>> recommended();
  Future<List<FriendProfile>> friends();
  Future<List<FriendProfile>> incomingRequests();
  Future<FriendProfile> sendRequest(String userId);
  Future<void> respondToRequest(String requestId, {required bool accept});
  Future<void> cancelRequest(String requestId);
  Future<void> deleteFriend(String userId);
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);
}
