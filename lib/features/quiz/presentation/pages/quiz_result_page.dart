import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../home/presentation/pages/home_shell_page.dart';
import '../../../memory_seed/domain/entities/memory_seed.dart';
import '../../../memory_seed/presentation/providers/memory_seed_providers.dart';
import '../../../study/presentation/widgets/study_flow_components.dart';
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
    final effectiveSnapshot =
        widget.snapshot ??
        (session == null ? null : QuizResultSnapshot.fromSession(session));
    final summary = effectiveSnapshot?.summary;

    if (summary != null && !_seedGrowthRequested) {
      _seedGrowthRequested = true;
      Future.microtask(() async {
        try {
          final result = await ref
              .read(memorySeedControllerProvider.notifier)
              .applyQuizResultGrowth(
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

    return MameroomShell(
      showSparkles: true,
      padding: EdgeInsets.zero,
      child: summary == null || effectiveSnapshot == null
          ? const Center(child: Text('학습 결과를 찾을 수 없어요.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 42,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        QuizResultSummaryCard(
                          correct: summary.correctCount,
                          incorrect: summary.totalCount - summary.correctCount,
                          passed: _passedCount(session),
                          accuracy: (summary.accuracy * 100).round(),
                          coin: effectiveSnapshot.coinReward.earnedCoins,
                          memoryBefore: _percent(
                            effectiveSnapshot.averageMemoryScore,
                          ),
                          memoryAfter: _percent(
                            effectiveSnapshot.averageMemoryScore +
                                effectiveSnapshot.averageMemoryDelta,
                          ),
                          seedGrowth: _percent(
                            effectiveSnapshot.averageMemoryDelta.abs(),
                          ),
                          onHome: () => context.go(HomeShellPage.homeRoutePath),
                        ),
                        if (effectiveSnapshot.rewardWarning != null) ...[
                          const SizedBox(height: 12),
                          _WarningBanner(
                            message: effectiveSnapshot.rewardWarning!,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _SeedResultCard(
                          progress: _seedGrowthResult?.seed.progress ?? 0.65,
                          completed: _seedGrowthResult?.completedNow ?? false,
                        ),
                        if (_seedGrowthError != null) ...[
                          const SizedBox(height: 12),
                          _WarningBanner(message: 'Seed 성장 기록은 잠시 보류되었어요.'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  int _percent(double value) {
    return (value.clamp(0.0, 1.0) * 100).round();
  }

  int _passedCount(QuizSessionState? session) {
    if (session == null) {
      return 0;
    }
    return session.passedInitialQuestionIds.length;
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SeedResultCard extends StatelessWidget {
  const _SeedResultCard({required this.progress, required this.completed});

  final double progress;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return StudyFlowCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PixelSeedHero(size: 104, mood: SeedMood.growth),
          const SizedBox(height: 10),
          Text(
            completed
                ? '\u0053eed\uAC00 \uC644\uC131\uB418\uC5C8\uC5B4\uC694!'
                : '\u0053eed\uAC00 \uC131\uC7A5\uD588\uC5B4\uC694!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 9,
              color: colors.primary,
              backgroundColor: colors.primaryMist.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress.clamp(0, 1) * 100).round()}%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
