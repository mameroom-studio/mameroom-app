import 'package:flutter/material.dart';

import 'mameroom_state_view.dart';

class MameroomProcessingState extends StatelessWidget {
  const MameroomProcessingState({
    super.key,
    required this.title,
    required this.description,
    this.progress,
    this.icon = MameroomStatePixelIcon.robot,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.size = MameroomStateSize.medium,
  });

  factory MameroomProcessingState.pdfUploading({double progress = 0.45}) {
    return MameroomProcessingState(
      title: 'PDF \uC5C5\uB85C\uB4DC \uC911',
      description:
          '\uC790\uB8CC\uB97C \uC548\uC804\uD558\uAC8C \uC62C\uB9AC\uACE0 \uC788\uC5B4\uC694.',
      progress: progress,
      icon: MameroomStatePixelIcon.document,
    );
  }

  factory MameroomProcessingState.pdfAnalyzing({double progress = 0.72}) {
    return MameroomProcessingState(
      title: 'PDF \uBD84\uC11D \uC911',
      description:
          'AI\uAC00 \uC790\uB8CC\uB97C \uBD84\uC11D\uD558\uACE0 \uC788\uC5B4\uC694.',
      progress: progress,
      icon: MameroomStatePixelIcon.robot,
    );
  }

  factory MameroomProcessingState.quizGenerating({double progress = 0.60}) {
    return MameroomProcessingState(
      title: '\uBB38\uC81C \uC0DD\uC131 \uC911',
      description:
          '\uD559\uC2B5\uC5D0 \uB9DE\uB294 \uBB38\uC81C\uB97C \uB9CC\uB4E4\uACE0 \uC788\uC5B4\uC694.',
      progress: progress,
      icon: MameroomStatePixelIcon.book,
    );
  }

  factory MameroomProcessingState.seedGrowth({double progress = 0.60}) {
    return MameroomProcessingState(
      title: '\uC528\uC557 \uC131\uC7A5 \uC911',
      description:
          '\uAE30\uC5B5\uC528\uC557\uC774 \uC790\uB77C\uACE0 \uC788\uC5B4\uC694. 3\uB2E8\uACC4 / 5\uB2E8\uACC4',
      progress: progress,
      icon: MameroomStatePixelIcon.seedling,
    );
  }

  final String title;
  final String description;
  final double? progress;
  final MameroomStatePixelIcon icon;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final MameroomStateSize size;

  @override
  Widget build(BuildContext context) {
    return MameroomStateView(
      variant: MameroomStateVariant.processing,
      title: title,
      description: description,
      pixelIcon: icon,
      progress: progress,
      showProgress: true,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      size: size,
    );
  }
}
