import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/reward_feedback_overlay.dart';
import '../../../coins/domain/policies/economy_policy.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../domain/entities/question.dart';
import '../providers/quiz_providers.dart';
import 'quiz_result_page.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({required this.materialId, super.key});

  static const routePath = '/quiz';

  final String? materialId;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  final _textController = TextEditingController();
  List<String> _rewardMessages = const [];
  int _rewardTrigger = 0;

  @override
  void initState() {
    super.initState();
    final materialId = widget.materialId;
    if (materialId != null && materialId.isNotEmpty) {
      Future.microtask(() {
        ref.read(quizControllerProvider.notifier).load(materialId: materialId);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: widget.materialId == null || widget.materialId!.isEmpty
              ? _MissingMaterialId(onBack: () => context.go(LibraryPage.routePath))
              : state.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _QuizError(message: error.toString()),
                  data: (session) => _buildSession(context, session),
                ),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context, QuizSessionState session) {
    final question = session.currentQuestion;
    if (question == null) {
      return const Center(child: Text('No quiz questions found.'));
    }

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
        Text(
          'Question ${session.currentIndex + 1} / ${session.questions.length}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (session.currentIndex + 1) / session.questions.length,
        ),
        const SizedBox(height: 24),
        Text(question.questionText, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        _AnswerInput(
          question: question,
          selectedAnswer: session.selectedAnswer,
          enabled: !session.isAnswerChecked && !session.isSaving,
          textController: _textController,
          onChanged: ref.read(quizControllerProvider.notifier).selectAnswer,
        ),
        const SizedBox(height: 20),
        if (session.isAnswerChecked && session.currentAnswer != null)
          _AnswerReview(answer: session.currentAnswer!),
        const Spacer(),
        if (session.isAnswerChecked)
          _FeedbackRow(
            onFeedback: (type) {
              ref.read(quizControllerProvider.notifier).saveFeedback(type);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback saved.')),
              );
            },
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _buttonEnabled(session)
              ? () async {
                  if (!session.isAnswerChecked) {
                    await ref.read(quizControllerProvider.notifier).checkAnswer();
                    final updated = ref.read(quizControllerProvider).asData?.value;
                    if (mounted && updated != null) {
                      _showRewardFeedback(_quizRewardMessages(updated));
                    }
                    return;
                  }
                  if (session.isLastQuestion) {
                    await ref.read(quizControllerProvider.notifier).awardCompletionRewards();
                    if (context.mounted) {
                      context.go(QuizResultPage.routePath);
                    }
                  } else {
                    _textController.clear();
                    ref.read(quizControllerProvider.notifier).goNext();
                  }
                }
              : null,
          child: Text(_buttonText(session)),
        ),
        ],
      ),
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

  List<String> _quizRewardMessages(QuizSessionState session) {
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

  bool _hasFiveCorrectStreak(List<QuizAnswerResult> answers) {
    if (answers.length < 5) {
      return false;
    }
    return answers.reversed.take(5).every((answer) => answer.isCorrect);
  }

  bool _buttonEnabled(QuizSessionState session) {
    return !session.isRewarding &&
        (session.isAnswerChecked ||
            (!session.isSaving && session.selectedAnswer.trim().isNotEmpty));
  }

  String _buttonText(QuizSessionState session) {
    if (!session.isAnswerChecked) {
      return session.isSaving ? 'Saving...' : 'Check answer';
    }
    if (session.isLastQuestion) {
      return session.isRewarding ? 'Saving rewards...' : 'View result';
    }
    return 'Next question';
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

  final QuizAnswerResult answer;

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
            Text('Answer: ${answer.question.answer}', style: TextStyle(color: onColor)),
            const SizedBox(height: 8),
            Text(answer.question.explanation, style: TextStyle(color: onColor)),
            const SizedBox(height: 8),
            Text('Evidence: ${answer.question.evidence}', style: TextStyle(color: onColor)),
          ],
        ),
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.onFeedback});

  final ValueChanged<String> onFeedback;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => onFeedback('like'), child: const Text('Like'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: () => onFeedback('hard'), child: const Text('Hard'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: () => onFeedback('inaccurate'), child: const Text('Inaccurate'))),
      ],
    );
  }
}

class _MissingMaterialId extends StatelessWidget {
  const _MissingMaterialId({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onBack, child: const Text('Back to library')),
    );
  }
}

class _QuizError extends StatelessWidget {
  const _QuizError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}