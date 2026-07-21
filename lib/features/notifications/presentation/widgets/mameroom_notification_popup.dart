import 'package:flutter/material.dart';

import '../../../../core/presentation/modals/mameroom_modals.dart';
import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../domain/mameroom_notification.dart';

class MameroomNotificationPopup {
  const MameroomNotificationPopup._();

  static Future<void> show(
    BuildContext context,
    MameroomNotification notification,
  ) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) =>
          _NotificationPopupModal(notification: notification),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _NotificationPopupModal extends StatelessWidget {
  const _NotificationPopupModal({required this.notification});

  final MameroomNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return MameroomModal(
      title: notification.type.popupTitle,
      message: notification.message,
      icon: notification.type.icon,
      variant: _variant(notification.type),
      primaryButtonText: '확인',
      onPrimary: () => Navigator.of(context).pop(),
      customContent: notification.rewardAmount == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: colors.cloud,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(notification.type.icon, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+${notification.rewardAmount}',
                    style: TextStyle(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  MameroomModalVariant _variant(MameroomNotificationType type) {
    return switch (type) {
      MameroomNotificationType.seedGrowth => MameroomModalVariant.seedGrowth,
      MameroomNotificationType.coinReward ||
      MameroomNotificationType.diamondReward ||
      MameroomNotificationType.levelUp => MameroomModalVariant.reward,
      MameroomNotificationType.uploadComplete => MameroomModalVariant.success,
      _ => MameroomModalVariant.info,
    };
  }
}
