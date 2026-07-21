import 'package:flutter/material.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../domain/mameroom_notification.dart';

class MameroomNotificationTile extends StatelessWidget {
  const MameroomNotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final MameroomNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final accent = _accentColor(colors, notification.type);
    return Semantics(
      button: true,
      label: notification.isRead ? '읽은 알림' : '읽지 않은 알림',
      child: Material(
        color: notification.isRead
            ? colors.paper.withValues(alpha: 0.70)
            : colors.paper,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: notification.isRead
                    ? colors.line
                    : colors.primaryPale.withValues(alpha: 0.80),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(
                    alpha: notification.isRead ? 0.03 : 0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: notification.isRead ? 0.10 : 0.18,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.32)),
                  ),
                  child: Icon(notification.type.icon, color: accent, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: notification.isRead
                                        ? colors.ink.withValues(alpha: 0.58)
                                        : colors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _timeAgo(notification.createdAt),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.muted,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.muted,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: notification.isRead ? colors.line : colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(MameroomTheme colors, MameroomNotificationType type) {
    return switch (type) {
      MameroomNotificationType.seedGrowth => colors.seedGreen,
      MameroomNotificationType.reviewReminder ||
      MameroomNotificationType.uploadComplete => colors.primary,
      MameroomNotificationType.friendActivity => const Color(0xFF5AA9FF),
      MameroomNotificationType.coinReward ||
      MameroomNotificationType.levelUp => colors.sun,
      MameroomNotificationType.diamondReward => const Color(0xFF705CFF),
      MameroomNotificationType.announcement => colors.muted,
      MameroomNotificationType.event => colors.blossom,
    };
  }
}

String _timeAgo(DateTime createdAt) {
  final now = DateTime(2026, 7, 12, 9, 41);
  final diff = now.difference(createdAt);
  if (diff.inMinutes < 2) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}
