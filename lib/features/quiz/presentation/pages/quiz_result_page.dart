import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/reward_feedback_overlay.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../memory_seed/domain/entities/memory_seed.dart';
import '../../../memory_seed/presentation/providers/memory_seed_providers.dart';
import '../../domain/entities/quiz_result_snapshot.dart';
import '../providers/quiz_providers.dart';

class QuizResultPage extends ConsumerStatefulWidget {
  const QuizResultPage({this.snapshot, super.key});

  static const routePath = '/quiz/result';

  final QuizResultSnapshot? snapshot;

  @override
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage> {
  bool _seedGrowthRequested = false;
  MemorySeedGrowthResult? _seedGrowthResult;
  Object? _seedGrowthError;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);
    final session = state.asData?.value;
    final effectiveSnapshot = widget.snapshot ??
        (session == null ? null : QuizResultSnapshot.fromSession(session));
    final summary = effectiveSnapshot?.summary;

    if (summary != null && !_seedGrowthRequested) {
      _seedGrowthRequested = true;
      Future.microtask(() async {
        try {
          final result = await ref.read(memorySeedControllerProvider.notifier).applyQuizResultGrowth(
                correctCount: summary.correctCount,
                totalCount: summary.totalCount,
                accuracy: summary.accuracy,
              );
          if (mounted) {
            setState(() => _seedGrowthResult = result);
          }
        } catch (error) {
          if (mounted) {
            setState(() => _seedGrowthError = error);
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('학습 결과')),
      body: SafeArea(
        child: summary == null || effectiveSnapshot == null
            ? const Center(child: Text('학습 결과를 찾을 수 없어요.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('오늘의 기억', style: Theme.of(context).textTheme.headlineMedium),
                    if (effectiveSnapshot.rewardWarning != null) ...[
                      const SizedBox(height: 12),
                      _WarningBanner(message: effectiveSnapshot.rewardWarning!),
                    ],
                    const SizedBox(height: 18),
                    _ResultTile(
                      icon: Icons.check_circle_outline,
                      label: '정답 수',
                      value: '${summary.correctCount} / ${summary.totalCount}',
                    ),
                    _ResultTile(
                      icon: Icons.percent_rounded,
                      label: '정확도',
                      value: '${(summary.accuracy * 100).round()}%',
                    ),
                    _ResultTile(
                      icon: Icons.spa_outlined,
                      label: '기억률 변화',
                      value: _formatDelta(effectiveSnapshot.averageMemoryDelta),
                    ),
                    _ResultTile(
                      icon: Icons.monetization_on_outlined,
                      label: '획득 코인',
                      value: '+${effectiveSnapshot.coinReward.earnedCoins}',
                      animated: true,
                    ),
                    _ResultTile(
                      icon: Icons.event_available_outlined,
                      label: '다음 복습',
                      value: _formatReviewTime(effectiveSnapshot.nextReviewAt),
                    ),
                    _ResultTile(
                      icon: Icons.local_florist_outlined,
                      label: 'Seed 성장',
                      value: _seedGrowthLabel(),
                    ),
                    if (_seedGrowthResult != null) ...[
                      const SizedBox(height: 8),
                      _SeedSummary(seedGrowth: _seedGrowthResult!),
                    ],
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () => context.go(LibraryPage.routePath),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('라이브러리로 돌아가기'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDelta(double value) {
    final percent = (value * 100).round();
    return percent >= 0 ? '+$percent%' : '$percent%';
  }

  String _formatReviewTime(DateTime? value) {
    if (value == null) {
      return '예정 없음';
    }
    final local = value.toLocal();
    final date = '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  String _seedGrowthLabel() {
    final error = _seedGrowthError;
    final result = _seedGrowthResult;
    if (error != null) {
      return '기록 보류';
    }
    if (result == null) {
      return '계산 중';
    }
    final suffix = result.completedNow ? ' · 완성' : ' · ${result.seed.stageLabel}';
    return '+${result.growthDelta}$suffix';
  }
}

class _SeedSummary extends StatelessWidget {
  const _SeedSummary({required this.seedGrowth});

  final MemorySeedGrowthResult seedGrowth;

  @override
  Widget build(BuildContext context) {
    final seed = seedGrowth.seed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(seed.seedTypeLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: seed.progress),
            const SizedBox(height: 8),
            Text(
              seedGrowth.completedNow
                  ? 'Seed가 완성되었어요. 추후 Arboretum으로 이동할 수 있어요.'
                  : '${seed.stageLabel} 단계 · ${seed.growthValue}/${seed.maxGrowthValue}',
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.icon,
    required this.label,
    required this.value,
    this.animated = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: animated
          ? RewardAnimatedValue(
              value: value,
              style: Theme.of(context).textTheme.titleMedium,
            )
          : Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
