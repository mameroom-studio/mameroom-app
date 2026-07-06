import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../../gamification/presentation/pages/shop_page.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../library/presentation/providers/library_mock_providers.dart';
import '../../../memory_seed/presentation/pages/arboretum_page.dart';
import '../../../review/presentation/pages/review_page.dart';
import '../../../streak/presentation/providers/streak_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(libraryDashboardProvider);
    final walletState = ref.watch(coinWalletProvider);
    final streakState = ref.watch(streakProvider);
    final roomState = ref.watch(myRoomControllerProvider);

    final wallet = walletState.asData?.value;
    final streak = streakState.asData?.value;
    final dashboard = dashboardState.asData?.value;

    final coinBalance = wallet?.balance ?? 0;
    final currentStreak = streak?.currentStreak ?? 0;
    final reviewCount = dashboard?.todayReviewCount ?? 0;
    final memoryPercent = dashboard?.totalMemoryPercent ?? 0;
    final roomItems = roomState.asData?.value.layouts.length ?? 0;
    final weeklyProgress = _weeklyProgress(memoryPercent, reviewCount);

    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(libraryDashboardProvider);
          ref.invalidate(coinWalletProvider);
          ref.invalidate(streakProvider);
          ref.invalidate(myRoomControllerProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _HomeTopBar(coinBalance: coinBalance),
            const SizedBox(height: 22),
            _ProfileSummary(currentStreak: currentStreak),
            const SizedBox(height: 22),
            _MemoryRoomPanel(
              placedItemCount: roomItems,
              onDecorate: () => context.push(ShopPage.routePath),
              onArboretum: () => context.push(ArboretumPage.routePath),
            ),
            const SizedBox(height: 18),
            _TodayStudyCard(
              reviewCount: reviewCount,
              memoryPercent: memoryPercent,
              onStartStudy: () => context.push(ReviewPage.routePath),
            ),
            const SizedBox(height: 16),
            _WeeklyGoalCard(progress: weeklyProgress),
          ],
        ),
      ),
    );
  }

  double _weeklyProgress(int memoryPercent, int reviewCount) {
    final memoryWeight = memoryPercent / 100;
    final reviewWeight = reviewCount == 0 ? 0.35 : 0.75;
    return ((memoryWeight * 0.55) + (reviewWeight * 0.45)).clamp(0.0, 1.0).toDouble();
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.coinBalance});

  final int coinBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        const PixelSeed(size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Text('MAMEROOM', style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 1.1)),
        ),
        _CurrencyPill(icon: Icons.monetization_on_rounded, label: _compactNumber(coinBalance), color: colors.sun),
        const SizedBox(width: 8),
        _CurrencyPill(icon: Icons.diamond_rounded, label: '0', color: colors.primary),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: colors.primaryMist.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: colors.line),
          ),
          child: const Center(child: PixelCharacter(size: 66)),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text('MAMEROOM user', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_rounded, size: 18, color: colors.muted),
                  const SizedBox(width: 10),
                  Chip(label: Text('Lv.1', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Streak $currentStreak days', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.ink)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemoryRoomPanel extends StatelessWidget {
  const _MemoryRoomPanel({
    required this.placedItemCount,
    required this.onDecorate,
    required this.onArboretum,
  });

  final int placedItemCount;
  final VoidCallback onDecorate;
  final VoidCallback onArboretum;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Current Memory Room', style: Theme.of(context).textTheme.titleLarge)),
            FilledButton.tonalIcon(
              onPressed: onDecorate,
              icon: const Icon(Icons.construction_rounded),
              label: const Text('Decorate'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 0.95,
          child: Container(
            decoration: BoxDecoration(
              color: colors.paper,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.08), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  top: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C597).withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                  ),
                ),
                const Positioned(left: 28, top: 42, child: Icon(Icons.window_rounded, size: 54)),
                const Positioned(right: 34, top: 70, child: Icon(Icons.menu_book_rounded, size: 58)),
                const Positioned(left: 44, bottom: 58, child: PixelSeed(size: 50)),
                const Positioned(right: 50, bottom: 54, child: Icon(Icons.desk_rounded, size: 70)),
                const Center(child: PixelCharacter(size: 88)),
                Positioned(
                  right: 18,
                  top: 18,
                  child: Chip(label: Text('Items $placedItemCount')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onArboretum,
          icon: const Icon(Icons.park_outlined),
          label: const Text('Arboretum'),
        ),
      ],
    );
  }
}

class _TodayStudyCard extends StatelessWidget {
  const _TodayStudyCard({
    required this.reviewCount,
    required this.memoryPercent,
    required this.onStartStudy,
  });

  final int reviewCount;
  final int memoryPercent;
  final VoidCallback onStartStudy;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Today Study', style: Theme.of(context).textTheme.titleLarge)),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined), label: const Text('Study plan')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StudyMetric(
                  icon: Icons.menu_book_rounded,
                  label: 'Reviews',
                  value: '$reviewCount',
                  suffix: ' items',
                ),
              ),
              Container(width: 1, height: 72, color: colors.line),
              Expanded(
                child: _StudyMetric(
                  icon: Icons.spa_rounded,
                  label: 'Memory',
                  value: '$memoryPercent',
                  suffix: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStartStudy,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('???살쓱? ??筌믨퀣援????꾨탿'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final percent = (progress * 100).round();
    return _SoftCard(
      child: Row(
        children: [
          Icon(Icons.track_changes_rounded, size: 42, color: colors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly goal', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$percent% complete', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.primary)),
              ],
            ),
          ),
          SizedBox(
            width: 128,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: colors.primaryMist,
            ),
          ),
          const SizedBox(width: 8),
          Text('$percent%'),
        ],
      ),
    );
  }
}

class _StudyMetric extends StatelessWidget {
  const _StudyMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
  });

  final IconData icon;
  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      children: [
        Icon(icon, color: colors.primary, size: 34),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: colors.ink),
            children: [
              TextSpan(text: value),
              TextSpan(text: suffix, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

String _compactNumber(int value) {
  if (value < 1000) return '$value';
  final thousands = value / 1000;
  return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
}

