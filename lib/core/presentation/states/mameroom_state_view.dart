import 'package:flutter/material.dart';

import '../../../shared/design_system/theme/mameroom_theme_extension.dart';

enum MameroomStateVariant {
  empty,
  loading,
  processing,
  error,
  success,
  offline,
  permission,
  search,
  warning,
  info,
}

enum MameroomStateSize { compact, medium, full }

enum MameroomStatePixelIcon {
  seed,
  seedling,
  book,
  document,
  room,
  friends,
  bell,
  wifi,
  robot,
  gift,
  chest,
  warning,
  error,
  camera,
  image,
  folder,
  search,
  shop,
  question,
}

class MameroomStateView extends StatelessWidget {
  const MameroomStateView({
    super.key,
    required this.variant,
    required this.title,
    required this.description,
    this.pixelIcon,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.progress,
    this.showProgress = false,
    this.size = MameroomStateSize.medium,
    this.customContent,
    this.suggestionChips = const [],
    this.onChipPressed,
  });

  final MameroomStateVariant variant;
  final String title;
  final String description;
  final MameroomStatePixelIcon? pixelIcon;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final double? progress;
  final bool showProgress;
  final MameroomStateSize size;
  final Widget? customContent;
  final List<String> suggestionChips;
  final ValueChanged<String>? onChipPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final spec = _StateSpec.of(variant, colors);
    final metrics = _Metrics.of(size);
    final icon = pixelIcon ?? spec.icon;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(240.0, 420.0).toDouble()
            : 360.0;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: EdgeInsets.all(metrics.padding),
              decoration: BoxDecoration(
                color: colors.paper,
                border: Border.all(color: spec.borderColor),
                borderRadius: BorderRadius.circular(metrics.radius),
                boxShadow: [
                  BoxShadow(
                    color: spec.color.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: size == MameroomStateSize.full
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SparkleIcon(
                    icon: icon,
                    color: spec.color,
                    size: metrics.iconSize,
                    animate:
                        variant == MameroomStateVariant.loading ||
                        variant == MameroomStateVariant.processing,
                  ),
                  SizedBox(height: metrics.gap),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: size == MameroomStateSize.compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      fontSize: metrics.titleSize,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: metrics.smallGap),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      maxLines: size == MameroomStateSize.compact ? 2 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                        fontSize: metrics.bodySize,
                      ),
                    ),
                  ],
                  if (showProgress) ...[
                    SizedBox(height: metrics.gap),
                    _StateProgress(value: progress, color: spec.color),
                  ],
                  if (suggestionChips.isNotEmpty) ...[
                    SizedBox(height: metrics.gap),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final chip in suggestionChips)
                          ActionChip(
                            label: Text(chip),
                            onPressed: onChipPressed == null
                                ? null
                                : () => onChipPressed!(chip),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  if (customContent != null) ...[
                    SizedBox(height: metrics.gap),
                    customContent!,
                  ],
                  if (primaryButtonText != null ||
                      secondaryButtonText != null) ...[
                    SizedBox(height: metrics.buttonGap),
                    _StateButtons(
                      primaryText: primaryButtonText,
                      secondaryText: secondaryButtonText,
                      onPrimary: onPrimaryPressed,
                      onSecondary: onSecondaryPressed,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StateButtons extends StatelessWidget {
  const _StateButtons({
    required this.primaryText,
    required this.secondaryText,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String? primaryText;
  final String? secondaryText;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (secondaryText != null) {
      children.add(
        Expanded(
          child: OutlinedButton(
            onPressed: onSecondary,
            child: Text(secondaryText!),
          ),
        ),
      );
    }
    if (primaryText != null) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 10));
      children.add(
        Expanded(
          child: FilledButton(onPressed: onPrimary, child: Text(primaryText!)),
        ),
      );
    }
    return Row(children: children);
  }
}

class _StateProgress extends StatelessWidget {
  const _StateProgress({required this.value, required this.color});

  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final safeValue = value?.clamp(0.0, 1.0).toDouble();
    return Column(
      children: [
        LinearProgressIndicator(
          value: safeValue,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
          backgroundColor: color.withValues(alpha: 0.18),
          color: color,
        ),
        if (safeValue != null) ...[
          const SizedBox(height: 6),
          Text(
            '${(safeValue * 100).round()}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.mameroom.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _SparkleIcon extends StatelessWidget {
  const _SparkleIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.animate,
  });

  final MameroomStatePixelIcon icon;
  final Color color;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: size + 40,
      height: size + 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 7,
            left: 12,
            child: _Sparkle(color: color.withValues(alpha: 0.45), size: 8),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: _Sparkle(color: color.withValues(alpha: 0.32), size: 11),
          ),
          _PixelStateIcon(icon: icon, color: color, size: size),
        ],
      ),
    );
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.04),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, scale, _) =>
          Transform.scale(scale: scale, child: child),
      onEnd: () {},
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome_rounded, color: color, size: size);
  }
}

