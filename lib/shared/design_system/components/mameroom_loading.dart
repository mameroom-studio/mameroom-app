import 'package:flutter/material.dart';

import '../tokens/mameroom_colors.dart';
import '../tokens/mameroom_radius.dart';
import '../tokens/mameroom_spacing.dart';

class MameroomSpinner extends StatelessWidget {
  const MameroomSpinner({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CircularProgressIndicator(strokeWidth: 3),
    );
  }
}

class MameroomLoadingDots extends StatelessWidget {
  const MameroomLoadingDots({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: MameroomColors.primary,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class MameroomSkeleton extends StatelessWidget {
  const MameroomSkeleton({
    super.key,
    this.height = 18,
    this.width,
    this.radius = MameroomRadius.medium,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: MameroomColors.primaryMist.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class MameroomShimmer extends StatelessWidget {
  const MameroomShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 900),
      opacity: 0.72,
      child: child,
    );
  }
}

class MameroomSeedPulse extends StatelessWidget {
  const MameroomSeedPulse({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MameroomColors.success.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.eco_rounded, color: MameroomColors.success),
    );
  }
}

class MameroomLoadingListSkeleton extends StatelessWidget {
  const MameroomLoadingListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: MameroomSpacing.sm),
          child: Row(
            children: const [
              MameroomSkeleton(
                width: 42,
                height: 42,
                radius: MameroomRadius.large,
              ),
              SizedBox(width: MameroomSpacing.sm),
              Expanded(child: MameroomSkeleton(height: 14)),
            ],
          ),
        );
      }),
    );
  }
}
