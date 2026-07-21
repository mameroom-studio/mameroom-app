import 'package:flutter/material.dart';

import 'mameroom_state_view.dart';

class MameroomSuccessState extends StatelessWidget {
  const MameroomSuccessState({
    super.key,
    required this.title,
    required this.description,
    this.primaryButtonText = '\uD655\uC778',
    this.onPrimaryPressed,
    this.icon = MameroomStatePixelIcon.seedling,
    this.size = MameroomStateSize.medium,
  });

  factory MameroomSuccessState.uploadComplete({VoidCallback? onConfirm}) {
    return MameroomSuccessState(
      title: '\uC790\uB8CC \uC5C5\uB85C\uB4DC \uC644\uB8CC!',
      description:
          '\uC790\uB8CC \uC5C5\uB85C\uB4DC\uAC00 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.',
      icon: MameroomStatePixelIcon.document,
      onPrimaryPressed: onConfirm,
    );
  }

  factory MameroomSuccessState.analysisComplete({VoidCallback? onConfirm}) {
    return MameroomSuccessState(
      title: '\uBD84\uC11D \uC644\uB8CC!',
      description:
          'AI\uAC00 \uD559\uC2B5 \uD575\uC2EC\uC744 \uCC3E\uC558\uC5B4\uC694.',
      icon: MameroomStatePixelIcon.robot,
      onPrimaryPressed: onConfirm,
    );
  }

  factory MameroomSuccessState.quizGenerated({VoidCallback? onStart}) {
    return MameroomSuccessState(
      title: '\uBB38\uC81C\uAC00 \uC0DD\uC131\uB418\uC5C8\uC2B5\uB2C8\uB2E4!',
      description:
          '\uC9C0\uAE08 \uBC14\uB85C \uD559\uC2B5\uC744 \uC2DC\uC791\uD574\uBCF4\uC138\uC694.',
      icon: MameroomStatePixelIcon.book,
      primaryButtonText: '\uACF5\uBD80 \uC2DC\uC791\uD558\uAE30',
      onPrimaryPressed: onStart,
    );
  }

  factory MameroomSuccessState.purchaseComplete({VoidCallback? onDecorate}) {
    return MameroomSuccessState(
      title: '\uAD6C\uB9E4 \uC644\uB8CC!',
      description:
          '\uC544\uC774\uD15C\uC774 \uB0B4 \uBC29\uC73C\uB85C \uC9C0\uAE09\uB418\uC5C8\uC2B5\uB2C8\uB2E4.',
      icon: MameroomStatePixelIcon.shop,
      primaryButtonText: '\uBC29 \uAFB8\uBBF8\uB7EC \uAC00\uAE30',
      onPrimaryPressed: onDecorate,
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
      variant: MameroomStateVariant.success,
      title: title,
      description: description,
      pixelIcon: icon,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      size: size,
    );
  }
}
