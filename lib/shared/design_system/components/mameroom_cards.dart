import 'package:flutter/material.dart';

import '../tokens/mameroom_colors.dart';
import '../tokens/mameroom_radius.dart';
import '../tokens/mameroom_shadows.dart';
import '../tokens/mameroom_spacing.dart';

class MameroomCard extends StatelessWidget {
  const MameroomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MameroomSpacing.md),
    this.header,
    this.footer,
    this.selected = false,
    this.disabled = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? header;
  final Widget? footer;
  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: MameroomColors.surface,
          borderRadius: MameroomRadius.cardRadius,
          border: Border.all(
            color: selected ? MameroomColors.primary : MameroomColors.border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: MameroomShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(height: MameroomSpacing.sm),
            ],
            child,
            if (footer != null) ...[
              const SizedBox(height: MameroomSpacing.sm),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class MameroomElevatedCard extends StatelessWidget {
  const MameroomElevatedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MameroomSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: MameroomColors.surface,
        borderRadius: MameroomRadius.cardRadius,
        border: Border.all(color: MameroomColors.border),
        boxShadow: MameroomShadows.md,
      ),
      child: child,
    );
  }
}

class MameroomInteractiveCard extends StatelessWidget {
  const MameroomInteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.disabled = false,
    this.padding = const EdgeInsets.all(MameroomSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final bool disabled;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !disabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: MameroomRadius.cardRadius,
          child: MameroomCard(
            selected: selected,
            disabled: disabled,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
