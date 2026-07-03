import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/reward_feedback_overlay.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../domain/entities/quiz_result_snapshot.dart';
import '../providers/quiz_providers.dart';

class QuizResultPage extends ConsumerWidget {
  const QuizResultPage({this.snapshot, super.key});

  static const routePath = '/quiz/result';

  final QuizResultSnapshot? snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final session = state.asData?.value;
    final effectiveSnapshot = snapshot ??
        (session == null ? null : QuizResultSnapshot.fromSession(session));
    final summary = effectiveSnapshot?.summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Result')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: summary == null || effectiveSnapshot == null
              ? const Center(child: Text('No quiz result found.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Result', style: Theme.of(context).textTheme.headlineMedium),
                    if (effectiveSnapshot.rewardWarning != null) ...[
                      const SizedBox(height: 12),
                      _WarningBanner(message: effectiveSnapshot.rewardWarning!),
                    ],
                    const SizedBox(height: 24),
                    _ResultTile(
                      label: 'Correct answers',
                      value: '${summary.correctCount} / ${summary.totalCount}',
                    ),
                    _ResultTile(
                      label: 'Accuracy',
                      value: '${(summary.accuracy * 100).round()}%',
                    ),
                    _ResultTile(
                      label: 'Average response time',
                      value: '${(summary.averageResponseTimeMs / 1000).toStringAsFixed(1)}s',
                    ),
                    _ResultTile(
                      label: 'First attempt accuracy',
                      value: '${(summary.firstAttemptAccuracy * 100).round()}%',
                    ),
                    _ResultTile(
                      label: 'Retry success rate',
                      value: '${(summary.retrySuccessRate * 100).round()}%',
                    ),
                    _ResultTile(
                      label: 'Hints used',
                      value: '${summary.hintUsedCount}',
                    ),
                    _ResultTile(
                      label: 'Memory consolidation',
                      value: '${(summary.memoryConsolidationRate * 100).round()}%',
                    ),
                    const Divider(height: 32),
                    _ResultTile(
                      label: 'Average memory score',
                      value: '${(effectiveSnapshot.averageMemoryScore * 100).round()}%',
                    ),
                    _ResultTile(
                      label: 'Memory change',
                      value: _formatDelta(effectiveSnapshot.averageMemoryDelta),
                    ),
                    _ResultTile(
                      label: 'Next review',
                      value: _formatReviewTime(effectiveSnapshot.nextReviewAt),
                    ),
                    const Divider(height: 32),
                    _ResultTile(
                      label: 'Earned M-Coin',
                      value: '+${effectiveSnapshot.coinReward.earnedCoins}',
                      animated: true,
                    ),
                    _ResultTile(
                      label: 'Total M-Coin',
                      value: '${effectiveSnapshot.coinReward.balance}',
                      animated: true,
                    ),
                    _ResultTile(
                      label: 'Bonus M-Coin',
                      value: '+${effectiveSnapshot.coinReward.bonusCoins}',
                      animated: true,
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => context.go(LibraryPage.routePath),
                      child: const Text('Back to library'),
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
      return '-';
    }
    final local = value.toLocal();
    final date = '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
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
    required this.label,
    required this.value,
    this.animated = false,
  });

  final String label;
  final String value;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
