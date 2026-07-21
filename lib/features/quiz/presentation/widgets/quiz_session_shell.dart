import 'package:flutter/material.dart';

import '../../../../shared/widgets/mameroom_shell.dart';

class QuizModeConfig {
  const QuizModeConfig({
    required this.title,
    required this.badgeLabel,
    required this.exitDialogTitle,
    required this.exitDialogDescription,
    required this.resultTitle,
    this.showReviewMetadata = false,
    this.showNextReviewDate = false,
  });

  final String title;
  final String badgeLabel;
  final String exitDialogTitle;
  final String exitDialogDescription;
  final String resultTitle;
  final bool showReviewMetadata;
  final bool showNextReviewDate;
}

class QuizSessionShell extends StatelessWidget {
  const QuizSessionShell({
    super.key,
    required this.config,
    required this.current,
    required this.total,
    required this.coinBalance,
    required this.onExit,
    required this.child,
  });

  final QuizModeConfig config;
  final int current;
  final int total;
  final int coinBalance;
  final VoidCallback onExit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : current.clamp(0, total) / total;
    return MameroomShell(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 44,
                      child: IconButton(
                        tooltip: config.exitDialogTitle,
                        onPressed: onExit,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            config.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF2A2554),
                                ),
                          ),
                          Semantics(
                            label: 'Question $current of $total',
                            child: Text(
                              '$current / $total',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2A2554),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    QuizCoinPill(value: coinBalance),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    color: const Color(0xFF705CFF),
                    backgroundColor: const Color(0xFFEDE9FE),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.questionText,
    required this.questionTypeLabel,
    required this.difficultyLabel,
    required this.categoryLabel,
    required this.child,
    this.sourceLabel,
  });

  final String questionText;
  final String questionTypeLabel;
  final String difficultyLabel;
  final String categoryLabel;
  final String? sourceLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return QuizSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              QuizChip(
                label: questionTypeLabel,
                color: const Color(0xFF705CFF),
              ),
              QuizChip(label: difficultyLabel, color: const Color(0xFFFFB347)),
              if (categoryLabel.trim().isNotEmpty)
                QuizChip(label: categoryLabel, color: const Color(0xFF8BC34A)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            questionText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2A2554),
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
                color: const Color(0xFF6D6890),
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class QuizActionToolbar extends StatelessWidget {
  const QuizActionToolbar({
    super.key,
    required this.canSubmit,
    required this.isSaving,
    required this.bookmarked,
    required this.submitLabel,
    required this.hintLabel,
    required this.bookmarkLabel,
    required this.onHint,
    required this.onPass,
    required this.onBookmark,
    required this.onSubmit,
  });

  final bool canSubmit;
  final bool isSaving;
  final bool bookmarked;
  final String submitLabel;
  final String hintLabel;
  final String bookmarkLabel;
  final VoidCallback onHint;
  final VoidCallback onPass;
  final VoidCallback onBookmark;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToolButton(
          label: hintLabel,
          icon: Icons.lightbulb_outline_rounded,
          onPressed: isSaving ? null : onHint,
        ),
        const SizedBox(width: 8),
        _ToolButton(
          label: 'PASS',
          icon: Icons.skip_next_rounded,
          onPressed: isSaving ? null : onPass,
        ),
        const SizedBox(width: 8),
        _ToolButton(
          label: bookmarkLabel,
          icon: bookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          selected: bookmarked,
          onPressed: isSaving ? null : onBookmark,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: !isSaving && canSubmit ? onSubmit : null,
              child: Text(submitLabel),
            ),
          ),
        ),
      ],
    );
  }
}

class QuizSurfaceCard extends StatelessWidget {
  const QuizSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
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

class QuizChip extends StatelessWidget {
  const QuizChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class QuizCoinPill extends StatelessWidget {
  const QuizCoinPill({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            size: 18,
            color: Color(0xFFFFB54D),
          ),
          const SizedBox(width: 4),
          Text('$value'),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
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
    return SizedBox(
      width: 50,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: selected ? const Color(0xFFF2EDFF) : Colors.white,
          side: BorderSide(
            color: selected ? const Color(0xFF705CFF) : const Color(0xFFEDE9FE),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Tooltip(message: label, child: Icon(icon, size: 20)),
      ),
    );
  }
}
