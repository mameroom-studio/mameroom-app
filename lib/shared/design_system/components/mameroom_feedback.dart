import 'package:flutter/material.dart';

import '../tokens/mameroom_colors.dart';
import '../tokens/mameroom_radius.dart';
import '../tokens/mameroom_spacing.dart';

enum MameroomFeedbackVariant { info, success, warning, error }

class MameroomToast extends SnackBar {
  MameroomToast({
    super.key,
    required String message,
    MameroomFeedbackVariant variant = MameroomFeedbackVariant.info,
    Widget? action,
  }) : super(
         content: Row(
           children: [
             Icon(
               _variantIcon(variant),
               color: _variantColor(variant),
               size: 20,
             ),
             const SizedBox(width: MameroomSpacing.xs),
             Expanded(
               child: Text(
                 message,
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
             ?action,
           ],
         ),
         behavior: SnackBarBehavior.floating,
         duration: const Duration(milliseconds: 1800),
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(MameroomRadius.medium),
         ),
       );
}

class MameroomBanner extends StatelessWidget {
  const MameroomBanner({
    super.key,
    required this.message,
    this.variant = MameroomFeedbackVariant.info,
    this.action,
    this.onDismissed,
  });

  final String message;
  final MameroomFeedbackVariant variant;
  final Widget? action;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    final color = _variantColor(variant);
    final dismissButton = onDismissed == null
        ? null
        : IconButton(
            onPressed: onDismissed,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Dismiss',
          );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MameroomSpacing.md,
        vertical: MameroomSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: MameroomRadius.mediumRadius,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(_variantIcon(variant), color: color, size: 20),
          const SizedBox(width: MameroomSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MameroomColors.textPrimary,
              ),
            ),
          ),
          ?action,
          ?dismissButton,
        ],
      ),
    );
  }
}

IconData _variantIcon(MameroomFeedbackVariant variant) => switch (variant) {
  MameroomFeedbackVariant.info => Icons.info_rounded,
  MameroomFeedbackVariant.success => Icons.check_circle_rounded,
  MameroomFeedbackVariant.warning => Icons.warning_rounded,
  MameroomFeedbackVariant.error => Icons.error_rounded,
};

Color _variantColor(MameroomFeedbackVariant variant) => switch (variant) {
  MameroomFeedbackVariant.info => MameroomColors.info,
  MameroomFeedbackVariant.success => MameroomColors.success,
  MameroomFeedbackVariant.warning => MameroomColors.warning,
  MameroomFeedbackVariant.error => MameroomColors.error,
};
