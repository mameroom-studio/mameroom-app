import 'package:flutter/material.dart';

import '../../../shared/design_system/theme/mameroom_theme_extension.dart';

enum MameroomSkeletonType { list, room, shopGrid, profile, ranking, quiz }

class MameroomSkeleton extends StatelessWidget {
  const MameroomSkeleton({
    super.key,
    this.type = MameroomSkeletonType.list,
    this.itemCount = 4,
  });

  final MameroomSkeletonType type;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      MameroomSkeletonType.room => _RoomSkeleton(),
      MameroomSkeletonType.shopGrid => _ShopGridSkeleton(itemCount: itemCount),
      MameroomSkeletonType.profile => const _ProfileSkeleton(),
      MameroomSkeletonType.ranking => _ListSkeleton(
        itemCount: itemCount,
        avatar: true,
      ),
      MameroomSkeletonType.quiz => const _QuizSkeleton(),
      MameroomSkeletonType.list => _ListSkeleton(itemCount: itemCount),
    };
  }
}

class MameroomShimmerCard extends StatelessWidget {
  const MameroomShimmerCard({
    super.key,
    this.height = 84,
    this.width,
    this.borderRadius = 14,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.25, end: 0.80),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: [
                colors.primaryMist.withValues(alpha: 0.30),
                colors.primaryMist.withValues(alpha: value),
                colors.primaryMist.withValues(alpha: 0.30),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.itemCount, this.avatar = false});

  final int itemCount;
  final bool avatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          Row(
            children: [
              if (avatar) ...[
                const MameroomShimmerCard(
                  width: 46,
                  height: 46,
                  borderRadius: 14,
                ),
                const SizedBox(width: 10),
              ],
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MameroomShimmerCard(height: 14),
                    SizedBox(height: 8),
                    MameroomShimmerCard(height: 12),
                  ],
                ),
              ),
            ],
          ),
          if (i != itemCount - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _RoomSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        MameroomShimmerCard(height: 210, borderRadius: 20),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: MameroomShimmerCard(height: 74)),
            SizedBox(width: 10),
            Expanded(child: MameroomShimmerCard(height: 74)),
          ],
        ),
      ],
    );
  }
}

class _ShopGridSkeleton extends StatelessWidget {
  const _ShopGridSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 160,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, _) => const MameroomShimmerCard(height: 160),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        MameroomShimmerCard(width: 72, height: 72, borderRadius: 22),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MameroomShimmerCard(height: 18),
              SizedBox(height: 10),
              MameroomShimmerCard(height: 14),
              SizedBox(height: 10),
              MameroomShimmerCard(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuizSkeleton extends StatelessWidget {
  const _QuizSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MameroomShimmerCard(height: 120),
        SizedBox(height: 14),
        MameroomShimmerCard(height: 48),
        SizedBox(height: 8),
        MameroomShimmerCard(height: 48),
        SizedBox(height: 8),
        MameroomShimmerCard(height: 48),
      ],
    );
  }
}
