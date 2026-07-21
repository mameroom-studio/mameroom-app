import '../../domain/mameroom_notification.dart';

class MameroomNotificationPayloadMapper {
  const MameroomNotificationPayloadMapper._();

  static MameroomNotification fromMap(Map<String, Object?> payload) {
    final type = _typeFromPayload(payload['type']?.toString() ?? '');
    final createdAt =
        DateTime.tryParse(payload['createdAt']?.toString() ?? '') ??
        DateTime.now();
    return MameroomNotification(
      id:
          payload['id']?.toString() ??
          createdAt.microsecondsSinceEpoch.toString(),
      type: type,
      title: payload['title']?.toString() ?? type.popupTitle,
      message: payload['message']?.toString() ?? '',
      createdAt: createdAt,
      isRead: payload['isRead'] == true,
      rewardAmount: payload['rewardAmount'] is int
          ? payload['rewardAmount'] as int
          : int.tryParse(payload['rewardAmount']?.toString() ?? ''),
      payload: payload,
      actionLabel: payload['actionLabel']?.toString(),
      actionType: _actionFromPayload(payload['actionType']?.toString()),
    );
  }

  static MameroomNotificationType _typeFromPayload(String value) {
    return switch (value) {
      'seed_growth' || 'seedGrowth' => MameroomNotificationType.seedGrowth,
      'review_reminder' ||
      'reviewReminder' => MameroomNotificationType.reviewReminder,
      'level_up' || 'levelUp' => MameroomNotificationType.levelUp,
      'friend_activity' ||
      'friendActivity' => MameroomNotificationType.friendActivity,
      'coin_reward' || 'coinReward' => MameroomNotificationType.coinReward,
      'diamond_reward' ||
      'diamondReward' => MameroomNotificationType.diamondReward,
      'event' => MameroomNotificationType.event,
      'upload_complete' ||
      'uploadComplete' => MameroomNotificationType.uploadComplete,
      _ => MameroomNotificationType.announcement,
    };
  }

  static MameroomNotificationActionType? _actionFromPayload(String? value) {
    return switch (value) {
      'open_seed' || 'openSeed' => MameroomNotificationActionType.openSeed,
      'open_review' ||
      'openReview' => MameroomNotificationActionType.openReview,
      'open_friends' ||
      'openFriends' => MameroomNotificationActionType.openFriends,
      'open_study' || 'openStudy' => MameroomNotificationActionType.openStudy,
      'open_shop' || 'openShop' => MameroomNotificationActionType.openShop,
      'open_notice' ||
      'openNotice' => MameroomNotificationActionType.openNotice,
      'claim_reward' ||
      'claimReward' => MameroomNotificationActionType.claimReward,
      'none' => MameroomNotificationActionType.none,
      _ => null,
    };
  }
}
