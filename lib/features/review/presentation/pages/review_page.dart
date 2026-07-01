import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../library/presentation/pages/library_page.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../domain/entities/review_schedule.dart';
import '../providers/review_providers.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  static const routePath = '/review';

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  final _textController = TextEditingController();
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewControllerProvider.notifier).loadTodayReviews();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Today')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ReviewError(message: error.toString()),
            data: (session) => _buildSession(context, session),
          ),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context, ReviewSessionState session) {
    if (session.items.isEmpty) {
      return _EmptyReview(onBack: () => context.go(LibraryPage.routePath));
    }

    if (_isFinished) {
      return _ReviewComplete(
        session: session,
        onBack: () => context.go(LibraryPage.routePath),
      );
    }

    final item = session.currentItem;
    if (item == null) {
      return _EmptyReview(onBack: () => context.go(LibraryPage.routePath));
    }

    final question = item.question;
    if (question.type == QuizQuestionType.fillBlank &&
        _textController.text != session.selectedAnswer) {
      _textController.text = session.selectedAnswer;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today ${session.dueCount}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Memory ${(item.memoryScore * 100).round()}%',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Review ${session.currentIndex + 1} / ${session.items.length}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (session.currentIndex + 1) / session.items.length,
        ),
        const SizedBox(height: 24),
        Text(question.questionText, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        _AnswerInput(
          question: question,
          selectedAnswer: session.selectedAnswer,
          enabled: !session.isAnswerChecked && !session.isSaving,
          textController: _textController,
          onChanged: ref.read(reviewControllerProvider.notifier).selectAnswer,
        ),
        const SizedBox(height: 20),
        if (session.isAnswerChecked && session.currentAnswer != null)
          _AnswerReview(answer: session.currentAnswer!),
        const Spacer(),
        FilledButton(
          onPressed: _buttonEnabled(session)
              ? () async {
                  if (!session.isAnswerChecked) {
                    await ref.read(reviewControllerProvider.notifier).checkAnswer();
                    return;
                  }
                  if (session.isLastQuestion) {
                    await ref.read(reviewControllerProvider.notifier).awardCompletionRewards();
                    if (mounted) {
                      setState(() => _isFinished = true);
                    }
                  } else {
                    _textController.clear();
                    ref.read(reviewControllerProvider.notifier).goNext();
                  }
                }
              : null,
          child: Text(_buttonText(session)),
        ),
      ],
    );
  }

  bool _buttonEnabled(ReviewSessionState session) {
    return !session.isRewarding &&
        (session.isAnswerChecked ||
            (!session.isSaving && session.selectedAnswer.trim().isNotEmpty));
  }

  String _buttonText(ReviewSessionState session) {
    if (!session.isAnswerChecked) {
      return session.isSaving ? 'Saving...' : 'Check answer';
    }
    if (session.isLastQuestion) {
      return session.isRewarding ? 'Saving rewards...' : 'Finish review';
    }
    return 'Next review';
  }
}

class _AnswerInput extends StatelessWidget {
  const _AnswerInput({
    required this.question,
    required this.selectedAnswer,
    required this.enabled,
    required this.textController,
    required this.onChanged,
  });

  final Question question;
  final String selectedAnswer;
  final bool enabled;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (question.type) {
      QuizQuestionType.multipleChoice => RadioGroup<String>(
          groupValue: selectedAnswer.isEmpty ? null : selectedAnswer,
          onChanged: (value) {
            if (enabled) {
              onChanged(value ?? '');
            }
          },
          child: Column(
            children: question.options.map((option) {
              return RadioListTile<String>(
                value: option,
                enabled: enabled,
                selected: option == selectedAnswer,
                title: Text(option),
              );
            }).toList(growable: false),
          ),
        ),
      QuizQuestionType.ox => SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'O', label: Text('O')),
            ButtonSegment(value: 'X', label: Text('X')),
          ],
          selected: selectedAnswer.isEmpty ? const <String>{} : {selectedAnswer},
          emptySelectionAllowed: true,
          onSelectionChanged: enabled
              ? (values) => onChanged(values.isEmpty ? '' : values.first)
              : null,
        ),
      QuizQuestionType.fillBlank => TextField(
          controller: textController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Answer',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
    };
  }
}

class _AnswerReview extends StatelessWidget {
  const _AnswerReview({required this.answer});

  final ReviewAnswerResult answer;

  @override
  Widget build(BuildContext context) {
    final color = answer.isCorrect
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.errorContainer;
    final onColor = answer.isCorrect
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onErrorContainer;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              answer.isCorrect ? 'Correct' : 'Incorrect',
              style: TextStyle(color: onColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Answer: ${answer.item.question.answer}', style: TextStyle(color: onColor)),
            const SizedBox(height: 8),
            Text(answer.item.question.explanation, style: TextStyle(color: onColor)),
            const SizedBox(height: 8),
            Text('Evidence: ${answer.item.question.evidence}', style: TextStyle(color: onColor)),
          ],
        ),
      ),
    );
  }
}

class _ReviewComplete extends StatelessWidget {
  const _ReviewComplete({required this.session, required this.onBack});

  final ReviewSessionState session;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final summary = session.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Review complete', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _ResultRow(label: 'Completed', value: '${summary.totalCount}'),
        _ResultRow(label: 'Correct', value: '${summary.correctCount} / ${summary.totalCount}'),
        _ResultRow(label: 'Accuracy', value: '${(summary.accuracy * 100).round()}%'),
        _ResultRow(label: 'Next review', value: _formatReviewTime(session.nextReviewAt)),
        const Divider(height: 32),
        _ResultRow(label: 'Earned M-Coin', value: '+${session.coinReward.earnedCoins}'),
        _ResultRow(label: 'Total M-Coin', value: '${session.coinReward.balance}'),
        _ResultRow(label: 'Bonus M-Coin', value: '+${session.coinReward.bonusCoins}'),
        const Spacer(),
        FilledButton(onPressed: onBack, child: const Text('Back to library')),
      ],
    );
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

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

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available, size: 44),
          const SizedBox(height: 12),
          Text('No reviews due today', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton(onPressed: onBack, child: const Text('Back to library')),
        ],
      ),
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}