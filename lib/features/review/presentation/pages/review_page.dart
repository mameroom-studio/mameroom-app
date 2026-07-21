import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../../quiz/presentation/widgets/quiz_session_shell.dart';
import '../../domain/entities/review_schedule.dart';
import '../../data/fixtures/mock_review_fixture.dart';
import '../providers/review_providers.dart';

String _k(List<int> c) => String.fromCharCodes(c);

const _useMockReviewEnv = bool.fromEnvironment('USE_MOCK_REVIEW');

final _todayReview = _k([50724, 45720, 51032, 32, 48373, 49845]);
final _startReview = _k([48373, 49845, 32, 49884, 51089, 54616, 44592]);
final _reviewDone = _k([48373, 49845, 32, 50756, 47308]);
final _emptyDone = _k([
  50724,
  45720,
  32,
  48373,
  49845,
  51008,
  32,
  45149,
  45228,
  50612,
  50836,
  33,
]);
final _correct = _k([51221, 45813]);
final _wrong = _k([50724, 45813]);
final _memoryRate = _k([44592, 50613, 47456]);
final _nextQuestion = _k([45796, 51020, 32, 47928, 51228]);
final _bookmark = _k([48513, 47560, 53356]);
final _submit = _k([51228, 52636, 54616, 44592]);
final _hint = _k([55180, 53944]);
final _exitTitle = _k([
  48373,
  49845,
  51012,
  32,
  51333,
  47308,
  54624,
  44620,
  50836,
  63,
]);
final _keepReview = _k([44228, 49549, 32, 48373, 49845]);
final _saveExit = _k([51200, 51109, 54616, 44256, 32, 51333, 47308]);
final _home = _k([54856, 51004, 47196, 32, 44032, 44592]);
final _wrongNote = _k([50724, 45813, 45432, 53944, 32, 48372, 44592]);
final _memoryRecovered = _k([
  44592,
  50613,
  51060,
  32,
  54924,
  48373,
  46104,
  50632,
  50836,
  33,
]);
final _tryAgain = _k([
  51312,
  44552,
  32,
  45908,
  32,
  48373,
  49845,
  54644,
  48400,
  50836,
  33,
]);
final _selectedAnswer = _k([45236, 32, 45813]);
final _correctAnswer = _k([51221, 45813]);
final _explanation = _k([54644, 49444]);
final _nextReview = _k([45796, 51020, 32, 48373, 49845]);
final _due = _k([48373, 49845, 32, 50696, 51221]);
final _expectedTime = _k([50696, 49345, 32, 49884, 44036]);
final _weakest = _k([44032, 51109, 32, 50557, 54620, 32, 51088, 47308]);
final _startFirst = _k([
  52395,
  32,
  48373,
  49845,
  51012,
  32,
  49884,
  51089,
  54616,
  47732,
  32,
  44592,
  47197,
  51060,
  32,
  54924,
  48373,
  46121,
  45768,
  45796,
  46,
]);
final _exitBody = _k([
  54788,
  51116,
  32,
  51652,
  54665,
  51012,
  32,
  51200,
  51109,
  54616,
  44256,
  32,
  48373,
  49845,
  51012,
  32,
  51333,
  47308,
  54633,
  44620,
  50836,
  63,
]);

enum _Stage { home, answering, complete }

final _reviewModeConfig = QuizModeConfig(
  title: _todayReview,
  badgeLabel: 'Review',
  exitDialogTitle: _exitTitle,
  exitDialogDescription: _exitBody,
  resultTitle: _reviewDone,
  showReviewMetadata: true,
  showNextReviewDate: true,
);

