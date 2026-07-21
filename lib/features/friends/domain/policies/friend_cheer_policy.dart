// ignore_for_file: prefer_interpolation_to_compose_strings

abstract final class FriendCheerPolicy {
  static const int firstDailyReward = 5;
  static String idempotencyKey({
    required String visitorId,
    required String friendId,
    required DateTime localDate,
  }) =>
      'friend_room_first_cheer:' +
      visitorId +
      ':' +
      friendId +
      ':' +
      localDate.year.toString() +
      '-' +
      localDate.month.toString() +
      '-' +
      localDate.day.toString();
}
