import 'package:flutter/material.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';

class StudyCard extends StatelessWidget {
  const StudyCard({required this.child, this.padding = const EdgeInsets.all(22), super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class StudyPrimaryButton extends StatelessWidget {
  const StudyPrimaryButton({required this.label, required this.onPressed, this.icon, super.key});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class MemoryGauge extends StatelessWidget {
  const MemoryGauge({required this.value, this.compact = false, super.key});

  final double value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final percent = (value.clamp(0, 1) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('기억률', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.muted)),
            const SizedBox(width: 5),
            Text('$percent%', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.ink)),
            const Spacer(),
            if (!compact) const Text('🌱'),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: compact ? 8 : 10,
            color: percent >= 85 ? colors.sun : colors.primary,
            backgroundColor: colors.primaryMist.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class StudyBottomActionBar extends StatelessWidget {
  const StudyBottomActionBar({
    required this.memoryValue,
    required this.onPass,
    required this.onBookmark,
    super.key,
  });

  final double memoryValue;
  final VoidCallback onPass;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SafeArea(
      top: false,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: Row(
        children: [
          Expanded(
            child: _BarButton(icon: Icons.skip_next_outlined, label: 'PASS', onTap: onPass),
          ),
          VerticalDivider(width: 1, color: colors.line),
          Expanded(
            child: _BarButton(icon: Icons.star_border_rounded, label: '북마크', onTap: onBookmark),
          ),
          VerticalDivider(width: 1, color: colors.line),
          Expanded(
            child: _BarButton(icon: Icons.spa_outlined, label: '${(memoryValue * 100).round()}%', onTap: () {}),
          ),
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colors.primary, size: 24),
          const SizedBox(height: 5),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.ink, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
