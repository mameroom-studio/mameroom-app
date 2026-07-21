import 'package:flutter/material.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';

class QuizProgressHeader extends StatelessWidget {
  const QuizProgressHeader({
    super.key,
    required this.current,
    required this.total,
    required this.coinBalance,
    required this.onExit,
    this.bookmarked = false,
  });

  final int current;
  final int total;
  final int coinBalance;
  final bool bookmarked;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final progress = total <= 0 ? 0.0 : current.clamp(0, total) / total;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 44,
                  child: IconButton(
                    tooltip: '학습 종료',
                    onPressed: onExit,
                    icon: Icon(Icons.close_rounded, color: colors.ink),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    label: '현재 문제 $current, 전체 문제 $total',
                    child: Text(
                      '$current / $total',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                _CoinPill(balance: coinBalance),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                color: colors.primary,
                backgroundColor: colors.primaryMist.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, color: colors.sun, size: 18),
          const SizedBox(width: 5),
          Text(
            '$balance',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.questionText,
    required this.categoryLabel,
    required this.difficultyLabel,
    required this.questionTypeLabel,
    required this.child,
    this.sourceLabel,
  });

  final String questionText;
  final String categoryLabel;
  final String difficultyLabel;
  final String questionTypeLabel;
  final String? sourceLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return StudyFlowCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
              StudyBadge(label: questionTypeLabel, color: colors.primary),
              StudyBadge(label: difficultyLabel, color: colors.wood),
              if (categoryLabel.trim().isNotEmpty)
                StudyBadge(label: categoryLabel, color: colors.seedGreen),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            questionText,
            textAlign: TextAlign.center,
            softWrap: true,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              height: 1.45,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (sourceLabel != null && sourceLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              sourceLabel!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.muted,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class StudyBadge extends StatelessWidget {
  const StudyBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class PixelQuizIllustration extends StatelessWidget {
  const PixelQuizIllustration({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SizedBox(
      height: compact ? 78 : 112,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 18,
            right: 18,
            bottom: 7,
            child: Container(
              height: compact ? 22 : 30,
              decoration: BoxDecoration(
                color: colors.seedGreen.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 30,
            bottom: compact ? 18 : 24,
            child: _PixelTree(size: compact ? 32 : 42),
          ),
          Positioned(
            right: 32,
            bottom: compact ? 16 : 22,
            child: _PixelTree(size: compact ? 30 : 38),
          ),
          Icon(
            Icons.menu_book_rounded,
            size: compact ? 62 : 86,
            color: colors.primarySoft.withValues(alpha: 0.75),
          ),
        ],
      ),
    );
  }
}

class PixelSeedHero extends StatelessWidget {
  const PixelSeedHero({super.key, this.size = 126, this.mood = SeedMood.happy});

  final double size;
  final SeedMood mood;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final face = mood == SeedMood.wrong
        ? const Color(0xFFFFF0EA)
        : const Color(0xFFFFF7E6);
    final mouth = mood == SeedMood.wrong ? '•︵•' : '•‿•';
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: size * 0.08,
            child: Container(
              width: size * 0.58,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: mood == SeedMood.growth ? colors.seedGreen : colors.wood,
                borderRadius: BorderRadius.circular(size * 0.18),
                border: Border.all(
                  color: colors.ink.withValues(alpha: 0.14),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            top: size * 0.26,
            child: Container(
              width: size * 0.43,
              height: size * 0.43,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: face,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.ink.withValues(alpha: 0.22),
                  width: 2,
                ),
              ),
              child: Text(
                mouth,
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.12,
                ),
              ),
            ),
          ),
          Positioned(
            top: size * 0.06,
            child: Icon(
              Icons.eco_rounded,
              color: colors.seedGreen,
              size: size * 0.34,
            ),
          ),
          if (mood == SeedMood.growth)
            for (final item in const [
              Offset(0.12, 0.18),
              Offset(0.80, 0.26),
              Offset(0.20, 0.58),
            ])
              Positioned(
                left: size * item.dx,
                top: size * item.dy,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.sun,
                  size: size * 0.11,
                ),
              ),
        ],
      ),
    );
  }
}

enum SeedMood { happy, wrong, growth }

