import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../library/presentation/pages/library_page.dart';
import '../providers/quiz_providers.dart';

class QuizResultPage extends ConsumerWidget {
  const QuizResultPage({super.key});

  static const routePath = '/quiz/result';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final session = state.asData?.value;
    final summary = session?.summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Result')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: summary == null || session == null
              ? const Center(child: Text('No quiz result found.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Result', style: Theme.of(context).textTheme.headlineMedium),
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
                    const Divider(height: 32),
                    _ResultTile(
                      label: 'Average memory score',
                      value: '${(session.averageMemoryScore * 100).round()}%',
                    ),
                    _ResultTile(
                      label: 'Memory change',
                      value: _formatDelta(session.averageMemoryDelta),
                    ),
                    _ResultTile(
                      label: 'Next review',
                      value: _formatReviewTime(session.nextReviewAt),
                    ),
                    const Divider(height: 32),
                    _ResultTile(
                      label: 'Earned M-Coin',
                      value: '+${session.coinReward.earnedCoins}',
                    ),
                    _ResultTile(
                      label: 'Total M-Coin',
                      value: '${session.coinReward.balance}',
                    ),
                    _ResultTile(
                      label: 'Bonus M-Coin',
                      value: '+${session.coinReward.bonusCoins}',
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

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}