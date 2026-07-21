import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../gamification/presentation/pages/room_page.dart';
import '../../home/presentation/pages/home_shell_page.dart';
import '../../library/presentation/pages/library_page.dart';
import '../../memory_seed/presentation/pages/arboretum_page.dart';
import '../../review/presentation/pages/review_page.dart';
import '../domain/mameroom_notification.dart';
import 'widgets/mameroom_notification_popup.dart';

class MameroomNotificationActionResolver {
  const MameroomNotificationActionResolver();

  Future<void> resolve(
    BuildContext context,
    MameroomNotification notification,
  ) async {
    final action = notification.actionType ?? _defaultAction(notification.type);
    switch (action) {
      case MameroomNotificationActionType.openSeed:
        context.push(ArboretumPage.routePath);
      case MameroomNotificationActionType.openReview:
        context.push(ReviewPage.routePath);
      case MameroomNotificationActionType.openFriends:
        context.go(HomeShellPage.rankRoutePath);
      case MameroomNotificationActionType.openStudy:
        context.go(LibraryPage.routePath);
      case MameroomNotificationActionType.openShop:
        context.push(RoomPage.routePath);
      case MameroomNotificationActionType.openNotice:
      case MameroomNotificationActionType.claimReward:
      case MameroomNotificationActionType.none:
        await MameroomNotificationPopup.show(context, notification);
    }
  }

  MameroomNotificationActionType _defaultAction(MameroomNotificationType type) {
    return switch (type) {
      MameroomNotificationType.seedGrowth =>
        MameroomNotificationActionType.openSeed,
      MameroomNotificationType.reviewReminder =>
        MameroomNotificationActionType.openReview,
      MameroomNotificationType.friendActivity =>
        MameroomNotificationActionType.openFriends,
      MameroomNotificationType.uploadComplete =>
        MameroomNotificationActionType.openStudy,
      MameroomNotificationType.coinReward ||
      MameroomNotificationType.diamondReward ||
      MameroomNotificationType.levelUp =>
        MameroomNotificationActionType.claimReward,
      MameroomNotificationType.announcement || MameroomNotificationType.event =>
        MameroomNotificationActionType.openNotice,
    };
  }
}