class _PixelTree extends StatelessWidget {
  const _PixelTree({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: size * 0.16,
            height: size * 0.45,
            color: colors.wood,
          ),
          Positioned(
            top: 0,
            child: Icon(
              Icons.park_rounded,
              size: size,
              color: colors.seedGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class AnswerOptionCard extends StatelessWidget {
  const AnswerOptionCard({
    super.key,
    required this.index,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.reveal = false,
    this.isCorrect = false,
    this.isWrongSelection = false,
  });

  final int index;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final bool reveal;
  final bool isCorrect;
  final bool isWrongSelection;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final baseColor = isCorrect
        ? colors.seedGreen
        : isWrongSelection
        ? const Color(0xFFE94B4B)
        : colors.primary;
    final filled = selected || isCorrect || isWrongSelection;
    return Semantics(
      button: true,
      label: '$index번 보기 $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: filled
                ? baseColor.withValues(alpha: selected && !reveal ? 1 : 0.14)
                : colors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled ? baseColor : colors.line,
              width: filled ? 1.6 : 1,
            ),
            boxShadow: selected && !reveal
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled && selected && !reveal
                      ? Colors.white.withValues(alpha: 0.20)
                      : baseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: selected && !reveal ? Colors.white : baseColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected && !reveal ? Colors.white : colors.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.28,
                  ),
                ),
              ),
              if (reveal && isCorrect)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.seedGreen,
                  size: 20,
                )
              else if (reveal && isWrongSelection)
                const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFE94B4B),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShortAnswerField extends StatelessWidget {
  const ShortAnswerField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      minLines: 2,
      maxLines: 4,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: '정답 입력',
        hintText: '기억나는 답을 입력해주세요.',
        alignLabelWithHint: true,
        prefixIcon: Icon(Icons.edit_note_rounded, color: colors.primary),
        filled: true,
        fillColor: colors.cloud,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class BottomQuizActionBar extends StatelessWidget {
  const BottomQuizActionBar({
    super.key,
    required this.canSubmit,
    required this.isSaving,
    required this.bookmarked,
    required this.onHint,
    required this.onPass,
    required this.onBookmark,
    required this.onSubmit,
    this.canUseHint = false,
  });

  final bool canSubmit;
  final bool isSaving;
  final bool bookmarked;
  final bool canUseHint;
  final VoidCallback onHint;
  final VoidCallback onPass;
  final VoidCallback onBookmark;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border(top: BorderSide(color: colors.line)),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            _ToolbarButton(
              label: '힌트',
              icon: Icons.lightbulb_outline_rounded,
              onPressed: canUseHint && !isSaving ? onHint : null,
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              label: 'PASS',
              icon: Icons.skip_next_rounded,
              onPressed: isSaving ? null : onPass,
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              label: '북마크',
              icon: bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              onPressed: isSaving ? null : onBookmark,
              selected: bookmarked,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: !isSaving && canSubmit ? onSubmit : null,
                  child: Text(isSaving ? '저장 중...' : '제출하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SizedBox(
      width: 55,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: selected ? colors.primaryMist : colors.paper,
          side: BorderSide(color: selected ? colors.primary : colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackResultCard extends StatelessWidget {
  const FeedbackResultCard({
    super.key,
    required this.kind,
    required this.answer,
    required this.message,
    required this.rewardText,
    required this.onNext,
    this.selectedAnswer,
    this.explanation,
    this.source,
    this.isLast = false,
  });

  final FeedbackKind kind;
  final String answer;
  final String? selectedAnswer;
  final String message;
  final String? explanation;
  final String? source;
  final String rewardText;
  final VoidCallback onNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final accent = switch (kind) {
      FeedbackKind.correct => colors.seedGreen,
      FeedbackKind.incorrect => const Color(0xFFE94B4B),
      FeedbackKind.pass => colors.wood,
    };
    final title = switch (kind) {
      FeedbackKind.correct => '정답!',
      FeedbackKind.incorrect => '오답',
      FeedbackKind.pass => 'PASS',
    };
    final mood = switch (kind) {
      FeedbackKind.correct => SeedMood.happy,
      FeedbackKind.incorrect => SeedMood.wrong,
      FeedbackKind.pass => SeedMood.happy,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                PixelSeedHero(size: 116, mood: mood),
                const SizedBox(height: 12),
                StudyFlowCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (kind == FeedbackKind.incorrect &&
                          selectedAnswer != null) ...[
                        _InfoLine(label: '내 답', value: selectedAnswer!),
                        const SizedBox(height: 8),
                      ],
                      _InfoLine(label: '정답', value: answer),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.ink,
                          height: 1.42,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (explanation != null &&
                          explanation!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          explanation!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.muted,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      if (source != null && source!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SourceReferenceCard(source: source!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RewardRow(label: rewardText),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              child: Text(isLast ? '결과 보기' : '다음 문제'),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.ink,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

enum FeedbackKind { correct, incorrect, pass }

class SourceReferenceCard extends StatelessWidget {
  const SourceReferenceCard({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cloud,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.article_outlined, color: colors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              source,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.muted,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RewardRow extends StatelessWidget {
  const RewardRow({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.monetization_on_rounded, color: colors.sun, size: 22),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class BookmarkSavedSnack extends SnackBar {
  const BookmarkSavedSnack({super.key})
    : super(
        content: const Text('북마크에 저장했어요. 나중에 다시 확인할 수 있어요.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1300),
      );
}

class ExitQuizDialog extends StatelessWidget {
  const ExitQuizDialog({super.key, required this.onSaveAndExit});

  final VoidCallback onSaveAndExit;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return AlertDialog(
      backgroundColor: colors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('학습을 종료할까요?'),
      content: const Text('현재까지의 진행 상황은 저장되며 나중에 이어서 학습할 수 있습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('계속 학습'),
        ),
        FilledButton(onPressed: onSaveAndExit, child: const Text('저장하고 종료')),
      ],
    );
  }
}

class MemoryGrowthPanel extends StatelessWidget {
  const MemoryGrowthPanel({
    super.key,
    required this.beforeLevel,
    required this.afterLevel,
    required this.progress,
    required this.onConfirm,
  });

  final int beforeLevel;
  final int afterLevel;
  final double progress;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StudyFlowCard(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\uAE30\uC5B5\uC528\uC557 \uC131\uC7A5!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const PixelSeedHero(size: 112, mood: SeedMood.growth),
                    const SizedBox(height: 10),
                    Text(
                      'Lv.$beforeLevel  \u2192  Lv.$afterLevel',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\${(progress.clamp(0, 1) * 100).round()}%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: onConfirm,
              child: const Text('\uD655\uC778'),
            ),
          ),
        ],
      ),
    );
  }
}

class ComboRewardCard extends StatelessWidget {
  const ComboRewardCard({super.key, required this.combo, required this.coin});

  final int combo;
  final int coin;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return StudyFlowCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'COMBO $combo!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colors.wood,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Icon(Icons.inventory_2_rounded, color: colors.sun, size: 86),
          const SizedBox(height: 12),
          Text(
            '연속 정답 시 콤보 보상 획득!',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          RewardRow(label: '+$coin M-Coin'),
        ],
      ),
    );
  }
}

class QuizResultSummaryCard extends StatelessWidget {
  const QuizResultSummaryCard({
    super.key,
    required this.correct,
    required this.incorrect,
    required this.passed,
    required this.accuracy,
    required this.coin,
    required this.memoryBefore,
    required this.memoryAfter,
    required this.seedGrowth,
    required this.onHome,
    this.onReview,
  });

  final int correct;
  final int incorrect;
  final int passed;
  final int accuracy;
  final int coin;
  final int memoryBefore;
  final int memoryAfter;
  final int seedGrowth;
  final VoidCallback onHome;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return StudyFlowCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '퀴즈 완료!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: '정답',
                  value: '$correct개',
                  color: colors.seedGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: '오답',
                  value: '$incorrect개',
                  color: const Color(0xFFE94B4B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'PASS',
                  value: '$passed개',
                  color: colors.wood,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ResultLine(label: '정확도', value: '$accuracy%'),
          _ResultLine(label: 'M-Coin', value: '+$coin'),
          _ResultLine(label: '기억률', value: '$memoryBefore% → $memoryAfter%'),
          _ResultLine(label: '기억씨앗', value: '+$seedGrowth%'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(onPressed: onHome, child: const Text('홈으로 가기')),
          ),
          if (onReview != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: onReview,
                child: const Text('오답노트 보기'),
              ),
            ),
          ],
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
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: colors.muted, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: colors.ink, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class StudyFlowCard extends StatelessWidget {
  const StudyFlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.09),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
