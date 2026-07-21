import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../providers/notification_providers.dart';

class MameroomNotificationSettingsPage extends ConsumerWidget {
  const MameroomNotificationSettingsPage({super.key});

  static const routePath = '/notification-settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.mameroom;
    final state = ref.watch(mameroomNotificationControllerProvider);
    final settings = state.settings;
    final controller = ref.read(
      mameroomNotificationControllerProvider.notifier,
    );

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
        title: Text(
          '알림 설정',
          style: TextStyle(color: colors.ink, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _SettingsCard(
                  title: '기억씨앗 성장',
                  icon: Icons.eco_rounded,
                  value: settings.seedGrowth,
                  onChanged: controller.toggleSeedGrowth,
                ),
                _SettingsCard(
                  title: '복습 알림',
                  icon: Icons.menu_book_rounded,
                  value: settings.reviewReminder,
                  onChanged: controller.toggleReviewReminder,
                ),
                _SettingsCard(
                  title: '레벨업 / 업적',
                  icon: Icons.workspace_premium_rounded,
                  value: settings.levelUp,
                  onChanged: controller.toggleLevelUp,
                ),
                _SettingsCard(
                  title: '친구 활동',
                  icon: Icons.groups_rounded,
                  value: settings.friendActivity,
                  onChanged: controller.toggleFriendActivity,
                ),
                _SettingsCard(
                  title: '보상 알림',
                  icon: Icons.monetization_on_rounded,
                  value: settings.reward,
                  onChanged: controller.toggleReward,
                ),
                _SettingsCard(
                  title: '공지사항 / 이벤트',
                  icon: Icons.campaign_rounded,
                  value: settings.notice,
                  onChanged: controller.toggleNotice,
                ),
                const SizedBox(height: 12),
                _TimeCard(
                  settings: settings,
                  onWeekendChanged: controller.toggleWeekendMode,
                ),
                const SizedBox(height: 12),
                const _SoundPreviewCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.settings, required this.onWeekendChanged});

  final MameroomNotificationSettings settings;
  final ValueChanged<bool> onWeekendChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _PlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '알림 시간대',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TimePill(label: '시작', value: settings.quietStart),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TimePill(label: '종료', value: settings.quietEnd),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '주말 알림',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch(value: settings.weekendMode, onChanged: onWeekendChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoundPreviewCard extends StatelessWidget {
  const _SoundPreviewCard();

  @override
  Widget build(BuildContext context) {
    return _PlainCard(
      child: Column(
        children: const [
          _SoundRow(label: '성장 알림', icon: Icons.eco_rounded),
          _SoundRow(label: '복습 알림', icon: Icons.menu_book_rounded),
          _SoundRow(label: '보상 알림', icon: Icons.monetization_on_rounded),
        ],
      ),
    );
  }
}

class _SoundRow extends StatelessWidget {
  const _SoundRow({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < 9; i++)
                  Expanded(
                    child: Container(
                      height: i.isEven ? 8 : 18,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: colors.primaryPale,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: '미리듣기',
            icon: Icon(
              Icons.play_circle_outline_rounded,
              color: colors.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.cloud,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.muted, fontSize: 11)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(color: colors.ink, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
