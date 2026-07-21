import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/states/mameroom_empty_state.dart';
import '../../../../core/presentation/states/mameroom_error_state.dart';
import '../../../../core/presentation/states/mameroom_loading_state.dart';
import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../../home/presentation/pages/home_shell_page.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/achievement_failure.dart';
import '../providers/achievement_providers.dart';

class AchievementPage extends ConsumerStatefulWidget {
  const AchievementPage({super.key});

  static const routePath = '/achievements';

  @override
  ConsumerState<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends ConsumerState<AchievementPage> {
  AchievementCategory? category;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(HomeShellPage.myInfoRoutePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(achievementOverviewProvider);
    final coin = ref.watch(coinWalletProvider).asData?.value.balance ?? 0;
    return Scaffold(
      body: SafeArea(
        child: MameroomShell(
          showSparkles: false,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _Header(coin: coin, onBack: _goBack),
              Expanded(
                child: overview.when(
                  loading: () => const MameroomLoadingState(
                    title: '업적을 불러오고 있어요',
                    description: '나의 학습 기록과 성장 과정을 확인하고 있어요.',
                  ),
                  error: (error, _) => _AchievementLoadError(
                    error: error,
                    onRetry: () => ref.invalidate(achievementOverviewProvider),
                    onBack: _goBack,
                    onMyPage: () => context.go(HomeShellPage.myInfoRoutePath),
                    onLogin: () => context.go(LoginPage.routePath),
                  ),
                  data: (data) {
                    if (data.achievements.isEmpty) {
                      return MameroomEmptyState(
                        title: '아직 기록된 업적이 없어요',
                        description: '공부를 시작하면 첫 번째 성장 기록이 만들어져요.',
                        primaryButtonText: '공부 시작하기',
                        onPrimaryPressed: () =>
                            context.go(HomeShellPage.studyRoutePath),
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final side = constraints.maxWidth < 360 ? 12.0 : 20.0;
                        final items = data.achievements
                            .where(
                              (item) =>
                                  category == null || item.category == category,
                            )
                            .toList();
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: CustomScrollView(
                              key: const ValueKey('achievement-list'),
                              slivers: [
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    side,
                                    12,
                                    side,
                                    0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: AchievementSummaryCard(
                                      summary: data.summary,
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: AchievementCategoryTabs(
                                    selected: category,
                                    onChanged: (value) =>
                                        setState(() => category = value),
                                  ),
                                ),
                                if (items.isEmpty)
                                  const SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: Text('이 카테고리의 업적은 아직 없어요.'),
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: EdgeInsets.fromLTRB(
                                      side,
                                      4,
                                      side,
                                      24,
                                    ),
                                    sliver: SliverList.separated(
                                      itemCount: items.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) => AchievementCard(
                                        key: ValueKey(
                                          'achievement-card-${items[index].code}',
                                        ),
                                        achievement: items[index],
                                        onTap: () => context.push(
                                          '${AchievementDetailPage.routePrefix}/${items[index].code}',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.coin, required this.onBack});
  final int coin;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: '뒤로',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      Expanded(
        child: Text(
          '업적',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      Semantics(
        label: 'M-Coin $coin개',
        child: Chip(
          avatar: const Icon(Icons.monetization_on_rounded, size: 18),
          label: Text('$coin'),
        ),
      ),
    ],
  );
}

class _AchievementLoadError extends StatelessWidget {
  const _AchievementLoadError({
    required this.error,
    required this.onRetry,
    required this.onBack,
    required this.onMyPage,
    required this.onLogin,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onMyPage;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final failure = error is AchievementFailure
        ? error as AchievementFailure
        : null;
    final unauthenticated =
        failure?.kind == AchievementFailureKind.authentication;
    return ListView(
      key: const ValueKey('achievement-load-error'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        MameroomErrorState(
          title: unauthenticated ? '로그인 정보를 확인할 수 없어요' : '업적을 불러오지 못했어요.',
          description: unauthenticated
              ? '정상 로그인 화면 또는 인증 복구 흐름으로 이동해 주세요.'
              : '잠시 후 다시 시도해 주세요.',
          primaryButtonText: unauthenticated ? '로그인하기' : '다시 시도',
          onPrimaryPressed: unauthenticated ? onLogin : onRetry,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('뒤로가기'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: onMyPage,
                child: const Text('My Page로 복귀'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AchievementSummaryCard extends StatelessWidget {
  const AchievementSummaryCard({super.key, required this.summary});
  final AchievementSummary summary;

  @override
  Widget build(BuildContext context) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _PixelIcon(icon: Icons.emoji_events_rounded, size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '나의 업적',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${summary.completed} / ${summary.total} 완료 · 배지 ${summary.badgeCount}개',
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: '전체 업적 달성률 ${(summary.progress * 100).round()}퍼센트',
                    child: LinearProgressIndicator(
                      value: summary.progress,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (summary.nextAchievement != null) ...[
          const SizedBox(height: 12),
          Text(
            '다음 목표 · ${summary.nextAchievement!.title}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),
  );
}

class AchievementCategoryTabs extends StatelessWidget {
  const AchievementCategoryTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final AchievementCategory? selected;
  final ValueChanged<AchievementCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = <AchievementCategory?>[null, ...AchievementCategory.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          for (final value in values) ...[
            ChoiceChip(
              key: ValueKey('achievement-category-${value?.name ?? 'all'}'),
              selected: selected == value,
              label: Text(_categoryLabel(value)),
              onSelected: (_) => onChanged(value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    required this.onTap,
  });
  final Achievement achievement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${achievement.title}, ${_statusLabel(achievement.status)}, '
        '${achievement.current}/${achievement.target}',
    child: _Surface(
      onTap: onTap,
      borderColor: achievement.status == AchievementStatus.rewardPending
          ? MameroomColors.warning
          : null,
      child: Row(
        children: [
          _PixelIcon(
            icon: achievement.status == AchievementStatus.locked
                ? Icons.lock_rounded
                : Icons.park_rounded,
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
                        achievement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    AchievementStateBadge(status: achievement.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 9),
                LinearProgressIndicator(
                  value: achievement.progress,
                  minHeight: 7,
                ),
                const SizedBox(height: 5),
                Text(
                  '${achievement.current} / ${achievement.target} · '
                  '${achievement.rewards.map((r) => r.label).join(' · ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class AchievementStateBadge extends StatelessWidget {
  const AchievementStateBadge({super.key, required this.status});
  final AchievementStatus status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _statusColor(status).withValues(alpha: .14),
      borderRadius: MameroomRadius.pillRadius,
    ),
    child: Text(
      _statusLabel(status),
      style: TextStyle(
        color: _statusColor(status),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class AchievementDetailPage extends ConsumerWidget {
  const AchievementDetailPage({super.key, required this.code});
  static const routePrefix = '/achievements';
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementDetailProvider(code));
    return Scaffold(
      appBar: AppBar(title: const Text('업적 상세')),
      body: SafeArea(
        child: state.when(
          loading: () => const AchievementSkeleton(),
          error: (_, _) => MameroomErrorState(
            title: '상세 정보를 불러오지 못했어요',
            description: '잠시 뒤 다시 시도해 주세요.',
            primaryButtonText: '다시 시도',
            onPrimaryPressed: () =>
                ref.invalidate(achievementDetailProvider(code)),
          ),
          data: (item) => LayoutBuilder(
            builder: (context, constraints) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: EdgeInsets.all(constraints.maxWidth < 360 ? 12 : 20),
                  children: [
                    const Center(
                      child: _PixelIcon(icon: Icons.park_rounded, size: 116),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(item.description, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    AchievementStateBadge(status: item.status),
                    const SizedBox(height: 16),
                    _Surface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '진행 ${item.current} / ${item.target}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 10,
                          ),
                          const SizedBox(height: 16),
                          _Info(
                            label: '카테고리',
                            value: _categoryLabel(item.category),
                          ),
                          _Info(label: '달성 조건', value: item.condition),
                          if (item.completedAt != null)
                            _Info(
                              label: '달성 날짜',
                              value: item.completedAt!
                                  .toLocal()
                                  .toString()
                                  .split(' ')
                                  .first,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AchievementRewardSection(rewards: item.rewards),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('achievement-confirm'),
                      onPressed: item.status == AchievementStatus.rewardPending
                          ? () async {
                              final updated = await ref
                                  .read(achievementRepositoryProvider)
                                  .refreshRewardState(item.code);
                              ref.invalidate(achievementOverviewProvider);
                              ref.invalidate(achievementDetailProvider(code));
                              if (context.mounted) {
                                await showDialog<void>(
                                  context: context,
                                  builder: (_) =>
                                      RewardPopup(achievement: updated),
                                );
                              }
                            }
                          : () => context.pop(),
                      child: Text(
                        item.status == AchievementStatus.rewardPending
                            ? '보상 확인'
                            : '완료',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AchievementRewardSection extends StatelessWidget {
  const AchievementRewardSection({super.key, required this.rewards});
  final List<AchievementReward> rewards;
  @override
  Widget build(BuildContext context) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('보상', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (rewards.isEmpty)
          const Text('별도 보상이 없는 업적이에요.')
        else
          for (final reward in rewards)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                reward.type == AchievementRewardType.mCoin
                    ? Icons.monetization_on_rounded
                    : Icons.workspace_premium_rounded,
              ),
              title: Text(reward.label),
              trailing: reward.amount == null
                  ? null
                  : Text('+${reward.amount}'),
            ),
      ],
    ),
  );
}

class RewardPopup extends StatelessWidget {
  const RewardPopup({super.key, required this.achievement});
  final Achievement achievement;
  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const _PixelIcon(icon: Icons.celebration_rounded, size: 72),
    title: const Text('업적 달성!', textAlign: TextAlign.center),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(achievement.title, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        for (final reward in achievement.rewards)
          Text(
            '${reward.label}${reward.amount == null ? '' : ' +${reward.amount}'}',
          ),
      ],
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('확인'),
      ),
    ],
  );
}

class AchievementSkeleton extends StatelessWidget {
  const AchievementSkeleton({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      for (var i = 0; i < 5; i++) ...[
        Container(
          height: i == 0 ? 130 : 112,
          decoration: BoxDecoration(
            color: MameroomColors.gray100,
            borderRadius: MameroomRadius.cardRadius,
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _PixelIcon extends StatelessWidget {
  const _PixelIcon({required this.icon, this.size = 54});
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: MameroomColors.primaryMist,
      border: Border.all(color: MameroomColors.primary, width: 2),
      borderRadius: MameroomRadius.mediumRadius,
      boxShadow: const [
        BoxShadow(color: Color(0x337861FF), offset: Offset(3, 3)),
      ],
    ),
    child: Icon(icon, color: MameroomColors.primary, size: size * .56),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.onTap, this.borderColor});
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: MameroomRadius.cardRadius,
      side: BorderSide(color: borderColor ?? MameroomColors.border),
    ),
    child: InkWell(
      borderRadius: MameroomRadius.cardRadius,
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

String _categoryLabel(AchievementCategory? value) => switch (value) {
  null => '전체',
  AchievementCategory.learning => '학습',
  AchievementCategory.review => '복습',
  AchievementCategory.memory => '기억',
  AchievementCategory.growth => '성장',
  AchievementCategory.friends => '친구',
  AchievementCategory.collection => '수집',
};

String _statusLabel(AchievementStatus value) => switch (value) {
  AchievementStatus.notStarted => '미달성',
  AchievementStatus.inProgress => '진행 중',
  AchievementStatus.eligible || AchievementStatus.completing => '달성 처리 중',
  AchievementStatus.completed => '달성 완료',
  AchievementStatus.rewardPending => '보상 확인',
  AchievementStatus.rewarded => '보상 완료',
  AchievementStatus.locked => '잠김',
  AchievementStatus.unavailable => '이용 불가',
  AchievementStatus.expired => '기간 만료',
};

Color _statusColor(AchievementStatus value) => switch (value) {
  AchievementStatus.completed ||
  AchievementStatus.rewarded => MameroomColors.success,
  AchievementStatus.rewardPending ||
  AchievementStatus.eligible => MameroomColors.warning,
  AchievementStatus.locked ||
  AchievementStatus.unavailable ||
  AchievementStatus.expired => MameroomColors.gray500,
  _ => MameroomColors.primary,
};
