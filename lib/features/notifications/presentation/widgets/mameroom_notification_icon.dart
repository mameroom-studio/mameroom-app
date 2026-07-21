import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../providers/notification_providers.dart';
import 'mameroom_notification_badge.dart';

class MameroomNotificationIcon extends ConsumerWidget {
  const MameroomNotificationIcon({
    super.key,
    required this.onPressed,
    this.size = 36,
    this.iconSize = 24,
  });

  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(mameroomUnreadNotificationCountProvider);
    final colors = context.mameroom;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IconButton(
              tooltip: '알림',
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              icon: Icon(
                Icons.notifications_none_rounded,
                color: colors.ink,
                size: iconSize,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: MameroomNotificationBadge(count: count),
          ),
        ],
      ),
    );
  }
}
