import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../coins/domain/policies/economy_policy.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../../quiz/domain/entities/quiz_result_snapshot.dart';
import '../../../quiz/presentation/pages/quiz_result_page.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';
import '../widgets/study_flow_components.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({
    required this.materialId,
    this.unlearnedOnly = false,
    super.key,
  });

  final String? materialId;
  final bool unlearnedOnly;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  final _textController = TextEditingController();
  bool _bookmarked = false;
  bool _showPassFeedback = false;
  bool _showSeedCelebration = false;
  bool _passNoticeShown = false;
  QuizSessionState? _terminalPassSession;

  @override
  void initState() {
    super.initState();
    final materialId = widget.materialId;
    if (materialId != null && materialId.isNotEmpty) {
      Future.microtask(
        () => ref
            .read(quizControllerProvider.notifier)
            .load(materialId: materialId, unlearnedOnly: widget.unlearnedOnly),
      );
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: MameroomShell(
        showSparkles: false,
        padding: EdgeInsets.zero,
        child: widget.materialId == null || widget.materialId!.isEmpty
            ? _MissingMaterialId(
                onBack: () => context.go(LibraryPage.routePath),
              )
            : state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _StudyError(message: error.toString()),
                data: _buildSession,
              ),
      ),
    );
  }

  Widget _buildSession(QuizSessionState session) {
    final question = session.currentQuestion;
    if (question == null) {
      return _MissingMaterialId(
        onBack: () => context.go(LibraryPage.routePath),
      );
    }

    if (_usesTextInput(question) &&
        _textController.text != session.selectedAnswer) {
      _textController.text = session.selectedAnswer;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    final total = session.initialQuestionCount == 0
        ? session.questions.length
        : session.initialQuestionCount;
    final answeredInitial = session.answers
        .where((answer) => !answer.isRetry)
        .length;
    final current = (answeredInitial + 1).clamp(1, total == 0 ? 1 : total);

    return Column(
      children: [
        QuizProgressHeader(
          current: current,
          total: total == 0 ? 1 : total,
          coinBalance: session.coinReward.balance,
          bookmarked: _bookmarked,
          onExit: _confirmExit,
        ),
        Expanded(child: _buildBody(session, question)),
      ],
    );
  }

  Widget _buildBody(QuizSessionState session, Question question) {
    final answer = session.currentAnswer;

    if (_showSeedCelebration) {
      return MemoryGrowthPanel(
        beforeLevel: 2,
        afterLevel: 3,
        progress: _memoryValue(session),
        onConfirm: () {
          setState(() => _showSeedCelebration = false);
          _advance(session);
        },
      );
    }

    if (_showPassFeedback) {
      return FeedbackResultCard(
        kind: FeedbackKind.pass,
        answer: question.answer,
        message: '이 문제는 PASS했어요. 나중에 다시 복습할 수 있습니다.',
        rewardText: '',
        isLast: _terminalPassSession != null,
        onNext: () {
          final terminal = _terminalPassSession;
          setState(() {
            _showPassFeedback = false;
            _terminalPassSession = null;
          });
          if (terminal != null) _advance(terminal);
        },
      );
    }

    if (session.isAnswerChecked && answer != null) {
      return FeedbackResultCard(
        kind: answer.isCorrect ? FeedbackKind.correct : FeedbackKind.incorrect,
        answer: answer.question.answer,
        selectedAnswer: answer.selectedAnswer,
        message: answer.isCorrect
            ? '잘했어요. 핵심 개념을 정확히 기억하고 있어요.'
            : '괜찮아요. 정답과 해설을 확인하고 다음 문제에서 다시 연결해볼게요.',
        explanation: _explanation(answer.question),
        source: _source(answer.question),
        rewardText: answer.isCorrect
            ? '+${EconomyPolicy.correctAnswerCoins} M-Coin'
            : '+2 M-Coin',
        isLast: session.isSessionTerminal,
        onNext: () => _advance(session),
      );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 620;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuestionCard(
                        questionText: question.questionText,
                        categoryLabel: _categoryLabel(question),
                        difficultyLabel: _difficultyLabel(question.difficulty),
                        questionTypeLabel: _questionTypeLabel(question.type),
                        sourceLabel: _source(question),
                        child: question.evidence.trim().isEmpty
                            ? const SizedBox.shrink()
                            : PixelQuizIllustration(compact: compact),
                      ),
                      const SizedBox(height: 14),
                      _AnswerArea(
                        question: question,
                        selectedAnswer: session.selectedAnswer,
                        textController: _textController,
                        enabled: !session.isSaving,
                        onChanged: ref
                            .read(quizControllerProvider.notifier)
                            .selectAnswer,
                        onSubmit: () {
                          if (session.selectedAnswer.trim().isEmpty) {
                            _showEmptyAnswerMessage();
                            return;
                          }
                          ref
                              .read(quizControllerProvider.notifier)
                              .checkAnswer();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        BottomQuizActionBar(
          canSubmit: session.selectedAnswer.trim().isNotEmpty,
          isSaving: session.isSaving,
          bookmarked: _bookmarked,
          canUseHint: session.canUseHint,
          onHint: ref.read(quizControllerProvider.notifier).useHint,
          onPass: _passCurrentQuestion,
          onBookmark: _saveBookmark,
          onSubmit: () {
            if (session.selectedAnswer.trim().isEmpty) {
              _showEmptyAnswerMessage();
              return;
            }
            ref.read(quizControllerProvider.notifier).checkAnswer();
          },
        ),
      ],
    );
  }

  Future<void> _advance(QuizSessionState session) async {
    if (session.isSessionTerminal) {
      final rewardWarning = await ref
          .read(quizControllerProvider.notifier)
          .awardCompletionRewards();
      final resultSession =
          ref.read(quizControllerProvider).asData?.value ?? session;
      final snapshot = QuizResultSnapshot.fromSession(
        resultSession,
        rewardWarning: rewardWarning,
      );
      if (mounted) context.go(QuizResultPage.routePath, extra: snapshot);
      return;
    }
    _textController.clear();
    setState(() => _bookmarked = false);
    ref.read(quizControllerProvider.notifier).goNext();
  }

  Future<void> _passCurrentQuestion() async {
    final before = ref.read(quizControllerProvider).asData?.value;
    if (before == null || before.isAnswerChecked || before.isSaving) return;
    await ref
        .read(quizControllerProvider.notifier)
        .passCurrentQuestion(
          passType: LearningPassType.question,
          reason: LearningPassReason.reviewLater,
        );
    if (!mounted) return;
    final updated = ref.read(quizControllerProvider).asData?.value;
    _textController.clear();
    setState(() {
      _bookmarked = false;
      _showPassFeedback = true;
      _terminalPassSession = updated != null && updated.isSessionTerminal
          ? updated
          : null;
    });
    if (!_passNoticeShown) {
      _passNoticeShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이 문제는 PASS했어요. 나중에 다시 복습할 수 있습니다.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1200),
        ),
      );
    }
  }

  Future<void> _saveBookmark() async {
    setState(() => _bookmarked = !_bookmarked);
    if (_bookmarked) {
      ScaffoldMessenger.of(context).showSnackBar(BookmarkSavedSnack());
    }
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ExitQuizDialog(
        onSaveAndExit: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (shouldExit == true && mounted) {
      context.go(LibraryPage.routePath);
    }
  }

  void _showEmptyAnswerMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('정답을 입력해주세요.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _usesTextInput(Question question) =>
      question.type == QuizQuestionType.shortAnswer ||
      question.type == QuizQuestionType.fillBlank;

  double _memoryValue(QuizSessionState session) {
    if (session.memoryUpdates.isNotEmpty) {
      return session.memoryUpdates.last.memoryScore.clamp(0, 1);
    }
    return session.averageMemoryScore > 0
        ? session.averageMemoryScore.clamp(0, 1)
        : 0.65;
  }

  String _questionTypeLabel(QuizQuestionType type) {
    return switch (type) {
      QuizQuestionType.multipleChoice => '객관식',
      QuizQuestionType.shortAnswer => '주관식',
      QuizQuestionType.fillBlank => '빈칸',
    };
  }

  String _categoryLabel(Question question) {
    final text = question.sectionId?.trim();
    if (text != null && text.isNotEmpty) {
      return text.length > 8 ? text.substring(0, 8) : text;
    }
    return '학습';
  }

  String _difficultyLabel(int difficulty) {
    if (difficulty <= 1) {
      return '쉬움';
    }
    if (difficulty >= 4) {
      return '어려움';
    }
    return '보통';
  }

  String _explanation(Question question) {
    if (question.explanation.trim().isNotEmpty) return question.explanation;
    if (question.evidence.trim().isNotEmpty) return question.evidence;
    return '해설이 준비되지 않았습니다.';
  }

  String? _source(Question question) {
    final source = <String>[];
    if (question.evidence.trim().isNotEmpty) {
      source.add(question.evidence.trim());
    }
    if (question.sectionId?.trim().isNotEmpty ?? false) {
      source.add(question.sectionId!.trim());
    }
    return source.isEmpty ? null : source.join(' · ');
  }
}

class _AnswerArea extends StatelessWidget {
  const _AnswerArea({
    required this.question,
    required this.selectedAnswer,
    required this.textController,
    required this.enabled,
    required this.onChanged,
    required this.onSubmit,
  });

  final Question question;
  final String selectedAnswer;
  final TextEditingController textController;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (question.type == QuizQuestionType.multipleChoice) {
      return Column(
        children: [
          for (var index = 0; index < question.options.length; index++) ...[
            AnswerOptionCard(
              index: index + 1,
              label: question.options[index],
              selected: selectedAnswer == question.options[index],
              enabled: enabled,
              onTap: () => onChanged(question.options[index]),
            ),
            if (index != question.options.length - 1) const SizedBox(height: 9),
          ],
        ],
      );
    }
    return ShortAnswerField(
      controller: textController,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmit(),
    );
  }
}

class _MissingMaterialId extends StatelessWidget {
  const _MissingMaterialId({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StudyFlowCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelSeedHero(size: 96),
              const SizedBox(height: 14),
              Text(
                '학습 자료를 찾을 수 없어요',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onBack, child: const Text('공부 탭으로 돌아가기')),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyError extends StatelessWidget {
  const _StudyError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StudyFlowCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 46,
              ),
              const SizedBox(height: 12),
              Text(
                '학습 화면을 불러오지 못했어요',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
