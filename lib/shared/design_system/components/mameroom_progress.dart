import 'package:flutter/material.dart';

import '../tokens/mameroom_colors.dart';
import '../tokens/mameroom_radius.dart';
import '../tokens/mameroom_spacing.dart';

class MameroomProgressBar extends StatelessWidget {
  const MameroomProgressBar({
    super.key,
    required this.value,
    this.label,
    this.color = MameroomColors.primary,
    this.compact = false,
  });

  final double value;
  final String? label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: MameroomSpacing.xxs),
        ],
        ClipRRect(
          borderRadius: MameroomRadius.pillRadius,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 220),
            builder: (context, animatedValue, _) => LinearProgressIndicator(
              value: animatedValue,
              minHeight: compact ? 6 : 10,
              color: color,
              backgroundColor: MameroomColors.primaryMist,
            ),
          ),
        ),
      ],
    );
  }
}

class MameroomSeedGrowthBar extends MameroomProgressBar {
  const MameroomSeedGrowthBar({super.key, required super.value, super.label})
    : super(color: MameroomColors.success);
}

class MameroomStepIndicator extends StatelessWidget {
  const MameroomStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index == totalSteps - 1 ? 0 : MameroomSpacing.xs,
            ),
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? MameroomColors.primary
                  : MameroomColors.primaryMist,
              borderRadius: MameroomRadius.pillRadius,
            ),
          ),
        );
      }),
    );
  }
}

class MameroomPageIndicator extends StatelessWidget {
  const MameroomPageIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 10 : 7,
          height: active ? 10 : 7,
          decoration: BoxDecoration(
            color: active ? MameroomColors.primary : MameroomColors.primaryMist,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class MameroomSegmentedControl<T> extends StatelessWidget {
  const MameroomSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: segments.entries
          .map(
            (entry) =>
                ButtonSegment<T>(value: entry.key, label: Text(entry.value)),
          )
          .toList(),
      selected: {selected},
      onSelectionChanged: (value) => onSelected(value.first),
    );
  }
}