class _PixelStateIcon extends StatelessWidget {
  const _PixelStateIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final MameroomStatePixelIcon icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconData = _iconData(icon);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: size * 0.18,
            bottom: size * 0.16,
            child: Container(
              width: size * 0.26,
              height: size * 0.10,
              color: color.withValues(alpha: 0.22),
            ),
          ),
          Icon(iconData, color: color, size: size * 0.55),
        ],
      ),
    );
  }

  IconData _iconData(MameroomStatePixelIcon icon) {
    return switch (icon) {
      MameroomStatePixelIcon.seed => Icons.eco_rounded,
      MameroomStatePixelIcon.seedling => Icons.local_florist_rounded,
      MameroomStatePixelIcon.book => Icons.menu_book_rounded,
      MameroomStatePixelIcon.document => Icons.description_rounded,
      MameroomStatePixelIcon.room => Icons.bedroom_parent_rounded,
      MameroomStatePixelIcon.friends => Icons.groups_rounded,
      MameroomStatePixelIcon.bell => Icons.notifications_rounded,
      MameroomStatePixelIcon.wifi => Icons.wifi_off_rounded,
      MameroomStatePixelIcon.robot => Icons.smart_toy_rounded,
      MameroomStatePixelIcon.gift => Icons.card_giftcard_rounded,
      MameroomStatePixelIcon.chest => Icons.inventory_2_rounded,
      MameroomStatePixelIcon.warning => Icons.warning_amber_rounded,
      MameroomStatePixelIcon.error => Icons.close_rounded,
      MameroomStatePixelIcon.camera => Icons.photo_camera_rounded,
      MameroomStatePixelIcon.image => Icons.photo_rounded,
      MameroomStatePixelIcon.folder => Icons.folder_rounded,
      MameroomStatePixelIcon.search => Icons.search_rounded,
      MameroomStatePixelIcon.shop => Icons.storefront_rounded,
      MameroomStatePixelIcon.question => Icons.help_outline_rounded,
    };
  }
}

class _Metrics {
  const _Metrics({
    required this.padding,
    required this.radius,
    required this.iconSize,
    required this.gap,
    required this.smallGap,
    required this.buttonGap,
    required this.titleSize,
    required this.bodySize,
  });

  final double padding;
  final double radius;
  final double iconSize;
  final double gap;
  final double smallGap;
  final double buttonGap;
  final double titleSize;
  final double bodySize;

  static _Metrics of(MameroomStateSize size) {
    return switch (size) {
      MameroomStateSize.compact => const _Metrics(
        padding: 14,
        radius: 14,
        iconSize: 58,
        gap: 10,
        smallGap: 6,
        buttonGap: 12,
        titleSize: 15,
        bodySize: 12,
      ),
      MameroomStateSize.medium => const _Metrics(
        padding: 18,
        radius: 18,
        iconSize: 78,
        gap: 13,
        smallGap: 8,
        buttonGap: 16,
        titleSize: 18,
        bodySize: 13,
      ),
      MameroomStateSize.full => const _Metrics(
        padding: 22,
        radius: 20,
        iconSize: 96,
        gap: 16,
        smallGap: 10,
        buttonGap: 20,
        titleSize: 21,
        bodySize: 14,
      ),
    };
  }
}

class _StateSpec {
  const _StateSpec({
    required this.color,
    required this.borderColor,
    required this.icon,
  });

  final Color color;
  final Color borderColor;
  final MameroomStatePixelIcon icon;

  static _StateSpec of(MameroomStateVariant variant, MameroomTheme colors) {
    final color = switch (variant) {
      MameroomStateVariant.success => const Color(0xFF7ED957),
      MameroomStateVariant.loading => const Color(0xFF8B61FF),
      MameroomStateVariant.processing => const Color(0xFF8B61FF),
      MameroomStateVariant.warning => const Color(0xFFFFB54D),
      MameroomStateVariant.error => const Color(0xFFFF6B6B),
      MameroomStateVariant.offline => const Color(0xFF9AA0A6),
      MameroomStateVariant.permission => const Color(0xFFFFB54D),
      MameroomStateVariant.search => colors.primary,
      MameroomStateVariant.info => colors.primary,
      MameroomStateVariant.empty => colors.primary,
    };
    final icon = switch (variant) {
      MameroomStateVariant.success => MameroomStatePixelIcon.seedling,
      MameroomStateVariant.loading => MameroomStatePixelIcon.seed,
      MameroomStateVariant.processing => MameroomStatePixelIcon.robot,
      MameroomStateVariant.warning => MameroomStatePixelIcon.warning,
      MameroomStateVariant.error => MameroomStatePixelIcon.error,
      MameroomStateVariant.offline => MameroomStatePixelIcon.wifi,
      MameroomStateVariant.permission => MameroomStatePixelIcon.folder,
      MameroomStateVariant.search => MameroomStatePixelIcon.search,
      MameroomStateVariant.info => MameroomStatePixelIcon.question,
      MameroomStateVariant.empty => MameroomStatePixelIcon.seed,
    };
    return _StateSpec(
      color: color,
      borderColor: color.withValues(alpha: 0.24),
      icon: icon,
    );
  }
}
