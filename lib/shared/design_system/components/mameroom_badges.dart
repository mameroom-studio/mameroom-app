import 'package:flutter/material.dart';

import '../tokens/mameroom_colors.dart';
import '../tokens/mameroom_radius.dart';
import '../tokens/mameroom_spacing.dart';

enum MameroomBadgeVariant {
  active,
  warning,
  error,
  info,
  success,
  neutral,
  selected,
  disabled,
}

class MameroomStatusBadge extends StatelessWidget {
  const MameroomStatusBadge({
    super.key,
    required this.label,
    this.variant = MameroomBadgeVariant.neutral,
  });

  final String label;
  final MameroomBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final color = _variantColor(variant);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MameroomSpacing.sm,
        vertical: MameroomSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: variant == MameroomBadgeVariant.disabled ? 0.10 : 0.16,
        ),
        borderRadius: MameroomRadius.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MameroomLevelBadge extends StatelessWidget {
  const MameroomLevelBadge({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return MameroomStatusBadge(
      label: 'Lv.$level',
      variant: MameroomBadgeVariant.selected,
    );
  }
}

class MameroomTypeChip extends StatelessWidget {
  const MameroomTypeChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class MameroomCategoryChip extends MameroomTypeChip {
  const MameroomCategoryChip({
    super.key,
    required super.label,
    super.selected,
    super.onSelected,
  });
}

class MameroomFilterChip extends StatelessWidget {
  const MameroomFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

Color _variantColor(MameroomBadgeVariant variant) => switch (variant) {
  MameroomBadgeVariant.active => MameroomColors.success,
  MameroomBadgeVariant.warning => MameroomColors.warning,
  MameroomBadgeVariant.error => MameroomColors.error,
  MameroomBadgeVariant.info => MameroomColors.info,
  MameroomBadgeVariant.success => MameroomColors.success,
  MameroomBadgeVariant.neutral => MameroomColors.gray700,
  MameroomBadgeVariant.selected => MameroomColors.primary,
  MameroomBadgeVariant.disabled => MameroomColors.gray500,
};
