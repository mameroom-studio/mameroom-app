import 'package:flutter/material.dart';

import 'mameroom_state_view.dart';

class MameroomErrorState extends StatelessWidget {
  const MameroomErrorState({
    super.key,
    required this.title,
    required this.description,
    this.primaryButtonText = '\uB2E4\uC2DC \uC2DC\uB3C4',
    this.onPrimaryPressed,
    this.icon = MameroomStatePixelIcon.error,
    this.size = MameroomStateSize.medium,
  });

  factory MameroomErrorState.network({VoidCallback? onRetry}) {
    return MameroomErrorState(
      title: '\uC5F0\uACB0\uC774 \uBD88\uC548\uC815\uD574\uC694',
      description:
          '\uC778\uD130\uB137 \uC5F0\uACB0\uC744 \uD655\uC778\uD558\uACE0 \uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.',
      icon: MameroomStatePixelIcon.wifi,
      onPrimaryPressed: onRetry,
    );
  }

  factory MameroomErrorState.analysisFailed({VoidCallback? onRetry}) {
    return MameroomErrorState(
      title: '\uBD84\uC11D\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4.',
      description:
          '\uC790\uB8CC \uD615\uC2DD\uC744 \uD655\uC778\uD558\uACE0 \uB2E4\uC2DC \uBD84\uC11D\uD574\uC8FC\uC138\uC694.',
      icon: MameroomStatePixelIcon.robot,
      primaryButtonText: '\uB2E4\uC2DC \uBD84\uC11D\uD558\uAE30',
      onPrimaryPressed: onRetry,
    );
  }

  factory MameroomErrorState.quizGenerationFailed({VoidCallback? onRetry}) {
    return MameroomErrorState(
      title: '\uBB38\uC81C \uC0DD\uC131 \uC2E4\uD328',
      description:
          '\uBB38\uC81C \uC0DD\uC131 \uC911 \uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC5B4\uC694.',
      icon: MameroomStatePixelIcon.document,
      onPrimaryPressed: onRetry,
    );
  }

  factory MameroomErrorState.uploadFailed({VoidCallback? onRetry}) {
    return MameroomErrorState(
      title: '\uC5C5\uB85C\uB4DC \uC2E4\uD328',
      description:
          '\uC790\uB8CC \uC5C5\uB85C\uB4DC\uC5D0 \uC2E4\uD328\uD588\uC5B4\uC694.',
      icon: MameroomStatePixelIcon.document,
      primaryButtonText: '\uB2E4\uC2DC \uC5C5\uB85C\uB4DC',
      onPrimaryPressed: onRetry,
    );
  }

  factory MameroomErrorState.maintenance() {
    return const MameroomErrorState(
      title: '\uC7A0\uC2DC \uC810\uAC80 \uC911\uC785\uB2C8\uB2E4.',
      description: '\uC870\uAE08\uB9CC \uAE30\uB2E4\uB824\uC8FC\uC138\uC694.',
      icon: MameroomStatePixelIcon.warning,
      primaryButtonText: null,
    );
  }

  final String title;
  final String description;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final MameroomStatePixelIcon icon;
  final MameroomStateSize size;

  @override
  Widget build(BuildContext context) {
    return MameroomStateView(
      variant: MameroomStateVariant.error,
      title: title,
      description: description,
      pixelIcon: icon,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      size: size,
    );
  }
}
