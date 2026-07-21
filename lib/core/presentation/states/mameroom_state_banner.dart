import 'package:flutter/material.dart';

import '../../../shared/design_system/theme/mameroom_theme_extension.dart';

enum MameroomStateBannerVariant { info, success, warning, error, offline }

class MameroomStateBanner extends StatelessWidget {
  const MameroomStateBanner({
    super.key,
    required this.variant,
    required this.message,
    this.actionText,
    this.onAction,
    this.onClose,
  });

  final MameroomStateBannerVariant variant;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final color = _color(colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_icon(), color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (actionText != null)
            TextButton(onPressed: onAction, child: Text(actionText!)),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Color _color(MameroomTheme colors) {
    return switch (variant) {
      MameroomStateBannerVariant.info => colors.primary,
      MameroomStateBannerVariant.success => const Color(0xFF7ED957),
      MameroomStateBannerVariant.warning => const Color(0xFFFFB54D),
      MameroomStateBannerVariant.error => const Color(0xFFFF6B6B),
      MameroomStateBannerVariant.offline => const Color(0xFF9AA0A6),
    };
  }

  IconData _icon() {
    return switch (variant) {
      MameroomStateBannerVariant.info => Icons.info_outline_rounded,
      MameroomStateBannerVariant.success => Icons.check_circle_rounded,
      MameroomStateBannerVariant.warning => Icons.warning_amber_rounded,
      MameroomStateBannerVariant.error => Icons.error_outline_rounded,
      MameroomStateBannerVariant.offline => Icons.wifi_off_rounded,
    };
  }
}

class MameroomRetryButton extends StatelessWidget {
  const MameroomRetryButton({
    super.key,
    required this.onPressed,
    this.label = '\uB2E4\uC2DC \uC2DC\uB3C4',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.refresh_rounded),
      label: Text(label),
    );
  }
}
