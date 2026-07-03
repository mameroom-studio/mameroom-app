import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../coins/domain/policies/economy_policy.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../../quiz/domain/entities/quiz_result_snapshot.dart';
import '../../../quiz/presentation/pages/quiz_result_page.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';
import '../widgets/study_components.dart';
import '../widgets/study_feedback_screens.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({required this.materialId, super.key});

  final String? materialId;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final materialId = widget.materialId;
    if (materialId != null && materialId.isNotEmpty) {
      Future.microtask(() => ref.read(quizControllerProvider.notifier).load(materialId: materialId));
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
    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: widget.materialId == null || widget.materialId!.isEmpty
          ? _MissingMaterialId(onBack: () => context.go(LibraryPage.routePath))
          : state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _StudyError(message: error.toString()),
              data: _buildSession,
            ),
    );
  }

  Widget _buildSession(QuizSessionState session) {
    final question = session.currentQuestion;
    if (question == null) {
      return const Center(child: Text('생성된 문제가 없어요.'));
    }

    if (question.type == QuizQuestionType.fillBlank && _textController.text != session.selectedAnswer) {
      _textController.text = session.selectedAnswer;
      _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
    }

    final answer = session.currentAnswer;
    final memoryValue = _memoryValue(session);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: session.isAnswerChecked && answer != null
                  ? answer.isCorrect
                      ? CorrectAnswerScreen(
                          key: const ValueKey('correct'),
                          memoryBefore: _lastMemoryBefore(session),
                          memoryAfter: memoryValue,
                          coinAmount: EconomyPolicy.correctAnswerCoins,
                          onNext: () => _advance(session),
                        )
                      : IncorrectAnswerScreen(
                          key: const ValueKey('incorrect'),
                          answer: answer,
                          isHardStop: session.hasHardStop,
                          hintText: _hintForIncorrect(answer.question),
                          onNext: () => _advance(session),
                        )
                  : _QuestionStudyView(
                      key: ValueKey(question.id),
                      session: session,
                      question: question,
                      memoryValue: memoryValue,
                      textController: _textController,
                      onChanged: ref.read(quizControllerProvider.notifier).selectAnswer,
                      onUseHint: ref.read(quizControllerProvider.notifier).useHint,
                      onCheckAnswer: () => _checkAnswer(session),
                    ),
            ),
          ),
        ),
        StudyBottomActionBar(
          memoryValue: memoryValue,
          onPass: session.isAnswerChecked || session.isSaving ? () {} : _openPassSheet,
          onBookmark: _openBookmarkSheet,
        ),
      ],
    );
  }

  Future<void> _checkAnswer(QuizSessionState previousSession) async {
    await ref.read(quizControllerProvider.notifier).checkAnswer();
    if (!mounted) {
      return;
    }
    final updated = ref.read(quizControllerProvider).asData?.value;
    final answer = updated?.currentAnswer;
    if (updated == null || answer == null || !answer.isCorrect) {
      return;
    }

    final delta = updated.memoryUpdates.isEmpty ? 0.0 : updated.memoryUpdates.last.delta;
    if (_hasFiveCorrectStreak(updated.answers)) {
      await showDialog<void>(
        context: context,
        builder: (context) => const ComboRewardPopup(comboCount: 5, coinAmount: EconomyPolicy.fiveCorrectStreakBonusCoins),
      );
      return;
    }
    if (delta > 0.005) {
      await showDialog<void>(
        context: context,
        builder: (context) => MemoryGrowthPopup(
          before: _lastMemoryBefore(updated),
          after: _memoryValue(updated),
        ),
      );
    }
  }

  Future<void> _advance(QuizSessionState session) async {
    if (session.isSessionTerminal) {
      final rewardWarning = await ref.read(quizControllerProvider.notifier).awardCompletionRewards();
      final resultSession = ref.read(quizControllerProvider).asData?.value ?? session;
      final snapshot = QuizResultSnapshot.fromSession(
        resultSession,
        rewardWarning: rewardWarning,
      );
      if (mounted) {
        context.go(QuizResultPage.routePath, extra: snapshot);
      }
      return;
    }
    _textController.clear();
    ref.read(quizControllerProvider.notifier).goNext();
  }

  Future<void> _openPassSheet() async {
    final decision = await showModalBottomSheet<_PassDecision>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const QuestionPassScreen(),
    );
    if (decision == null || !mounted) {
      return;
    }
    await ref.read(quizControllerProvider.notifier).passCurrentQuestion(
          passType: decision.type,
          reason: decision.reason,
        );
    if (mounted) {
      _textController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PASS 처리했어요.')));
    }
  }

  Future<void> _openBookmarkSheet() async {
    final level = await showModalBottomSheet<_BookmarkLevel>(
      context: context,
      showDragHandle: true,
      builder: (context) => const BookmarkScreen(),
    );
    if (level == null || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${level.label} 북마크로 저장했어요.')));
  }

  double _memoryValue(QuizSessionState session) {
    if (session.memoryUpdates.isNotEmpty) {
      return session.memoryUpdates.last.memoryScore.clamp(0, 1);
    }
    return session.averageMemoryScore > 0 ? session.averageMemoryScore.clamp(0, 1) : 0.68;
  }

  double _lastMemoryBefore(QuizSessionState session) {
    if (session.memoryUpdates.isEmpty) {
      return (_memoryValue(session) - 0.03).clamp(0, 1);
    }
    return session.memoryUpdates.last.previousMemoryScore.clamp(0, 1);
  }

  bool _hasFiveCorrectStreak(List<QuizAnswerResult> answers) {
    if (answers.length < 5) {
      return false;
    }
    return answers.reversed.take(5).every((answer) => answer.isCorrect);
  }

  String _hintForIncorrect(Question question) {
    if (question.explanation.trim().isNotEmpty) {
      return question.explanation;
    }
    if (question.evidence.trim().isNotEmpty) {
      return question.evidence;
    }
    return '핵심 개념을 다시 떠올린 뒤 정답과 연결해보세요.';
  }
}

