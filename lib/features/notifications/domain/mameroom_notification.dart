import 'package:flutter/material.dart';

enum MameroomNotificationType {
  seedGrowth,
  reviewReminder,
  levelUp,
  friendActivity,
  coinReward,
  diamondReward,
  announcement,
  event,
  uploadComplete,
}

enum MameroomNotificationCategory {
  all,
  unread,
  seed,
  study,
  social,
  reward,
  notice,
}

enum MameroomNotificationActionType {
  openSeed,
  openReview,
  openFriends,
  openStudy,
  openShop,
  openNotice,
  claimReward,
  none,
}

@immutable
class MameroomNotification {
  const MameroomNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.rewardAmount,
    this.payload = const {},
    this.actionLabel,
    this.actionType,
  });

  final String id;
  final MameroomNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int? rewardAmount;
  final Map<String, Object?> payload;
  final String? actionLabel;
  final MameroomNotificationActionType? actionType;

  MameroomNotification copyWith({
    String? id,
    MameroomNotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    int? rewardAmount,
    Map<String, Object?>? payload,
    String? actionLabel,
    MameroomNotificationActionType? actionType,
  }) {
    return MameroomNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      payload: payload ?? this.payload,
      actionLabel: actionLabel ?? this.actionLabel,
      actionType: actionType ?? this.actionType,
    );
  }
}

extension MameroomNotificationTypeX on MameroomNotificationType {
  String get label {
    return switch (this) {
      MameroomNotificationType.seedGrowth => '성장',
      MameroomNotificationType.reviewReminder => '학습',
      MameroomNotificationType.levelUp => '업적',
      MameroomNotificationType.friendActivity => '소셜',
      MameroomNotificationType.coinReward => '보상',
      MameroomNotificationType.diamondReward => '보상',
      MameroomNotificationType.announcement => '공지',
      MameroomNotificationType.event => '이벤트',
      MameroomNotificationType.uploadComplete => '학습',
    };
  }

  String get popupTitle {
    return switch (this) {
      MameroomNotificationType.seedGrowth => '성장했어요!',
      MameroomNotificationType.coinReward => '코인 획득!',
      MameroomNotificationType.diamondReward => '다이아 획득!',
      MameroomNotificationType.levelUp => '레벨업!',
      MameroomNotificationType.uploadComplete => '업로드 완료',
      _ => '알림',
    };
  }

  IconData get icon {
    return switch (this) {
      MameroomNotificationType.seedGrowth => Icons.eco_rounded,
      MameroomNotificationType.reviewReminder => Icons.menu_book_rounded,
      MameroomNotificationType.levelUp => Icons.workspace_premium_rounded,
      MameroomNotificationType.friendActivity => Icons.groups_rounded,
      MameroomNotificationType.coinReward => Icons.monetization_on_rounded,
      MameroomNotificationType.diamondReward => Icons.diamond_rounded,
      MameroomNotificationType.announcement => Icons.campaign_rounded,
      MameroomNotificationType.event => Icons.card_giftcard_rounded,
      MameroomNotificationType.uploadComplete => Icons.description_rounded,
    };
  }

  MameroomNotificationCategory get category {
    return switch (this) {
      MameroomNotificationType.seedGrowth => MameroomNotificationCategory.seed,
      MameroomNotificationType.reviewReminder ||
      MameroomNotificationType.uploadComplete =>
        MameroomNotificationCategory.study,
      MameroomNotificationType.friendActivity =>
        MameroomNotificationCategory.social,
      MameroomNotificationType.coinReward ||
      MameroomNotificationType.diamondReward ||
      MameroomNotificationType.levelUp => MameroomNotificationCategory.reward,
      MameroomNotificationType.announcement ||
      MameroomNotificationType.event => MameroomNotificationCategory.notice,
    };
  }
}

extension MameroomNotificationCategoryX on MameroomNotificationCategory {
  String get label {
    return switch (this) {
      MameroomNotificationCategory.all => '전체',
      MameroomNotificationCategory.unread => '읽지 않음',
      MameroomNotificationCategory.seed => '씨앗',
      MameroomNotificationCategory.study => '학습',
      MameroomNotificationCategory.social => '소셜',
      MameroomNotificationCategory.reward => '보상',
      MameroomNotificationCategory.notice => '공지',
    };
  }
}