String _modeQuestionTypeLabel(QuizQuestionType type) => switch (type) {
  QuizQuestionType.multipleChoice => 'Choice',
  QuizQuestionType.shortAnswer => 'Short',
  QuizQuestionType.fillBlank => 'Blank',
};

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({
    super.key,
    this.useMockReview = false,
    this.mockEmpty = false,
  });

  static const routePath = '/review';

  final bool useMockReview;
  final bool mockEmpty;

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  final _textController = TextEditingController();
  final Set<String> _bookmarks = <String>{};
  ReviewSessionState? _mockSession;
  _Stage _stage = _Stage.home;
  int _passCount = 0;

  bool get _useMock => widget.useMockReview || _useMockReviewEnv;

  @override
  void initState() {
    super.initState();
    if (_useMock) {
      _mockSession = _mockSessionState(empty: widget.mockEmpty);
    } else {
      Future.microtask(
        () => ref.read(reviewControllerProvider.notifier).loadTodayReviews(),
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
    if (_useMock) {
      return _buildSession(
        context,
        _mockSession ?? _mockSessionState(empty: widget.mockEmpty),
      );
    }
    final async = ref.watch(reviewControllerProvider);
    return async.when(
      data: (session) => _buildSession(context, session),
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) => Scaffold(
        body: SafeArea(
          child: _ReviewScaffold(
            title: _todayReview,
            onBack: () => Navigator.of(context).maybePop(),
            child: _StateCard(
              icon: Icons.wifi_off_rounded,
              title: 'Review data unavailable',
              body: 'Please try again in a moment.',
              actionLabel: 'Retry',
              onAction: () => ref
                  .read(reviewControllerProvider.notifier)
                  .loadTodayReviews(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context, ReviewSessionState session) {
    if (session.items.isEmpty && _stage != _Stage.complete) {
      return _ReviewScaffold(
        title: _todayReview,
        onBack: () => Navigator.of(context).maybePop(),
        child: _EmptyReview(onHome: () => Navigator.of(context).maybePop()),
      );
    }

    if (_stage == _Stage.home) {
      return _ReviewScaffold(
        title: _todayReview,
        onBack: () => Navigator.of(context).maybePop(),
        child: _ReviewHome(
          session: session,
          onStart: () => setState(() => _stage = _Stage.answering),
        ),
      );
    }

    if (_stage == _Stage.complete) {
      return _ReviewScaffold(
        title: _reviewDone,
        onBack: () => Navigator.of(context).maybePop(),
        child: _ReviewComplete(
          session: session,
          passCount: _passCount,
          onHome: () => Navigator.of(context).maybePop(),
          onWrongNote: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmExit();
        }
      },
      child: _ReviewQuestion(
        session: session,
        bookmarked: _bookmarks.contains(session.currentItem?.question.id),
        textController: _textController,
        onBack: _confirmExit,
        onSelect: _selectAnswer,
        onTextChanged: _selectAnswer,
        onSubmit: () => _submitAnswer(session),
        onNext: () => _next(session),
        onPass: () => _pass(session),
        onBookmark: () => _toggleBookmark(session.currentItem?.question.id),
        onHint: () =>
            _showSnack('Review the evidence and pick the closest answer.'),
      ),
    );
  }

  void _selectAnswer(String answer) {
    if (_useMock) {
      final session = _mockSession;
      if (session == null || session.isAnswerChecked) {
        return;
      }
      setState(() => _mockSession = session.copyWith(selectedAnswer: answer));
      return;
    }
    ref.read(reviewControllerProvider.notifier).selectAnswer(answer);
  }

  Future<void> _submitAnswer(ReviewSessionState session) async {
    if (session.selectedAnswer.trim().isEmpty || session.isAnswerChecked) {
      return;
    }
    if (_useMock) {
      final item = session.currentItem;
      if (item == null) {
        return;
      }
      final selected = session.selectedAnswer.trim();
      final isCorrect =
          selected.toLowerCase() == item.question.answer.toLowerCase();
      final answer = ReviewAnswerResult(
        item: item,
        selectedAnswer: selected,
        isCorrect: isCorrect,
        responseTimeMs: 1400,
      );
      final before = item.memoryScore;
      final after = (before + (isCorrect ? 0.09 : -0.02)).clamp(0.0, 1.0);
      final update = MemoryUpdate(
        conceptId: item.conceptId,
        previousMemoryScore: before,
        memoryScore: after,
        nextReviewAt: DateTime.now().add(Duration(days: isCorrect ? 3 : 1)),
      );
      setState(() {
        _mockSession = session.copyWith(
          answers: [...session.answers, answer],
          memoryUpdates: [...session.memoryUpdates, update],
          isAnswerChecked: true,
        );
      });
      return;
    }
    await ref.read(reviewControllerProvider.notifier).checkAnswer();
  }

  Future<void> _next(ReviewSessionState session) async {
    _textController.clear();
    if (session.isLastQuestion) {
      if (!_useMock) {
        await ref
            .read(reviewControllerProvider.notifier)
            .awardCompletionRewards();
      }
      setState(() => _stage = _Stage.complete);
      return;
    }
    if (_useMock) {
      setState(() {
        _mockSession = session.copyWith(
          currentIndex: session.currentIndex + 1,
          selectedAnswer: '',
          isAnswerChecked: false,
          questionStartedAt: DateTime.now(),
        );
      });
      return;
    }
    ref.read(reviewControllerProvider.notifier).goNext();
  }

  Future<void> _pass(ReviewSessionState session) async {
    _textController.clear();
    _showSnack('PASS');
    _passCount += 1;
    if (_useMock) {
      final updated = [...session.items]..removeAt(session.currentIndex);
      setState(() {
        _mockSession = session.copyWith(
          items: updated,
          currentIndex: updated.isEmpty
              ? 0
              : math.min(session.currentIndex, updated.length - 1),
          selectedAnswer: '',
          isAnswerChecked: false,
        );
        if (updated.isEmpty) _stage = _Stage.complete;
      });
      return;
    }
    await ref
        .read(reviewControllerProvider.notifier)
        .passCurrentItem(
          passType: LearningPassType.question,
          reason: LearningPassReason.reviewLater,
        );
    final updated = ref.read(reviewControllerProvider).asData?.value;
    if (updated != null && updated.items.isEmpty) {
      setState(() => _stage = _Stage.complete);
    }
  }

  void _toggleBookmark(String? questionId) {
    if (questionId == null) {
      return;
    }
    final added = _bookmarks.add(questionId);
    if (!added) {
      _bookmarks.remove(questionId);
    }
    setState(() {});
    _showSnack(added ? 'Bookmarked' : 'Bookmark removed');
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_exitTitle),
        content: Text(_exitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_keepReview),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_saveExit),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReviewScaffold extends StatelessWidget {
  const _ReviewScaffold({
    required this.title,
    required this.child,
    required this.onBack,
  });

  final String title;
  final Widget child;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return MameroomShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewHome extends StatelessWidget {
  const _ReviewHome({required this.session, required this.onStart});

  final ReviewSessionState session;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final weakest = session.items.reduce(
      (a, b) => a.memoryScore <= b.memoryScore ? a : b,
    );
    final average =
        session.items.fold<double>(0, (sum, item) => sum + item.memoryScore) /
        session.items.length;
    final minutes = math.max(5, session.items.length * 2);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroGarden(memoryRate: average),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: _due,
                  value: '${session.items.length} Q',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(label: _expectedTime, value: '$minutes min'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MemoryReasonCard(
            title: _memoryRate,
            before: average,
            after: (average + 0.08).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.priority_high_rounded,
            title: _weakest,
            body:
                "${weakest.question.sectionId ?? 'Insurance Actuary Test'}\n$_memoryRate ${(weakest.memoryScore * 100).round()}%",
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton(onPressed: onStart, child: Text(_startReview)),
          ),
        ],
      ),
    );
  }
}

class _ReviewQuestion extends StatelessWidget {
  const _ReviewQuestion({
    required this.session,
    required this.bookmarked,
    required this.textController,
    required this.onBack,
    required this.onSelect,
    required this.onTextChanged,
    required this.onSubmit,
    required this.onNext,
    required this.onPass,
    required this.onBookmark,
    required this.onHint,
  });

  final ReviewSessionState session;
  final bool bookmarked;
  final TextEditingController textController;
  final VoidCallback onBack;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onSubmit;
  final VoidCallback onNext;
  final VoidCallback onPass;
  final VoidCallback onBookmark;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final item = session.currentItem!;
    final question = item.question;
    final total = session.items.length;
    return QuizSessionShell(
      config: _reviewModeConfig,
      current: session.currentIndex + 1,
      total: total,
      coinBalance: 250,
      onExit: onBack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QuizQuestionCard(
              questionText: question.questionText,
              questionTypeLabel: _modeQuestionTypeLabel(question.type),
              difficultyLabel: 'Level ${question.difficulty}',
              categoryLabel: _reviewModeConfig.badgeLabel,
              sourceLabel: question.evidence,
              child: const Icon(
                Icons.menu_book_rounded,
                size: 44,
                color: Color(0xFF705CFF),
              ),
            ),
            const SizedBox(height: 12),
            if (question.type == QuizQuestionType.shortAnswer)
              TextField(
                controller: textController,
                onChanged: onTextChanged,
                decoration: InputDecoration(
                  hintText: 'Type your answer',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )
            else
              ...question.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AnswerOption(
                    text: option,
                    selected: session.selectedAnswer == option,
                    disabled: session.isAnswerChecked,
                    onTap: () => onSelect(option),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            QuizActionToolbar(
              bookmarked: bookmarked,
              isSaving: session.isSaving,
              canSubmit:
                  session.selectedAnswer.trim().isNotEmpty &&
                  !session.isAnswerChecked,
              submitLabel: _submit,
              hintLabel: _hint,
              bookmarkLabel: _bookmark,
              onHint: onHint,
              onPass: onPass,
              onBookmark: onBookmark,
              onSubmit: onSubmit,
            ),
            if (session.isAnswerChecked && session.currentAnswer != null) ...[
              const SizedBox(height: 12),
              _ReviewFeedback(
                answer: session.currentAnswer!,
                update: session.memoryUpdates.isEmpty
                    ? null
                    : session.memoryUpdates.last,
                onNext: onNext,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewFeedback extends StatelessWidget {
  const _ReviewFeedback({
    required this.answer,
    required this.update,
    required this.onNext,
  });

  final ReviewAnswerResult answer;
  final MemoryUpdate? update;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isCorrect = answer.isCorrect;
    final before =
        ((update?.previousMemoryScore ?? answer.item.memoryScore) * 100)
            .round();
    final after = ((update?.memoryScore ?? answer.item.memoryScore) * 100)
        .round();
    final color = isCorrect ? const Color(0xFF7ED957) : const Color(0xFFFF6B6B);
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isCorrect ? '$_correct!' : '$_wrong!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Icon(
            isCorrect ? Icons.eco_rounded : Icons.local_florist_outlined,
            size: 72,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            isCorrect ? _memoryRecovered : _tryAgain,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _MemoryReasonCard(
            title: _memoryRate,
            before: before / 100,
            after: after / 100,
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 10),
            _InfoLine(label: _selectedAnswer, value: answer.selectedAnswer),
            _InfoLine(
              label: _correctAnswer,
              value: answer.item.question.answer,
            ),
            _InfoLine(
              label: _explanation,
              value: answer.item.question.explanation,
            ),
          ],
          const SizedBox(height: 10),
          _InfoLine(
            label: _nextReview,
            value: _formatNext(update?.nextReviewAt),
          ),
          _InfoLine(label: 'M-Coin', value: isCorrect ? '+5' : '+2'),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: FilledButton(onPressed: onNext, child: Text(_nextQuestion)),
          ),
        ],
      ),
    );
  }
}

class _ReviewComplete extends StatelessWidget {
  const _ReviewComplete({
    required this.session,
    required this.passCount,
    required this.onHome,
    required this.onWrongNote,
  });

  final ReviewSessionState session;
  final int passCount;
  final VoidCallback onHome;
  final VoidCallback onWrongNote;

  @override
  Widget build(BuildContext context) {
    final summary = session.summary;
    final total = summary.totalCount + passCount;
    final correct = summary.correctCount;
    final incorrect = summary.totalCount - correct;
    final success = summary.totalCount == 0
        ? 0
        : (summary.accuracy * 100).round();
    final memoryBefore = session.memoryUpdates.isEmpty
        ? 43
        : (session.memoryUpdates.first.previousMemoryScore * 100).round();
    final memoryAfter = session.memoryUpdates.isEmpty
        ? 52
        : (session.memoryUpdates.last.memoryScore * 100).round();
    final coin = session.coinReward.earnedCoins > 0
        ? session.coinReward.earnedCoins
        : correct * 5 + incorrect * 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SoftCard(
            child: Column(
              children: [
                const Icon(
                  Icons.celebration_rounded,
                  size: 74,
                  color: Color(0xFF705CFF),
                ),
                const SizedBox(height: 8),
                Text(
                  _reviewDone,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _ResultLine(label: 'Total', value: '$total'),
                _ResultLine(label: _correct, value: '$correct'),
                _ResultLine(label: _wrong, value: '$incorrect'),
                _ResultLine(label: 'PASS', value: '$passCount'),
                _ResultLine(label: 'Success', value: '$success%'),
                _ResultLine(
                  label: _memoryRate,
                  value: '$memoryBefore% -> $memoryAfter%',
                ),
                _ResultLine(label: 'M-Coin', value: '+$coin'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton(onPressed: onHome, child: Text(_home)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: onWrongNote,
              child: Text(_wrongNote),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: _StateCard(
        icon: Icons.local_florist_rounded,
        title: _emptyDone,
        body: _startFirst,
        actionLabel: _home,
        onAction: onHome,
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.text,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF705CFF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF705CFF) : const Color(0xFFEDE9FE),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? Colors.white : const Color(0xFF1F1B4D),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HeroGarden extends StatelessWidget {
  const _HeroGarden({required this.memoryRate});

  final double memoryRate;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      background: const LinearGradient(
        colors: [Color(0xFFF2EDFF), Color(0xFFFFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_florist_rounded,
            size: 96,
            color: Color(0xFF8BC34A),
          ),
          const SizedBox(height: 8),
          Text(
            _todayReview,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: memoryRate.clamp(0.0, 1.0),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text('$_memoryRate ${(memoryRate * 100).round()}%'),
        ],
      ),
    );
  }
}

class _MemoryReasonCard extends StatelessWidget {
  const _MemoryReasonCard({
    required this.title,
    required this.before,
    required this.after,
  });

  final String title;
  final double before;
  final double after;

  @override
  Widget build(BuildContext context) {
    final beforePct = (before * 100).round();
    final afterPct = (after * 100).round();
    final delta = afterPct - beforePct;
    return _SoftCard(
      child: Row(
        children: [
          const Icon(
            Icons.psychology_alt_rounded,
            color: Color(0xFF705CFF),
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$beforePct% -> $afterPct% (${delta >= 0 ? '+' : ''}$delta%)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF705CFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _SoftCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF705CFF), size: 86),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, this.background});

  final Widget child;
  final Gradient? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background == null ? Colors.white : null,
        gradient: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
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
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

String _formatNext(DateTime? dateTime) {
  if (dateTime == null) return 'Tomorrow';
  final days = dateTime.difference(DateTime.now()).inDays + 1;
  return '${math.max(1, days)} day';
}

ReviewSessionState _mockSessionState({required bool empty}) {
  final now = DateTime.now();
  return ReviewSessionState(
    items: empty
        ? const <ReviewSchedule>[]
        : MockReviewFixture.dueReviews(clock: now),
    currentIndex: 0,
    answers: const [],
    selectedAnswer: '',
    isAnswerChecked: false,
    questionStartedAt: now,
  );
}