class _QuestionStudyView extends StatelessWidget {
  const _QuestionStudyView({
    required this.session,
    required this.question,
    required this.memoryValue,
    required this.textController,
    required this.onChanged,
    required this.onUseHint,
    required this.onCheckAnswer,
    super.key,
  });

  final QuizSessionState session;
  final Question question;
  final double memoryValue;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final VoidCallback onUseHint;
  final VoidCallback onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final progressTotal = session.initialQuestionCount == 0 ? session.questions.length : session.initialQuestionCount;
    final progressCurrent = (session.answers.where((answer) => !answer.isRetry).length + 1).clamp(1, progressTotal);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
          children: [
            IconButton(
              tooltip: '뒤로가기',
              onPressed: () => context.go(LibraryPage.routePath),
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primary),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(session.materialTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.ink, fontWeight: FontWeight.w800)),
                  Text('문제 $progressCurrent / $progressTotal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: colors.paper, border: Border.all(color: colors.line), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: colors.sun, size: 18),
                  const SizedBox(width: 5),
                  Text('1,250', style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progressTotal == 0 ? 0 : progressCurrent / progressTotal,
            minHeight: 8,
            color: colors.primary,
            backgroundColor: colors.primaryMist.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 8),
        MemoryGauge(value: memoryValue),
        const SizedBox(height: 18),
        if (session.isReinforcementQuestion) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(Icons.replay_rounded, color: colors.primary, size: 18),
              label: Text('Retry ${session.currentRetryCount + 1} / 3'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 180),
          child: StudyCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  question.questionText,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 18),
                if (question.type == QuizQuestionType.fillBlank)
                  _HintPanel(session: session, answer: question.answer, onUseHint: onUseHint),
                const SizedBox(height: 18),
                Center(child: PixelCharacter(size: constraints.maxHeight < 560 ? 82 : 110)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _AnswerInput(question: question, selectedAnswer: session.selectedAnswer, textController: textController, enabled: !session.isSaving, onChanged: onChanged),
        const SizedBox(height: 14),
        StudyPrimaryButton(
          label: session.isSaving ? '저장 중...' : '정답 확인',
          onPressed: !session.isSaving && session.selectedAnswer.trim().isNotEmpty ? onCheckAnswer : null,
        ),
        const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnswerInput extends StatelessWidget {
  const _AnswerInput({required this.question, required this.selectedAnswer, required this.textController, required this.enabled, required this.onChanged});

  final Question question;
  final String selectedAnswer;
  final TextEditingController textController;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (question.type) {
      QuizQuestionType.multipleChoice => Column(
          children: [
            for (var index = 0; index < question.options.length; index++) ...[
              _ChoiceButton(
                index: index,
                label: question.options[index],
                selected: selectedAnswer == question.options[index],
                enabled: enabled,
                onTap: () => onChanged(question.options[index]),
              ),
              if (index != question.options.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      QuizQuestionType.ox => Row(
          children: [
            Expanded(child: _ChoiceButton(index: 0, label: 'O', selected: selectedAnswer == 'O', enabled: enabled, onTap: () => onChanged('O'))),
            const SizedBox(width: 10),
            Expanded(child: _ChoiceButton(index: 1, label: 'X', selected: selectedAnswer == 'X', enabled: enabled, onTap: () => onChanged('X'))),
          ],
        ),
      QuizQuestionType.fillBlank => SizedBox(
          height: 56,
          child: TextField(
            controller: textController,
            enabled: enabled,
            decoration: const InputDecoration(labelText: '정답 입력'),
            onChanged: onChanged,
          ),
        ),
    };
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.index, required this.label, required this.selected, required this.enabled, required this.onTap});

  final int index;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.paper,
          border: Border.all(color: selected ? colors.primary : colors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text('${index + 1}', style: TextStyle(color: selected ? Colors.white : colors.ink, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                softWrap: true,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : colors.ink,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.session, required this.answer, required this.onUseHint});

  final QuizSessionState session;
  final String answer;
  final VoidCallback onUseHint;

  @override
  Widget build(BuildContext context) {
    final hint = switch (session.currentHintLevel) {
      1 => _initialConsonantHint(answer),
      2 => _firstCharacterHint(answer),
      _ => '빈칸 문제는 힌트를 사용할 수 있어요.',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.mameroom.primaryMist.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: Text('힌트: $hint')),
          OutlinedButton.icon(
            onPressed: session.canUseHint ? onUseHint : null,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(session.currentHintLevel == 0 ? '힌트 1' : '힌트 2'),
          ),
        ],
      ),
    );
  }

  String _initialConsonantHint(String value) {
    const initials = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'];
    return value.runes.map((rune) {
      if (rune < 0xac00 || rune > 0xd7a3) {
        return String.fromCharCode(rune).trim().isEmpty ? ' ' : '_';
      }
      return initials[((rune - 0xac00) ~/ 588).clamp(0, initials.length - 1)];
    }).join();
  }

  String _firstCharacterHint(String value) {
    final chars = value.runes.toList();
    if (chars.isEmpty) {
      return '';
    }
    return '${String.fromCharCode(chars.first)}${List.filled(chars.length - 1, '_').join()}';
  }
}

class QuestionPassScreen extends StatefulWidget {
  const QuestionPassScreen({super.key});

  @override
  State<QuestionPassScreen> createState() => _QuestionPassScreenState();
}

class _QuestionPassScreenState extends State<QuestionPassScreen> {
  LearningPassType _type = LearningPassType.question;
  LearningPassReason _reason = LearningPassReason.alreadyKnown;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('이 문제는 PASS 할까요!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            SegmentedButton<LearningPassType>(
              segments: const [
                ButtonSegment(value: LearningPassType.question, label: Text('문제 PASS')),
                ButtonSegment(value: LearningPassType.concept, label: Text('개념 PASS')),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() => _type = value.first),
            ),
            const SizedBox(height: 18),
            Text('PASS 사유를 선택해주세요.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            RadioGroup<LearningPassReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value ?? _reason),
              child: Column(
                children: LearningPassReason.values.map((reason) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<LearningPassReason>(
                      value: reason,
                      title: Text(reason.label),
                      tileColor: colors.paper,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.line)),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
            const SizedBox(height: 10),
            StudyPrimaryButton(
              label: 'PASS 하기',
              onPressed: () => Navigator.of(context).pop(_PassDecision(_type, _reason)),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          ],
        ),
      ),
    );
  }
}

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  _BookmarkLevel _selected = _BookmarkLevel.important;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('중요도를 선택해주세요.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            ..._BookmarkLevel.values.map((level) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BookmarkTile(
                  level: level,
                  selected: level == _selected,
                  onTap: () => setState(() => _selected = level),
                ),
              );
            }),
            const SizedBox(height: 10),
            StudyPrimaryButton(label: '저장하기', onPressed: () => Navigator.of(context).pop(_selected)),
          ],
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.level, required this.selected, required this.onTap});

  final _BookmarkLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: selected ? colors.primary : colors.line, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(level.stars, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 16),
            Expanded(child: Text(level.label, style: Theme.of(context).textTheme.titleMedium)),
            Text(level.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.muted)),
          ],
        ),
      ),
    );
  }
}

class _PassDecision {
  const _PassDecision(this.type, this.reason);

  final LearningPassType type;
  final LearningPassReason reason;
}

enum _BookmarkLevel {
  normal('일반', '☆ ☆ ☆', '복습 빈도 1배'),
  important('중요', '★ ☆ ☆', '복습 빈도 1.5배'),
  veryImportant('매우 중요', '★ ★ ☆', '복습 빈도 2배'),
  highest('최우선', '★ ★ ★', '복습 빈도 3배');

  const _BookmarkLevel(this.label, this.stars, this.description);

  final String label;
  final String stars;
  final String description;
}

class _MissingMaterialId extends StatelessWidget {
  const _MissingMaterialId({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(child: StudyPrimaryButton(label: '라이브러리로 돌아가기', onPressed: onBack));
  }
}

class _StudyError extends StatelessWidget {
  const _StudyError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StudyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelSeed(size: 54),
              const SizedBox(height: 16),
              Text('학습 화면을 불러오지 못했어요', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

