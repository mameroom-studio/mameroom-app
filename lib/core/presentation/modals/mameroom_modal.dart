import 'package:flutter/material.dart';

import '../../../shared/design_system/theme/mameroom_theme_extension.dart';
import 'mameroom_modal_button.dart';
import 'mameroom_modal_icon.dart';
import 'mameroom_modal_theme.dart';

class MameroomModal extends StatelessWidget {
  const MameroomModal({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.customContent,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.destructiveButtonText,
    this.onPrimary,
    this.onSecondary,
    this.onDestructive,
    this.showCloseButton = true,
    this.modalSize = MameroomModalSize.medium,
    this.variant = MameroomModalVariant.info,
    this.primaryVariant = MameroomModalButtonVariant.primary,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? customContent;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final String? destructiveButtonText;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final VoidCallback? onDestructive;
  final bool showCloseButton;
  final MameroomModalSize modalSize;
  final MameroomModalVariant variant;
  final MameroomModalButtonVariant primaryVariant;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final size = MediaQuery.sizeOf(context);
    final maxWidth = mameroomModalMaxWidth(modalSize, size.width);
    final maxHeight = size.height - 72;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: colors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.primaryPale),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MameroomModalIcon(variant: variant, icon: icon),
                                const SizedBox(height: 8),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: colors.ink,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                if (message != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    message!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colors.ink,
                                          height: 1.42,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                                if (customContent != null) ...[
                                  const SizedBox(height: 14),
                                  customContent!,
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_hasButtons) ...[
                          const SizedBox(height: 18),
                          _ModalActions(
                            primaryButtonText: primaryButtonText,
                            secondaryButtonText: secondaryButtonText,
                            destructiveButtonText: destructiveButtonText,
                            onPrimary: onPrimary,
                            onSecondary: onSecondary,
                            onDestructive: onDestructive,
                            primaryVariant: primaryVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showCloseButton)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        tooltip: '\uB2EB\uAE30',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.close_rounded, color: colors.ink),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size.square(34),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasButtons =>
      primaryButtonText != null ||
      secondaryButtonText != null ||
      destructiveButtonText != null;
}

class MameroomModalHeader extends StatelessWidget {
  const MameroomModalHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          tooltip: '\uB2EB\uAE30',
          onPressed: onClose,
          icon: Icon(Icons.close_rounded, color: colors.ink),
        ),
      ],
    );
  }
}

class MameroomModalProgress extends StatelessWidget {
  const MameroomModalProgress({super.key, required this.value, this.label});

  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final clamped = value.clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 8,
              color: colors.primary,
              backgroundColor: colors.primaryMist.withValues(alpha: 0.6),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 10),
          Text(
            label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _ModalActions extends StatelessWidget {
  const _ModalActions({
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.destructiveButtonText,
    required this.onPrimary,
    required this.onSecondary,
    required this.onDestructive,
    required this.primaryVariant,
  });

  final String? primaryButtonText;
  final String? secondaryButtonText;
  final String? destructiveButtonText;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final VoidCallback? onDestructive;
  final MameroomModalButtonVariant primaryVariant;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (secondaryButtonText != null)
        Expanded(
          child: MameroomModalButton(
            label: secondaryButtonText!,
            onPressed: onSecondary,
            variant: MameroomModalButtonVariant.secondary,
          ),
        ),
      if (primaryButtonText != null)
        Expanded(
          child: MameroomModalButton(
            label: primaryButtonText!,
            onPressed: onPrimary,
            variant: primaryVariant,
          ),
        ),
      if (destructiveButtonText != null)
        Expanded(
          child: MameroomModalButton(
            label: destructiveButtonText!,
            onPressed: onDestructive,
            variant: MameroomModalButtonVariant.destructive,
          ),
        ),
    ];

    if (actions.length == 1) {
      return actions.single;
    }

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          actions[i],
        ],
      ],
    );
  }
}
