import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/states/mameroom_states.dart';
import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../domain/mameroom_notification.dart';
import '../notification_action_resolver.dart';
import '../providers/notification_providers.dart';
import '../widgets/mameroom_notification_tile.dart';
import 'mameroom_notification_settings_page.dart';

class MameroomNotificationPage extends ConsumerWidget {
  const MameroomNotificationPage({
    super.key,
    this.actionResolver = const MameroomNotificationActionResolver(),
  });

  static const routePath = '/notifications';

  final MameroomNotificationActionResolver actionResolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mameroomNotificationControllerProvider);
    final controller = ref.read(
      mameroomNotificationControllerProvider.notifier,
    );
    final colors = context.mameroom;

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        elevation: 0,
        leading: IconButton(
          tooltip: '뒤로가기',
          icon: Icon(Icons.chevron_left_rounded, color: colors.ink),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          '알림',
          style: TextStyle(color: colors.ink, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: '알림 설정',
            onPressed: () =>
                context.push(MameroomNotificationSettingsPage.routePath),
            icon: Icon(Icons.settings_outlined, color: colors.ink),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  _CategoryTabs(
                    selected: state.selectedCategory,
                    onSelected: controller.selectCategory,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _NotificationBody(
                        key: ValueKey(
                          state.phase.toString() +
                              state.selectedCategory.toString() +
                              state.visibleNotifications.length.toString(),
                        ),
                        state: state,
                        onRetry: controller.retry,
                        onTap: (notification) async {
                          controller.markRead(notification.id);
                          await actionResolver.resolve(context, notification);
                        },
                      ),
                    ),
                  ),
                  if (!state.isLoading &&
                      !state.hasError &&
                      state.notifications.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: controller.markAllRead,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('모든 알림 읽기'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelected});

  final MameroomNotificationCategory selected;
  final ValueChanged<MameroomNotificationCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    const categories = [
      MameroomNotificationCategory.all,
      MameroomNotificationCategory.unread,
      MameroomNotificationCategory.seed,
      MameroomNotificationCategory.study,
      MameroomNotificationCategory.social,
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selected == category;
          return ChoiceChip(
            label: Text(category.label),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            visualDensity: VisualDensity.compact,
            selectedColor: colors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : colors.ink,
              fontWeight: FontWeight.w900,
            ),
            side: BorderSide(color: isSelected ? colors.primary : colors.line),
          );
        },
      ),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  const _NotificationBody({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onTap,
  });

  final MameroomNotificationState state;
  final VoidCallback onRetry;
  final ValueChanged<MameroomNotification> onTap;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const MameroomLoadingState(
        title: '\uC54C\uB9BC\uC744 \uBD88\uB7EC\uC624\uB294 \uC911',
        description:
            '\uC0C8\uB85C\uC6B4 \uC18C\uC2DD\uC744 \uC815\uB9AC\uD558\uACE0 \uC788\uC5B4\uC694.',
      );
    }
    if (state.hasError) {
      return MameroomErrorState.network(onRetry: onRetry);
    }
    final notifications = state.visibleNotifications;
    if (notifications.isEmpty) {
      return MameroomStateView(
        variant: MameroomStateVariant.empty,
        title: '새로운 알림이 없어요',
        description: '중요한 소식이 생기면 여기에 모아둘게요.',
        pixelIcon: MameroomStatePixelIcon.bell,
        size: MameroomStateSize.medium,
      );
    }
    return ListView.separated(
      key: const ValueKey('notification-list'),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => MameroomNotificationTile(
        notification: notifications[index],
        onTap: () => onTap(notifications[index]),
      ),
    );
  }
}
