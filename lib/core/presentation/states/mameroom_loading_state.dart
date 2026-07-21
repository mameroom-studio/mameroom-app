import 'package:flutter/material.dart';

import 'mameroom_skeleton.dart';
import 'mameroom_state_view.dart';

class MameroomLoadingState extends StatelessWidget {
  const MameroomLoadingState({
    super.key,
    this.title = '\uB85C\uB529 \uC911...',
    this.description =
        '\uC7A0\uC2DC\uB9CC \uAE30\uB2E4\uB824\uC8FC\uC138\uC694.',
    this.skeletonType,
    this.size = MameroomStateSize.medium,
  });

  factory MameroomLoadingState.studyMaterials() => const MameroomLoadingState(
    title: '\uD559\uC2B5 \uC790\uB8CC \uB85C\uB529',
    description:
        '\uC790\uB8CC\uB97C \uAC00\uC838\uC624\uACE0 \uC788\uC5B4\uC694.',
    skeletonType: MameroomSkeletonType.list,
  );

  factory MameroomLoadingState.room() => const MameroomLoadingState(
    title: '\uBC29 \uB85C\uB529',
    description:
        '\uB0B4 \uBC29\uC744 \uC900\uBE44\uD558\uACE0 \uC788\uC5B4\uC694.',
    skeletonType: MameroomSkeletonType.room,
  );

  factory MameroomLoadingState.shop() => const MameroomLoadingState(
    title: '\uC0C1\uC810 \uB85C\uB529',
    description:
        '\uC624\uB298\uC758 \uC544\uC774\uD15C\uC744 \uAEBC\uB0B4\uACE0 \uC788\uC5B4\uC694.',
    skeletonType: MameroomSkeletonType.shopGrid,
  );

  factory MameroomLoadingState.profile() => const MameroomLoadingState(
    title: '\uD504\uB85C\uD544 \uB85C\uB529',
    description:
        '\uD559\uC2B5 \uD604\uD669\uC744 \uBD88\uB7EC\uC624\uACE0 \uC788\uC5B4\uC694.',
    skeletonType: MameroomSkeletonType.profile,
  );

  factory MameroomLoadingState.ranking() => const MameroomLoadingState(
    title: '\uB7AD\uD0B9 \uB85C\uB529',
    description:
        '\uCE5C\uAD6C\uB4E4\uC758 \uD559\uC2B5 \uD604\uD669\uC744 \uBD88\uB7EC\uC624\uACE0 \uC788\uC5B4\uC694.',
    skeletonType: MameroomSkeletonType.ranking,
  );

  factory MameroomLoadingState.quiz() => const MameroomLoadingState(
    title: '\uBB38\uC81C \uB85C\uB529',
    description:
        '\uBB38\uC81C\uB97C \uC900\uBE44\uD558\uACE0 \uC788\uC5B4\uC694.',
    skeletonType: MameroomSkeletonType.quiz,
  );

  final String title;
  final String description;
  final MameroomSkeletonType? skeletonType;
  final MameroomStateSize size;

  @override
  Widget build(BuildContext context) {
    return MameroomStateView(
      variant: MameroomStateVariant.loading,
      title: title,
      description: description,
      pixelIcon: MameroomStatePixelIcon.seed,
      size: size,
      customContent: skeletonType == null
          ? null
          : MameroomSkeleton(type: skeletonType!, itemCount: 4),
    );
  }
}
