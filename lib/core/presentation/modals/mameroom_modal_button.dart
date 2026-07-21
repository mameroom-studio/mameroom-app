import 'package:flutter/material.dart';

import '../../../shared/design_system/theme/mameroom_theme_extension.dart';
import 'mameroom_modal_theme.dart';

class MameroomModalButton extends StatelessWidget {
  const MameroomModalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MameroomModalButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final MameroomModalButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final enabled =
        onPressed != null && variant != MameroomModalButtonVariant.disabled;
    final isFilled =
        variant == MameroomModalButtonVariant.primary ||
        variant == MameroomModalButtonVariant.warning ||
        variant == MameroomModalButtonVariant.destructive;
    final background = switch (variant) {
      MameroomModalButtonVariant.primary => colors.primary,
      MameroomModalButtonVariant.warning => const Color(0xFFFF8A00),
      MameroomModalButtonVariant.destructive => const Color(0xFFFF5B68),
      MameroomModalButtonVariant.secondary => colors.paper,
      MameroomModalButtonVariant.disabled => colors.line,
    };
    final foreground = isFilled ? Colors.white : colors.ink;
    final borderColor = variant == MameroomModalButtonVariant.secondary
        ? colors.primaryPale
        : Colors.transparent;

    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: isFilled && enabled
              ? [
                  BoxShadow(
                    color: background.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: background,
            disabledBackgroundColor: colors.line,
            foregroundColor: foreground,
            disabledForegroundColor: colors.muted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}
