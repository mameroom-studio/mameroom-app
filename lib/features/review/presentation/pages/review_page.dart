import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/reward_feedback_overlay.dart';
import '../../../coins/domain/policies/economy_policy.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../streak/presentation/providers/streak_providers.dart';
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
  List<String> _rewardMessages = const [];
  int _rewardTrigger = 0;

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
      return RewardFeedbackOverlay(
        messages: _rewardMessages,
        trigger: _rewardTrigger,
        child: _ReviewComplete(
          session: session,
          onBack: () => context.go(LibraryPage.routePath),
        ),
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

    return RewardFeedbackOverlay(
      messages: _rewardMessages,
      trigger: _rewardTrigger,
      child: Column(
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
        if (!session.isAnswerChecked) ...[
          const SizedBox(height: 12),
          _PassActions(
            enabled: !session.isSaving,
            onPassQuestion: () => _passCurrentReview(LearningPassType.question),
            onPassConcept: () => _passCurrentReview(LearningPassType.concept),
          ),
        ],
        const Spacer(),
        FilledButton(
          onPressed: _buttonEnabled(session)
              ? () async {
                  if (!session.isAnswerChecked) {
                    await ref.read(reviewControllerProvider.notifier).checkAnswer();
                    final updated = ref.read(reviewControllerProvider).asData?.value;
                    if (mounted && updated != null) {
                      _showRewardFeedback(_reviewRewardMessages(updated));
                    }
                    return;
                  }
                  if (session.isLastQuestion) {
                    await ref.read(reviewControllerProvider.notifier).awardCompletionRewards();
                    final streak = await ref.refresh(streakProvider.future);
                    if (mounted) {
                      setState(() => _isFinished = true);
                      _showRewardFeedback([
                        '+${EconomyPolicy.reviewCompletionCoins} M-Coin',
                        if (streak.currentStreak > 0) '?? ${streak.currentStreak}? ?? ??',
                      ]);
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
      ),
    );
  }

  Future<void> _passCurrentReview(LearningPassType passType) async {
    final reason = await showDialog<LearningPassReason>(
      context: context,
      builder: (context) => const _PassReasonDialog(),
    );
    if (reason == null || !mounted) {
      return;
    }

    await ref.read(reviewControllerProvider.notifier).passCurrentItem(
          passType: passType,
          reason: reason,
        );
    if (!mounted) {
      return;
    }
    _textController.clear();
    final label = passType == LearningPassType.question ? 'Question' : 'Concept';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label passed.')),
    );
  }
  void _showRewardFeedback(List<String> messages) {
    if (messages.isEmpty) {
      return;
    }
    setState(() {
      _rewardMessages = messages;
      _rewardTrigger += 1;
    });
  }

  List<String> _reviewRewardMessages(ReviewSessionState session) {
    final answer = session.currentAnswer;
    final messages = <String>[];
    if (answer?.isCorrect == true) {
      messages.add('+${EconomyPolicy.correctAnswerCoins} M-Coin');
      if (_hasFiveCorrectStreak(session.answers)) {
        messages.add('?? 5 Combo!');
      }
    }

    if (session.memoryUpdates.isNotEmpty) {
      final delta = session.memoryUpdates.last.delta;
      final percent = (delta * 100).round();
      if (percent > 0) {
        messages.add('+$percent% Memory');
      }
    }
    return messages;
  }

  bool _hasFiveCorrectStreak(List<ReviewAnswerResult> answers) {
    if (answers.length < 5) {
      return false;
    }
    return answers.reversed.take(5).every((answer) => answer.isCorrect);
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

class _PassActions extends StatelessWidget {
  const _PassActions({
    required this.enabled,
    required this.onPassQuestion,
    required this.onPassConcept,
  });

  final bool enabled;
  final VoidCallback onPassQuestion;
  final VoidCallback onPassConcept;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onPassQuestion : null,
            icon: const Icon(Icons.skip_next_outlined),
            label: const Text('Pass question'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onPassConcept : null,
            icon: const Icon(Icons.block_outlined),
            label: const Text('Pass concept'),
          ),
        ),
      ],
    );
  }
}

class _PassReasonDialog extends StatelessWidget {
  const _PassReasonDialog();

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Pass reason'),
      children: LearningPassReason.values.map((reason) {
        return SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(reason),
          child: Text(reason.label),
        );
      }).toList(growable: false),
    );
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
      QuizQuestionType.shortAnswer => TextField(
          controller: textController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Answer',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
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
        _ResultRow(label: 'Earned M-Coin', value: '+${session.coinReward.earnedCoins}', animated: true),
        _ResultRow(label: 'Total M-Coin', value: '${session.coinReward.balance}', animated: true),
        _ResultRow(label: 'Bonus M-Coin', value: '+${session.coinReward.bonusCoins}', animated: true),
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
  const _ResultRow({
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