import 'package:flutter/material.dart';

import 'mameroom_state_view.dart';

class MameroomEmptyState extends StatelessWidget {
  const MameroomEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = MameroomStatePixelIcon.seed,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.size = MameroomStateSize.medium,
  });

  factory MameroomEmptyState.studyMaterials({
    VoidCallback? onUpload,
    MameroomStateSize size = MameroomStateSize.medium,
  }) {
    return MameroomEmptyState(
      title:
          '\uC544\uC9C1 \uD559\uC2B5 \uC790\uB8CC\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
      description:
          '\uCCAB \uC790\uB8CC\uB97C \uC5C5\uB85C\uB4DC\uD558\uACE0 \uAE30\uC5B5\uC528\uC557\uC744 \uD0A4\uC6CC\uBCF4\uC138\uC694.',
      icon: MameroomStatePixelIcon.book,
      primaryButtonText: '\uC790\uB8CC \uC5C5\uB85C\uB4DC\uD558\uAE30',
      onPrimaryPressed: onUpload,
      size: size,
    );
  }

  factory MameroomEmptyState.friends({
    VoidCallback? onInvite,
    MameroomStateSize size = MameroomStateSize.medium,
  }) {
    return MameroomEmptyState(
      title:
          '\uC544\uC9C1 \uD568\uAED8 \uACF5\uBD80\uD558\uB294 \uCE5C\uAD6C\uAC00 \uC5C6\uC5B4\uC694.',
      description:
          '\uCE5C\uAD6C\uB97C \uCD08\uB300\uD558\uACE0 \uD568\uAED8 \uC131\uC7A5\uD574\uBCF4\uC138\uC694.',
      icon: MameroomStatePixelIcon.friends,
      primaryButtonText: '\uCE5C\uAD6C \uCD08\uB300\uD558\uAE30',
      onPrimaryPressed: onInvite,
      size: size,
    );
  }

  factory MameroomEmptyState.room({
    VoidCallback? onShop,
    MameroomStateSize size = MameroomStateSize.medium,
  }) {
    return MameroomEmptyState(
      title: '\uBE48 \uBC29',
      description:
          '\uCCAB \uC544\uC774\uD15C\uC73C\uB85C \uBC29\uC744 \uAFB8\uBA70\uBCF4\uC138\uC694.',
      icon: MameroomStatePixelIcon.room,
      primaryButtonText: '\uC0C1\uC810 \uAC00\uAE30',
      onPrimaryPressed: onShop,
      size: size,
    );
  }

  factory MameroomEmptyState.seeds({
    MameroomStateSize size = MameroomStateSize.medium,
  }) {
    return MameroomEmptyState(
      title:
          '\uC544\uC9C1 \uC790\uB77C\uACE0 \uC788\uB294 \uAE30\uC5B5\uC528\uC557\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      description:
          '\uACF5\uBD80\uB97C \uC2DC\uC791\uD558\uBA74 \uAE30\uC5B5\uC528\uC557\uC774 \uC790\uB77C\uC694.',
      icon: MameroomStatePixelIcon.seed,
      size: size,
    );
  }

  factory MameroomEmptyState.notifications({
    MameroomStateSize size = MameroomStateSize.medium,
  }) {
    return MameroomEmptyState(
      title: '\uC0C8\uB85C\uC6B4 \uC54C\uB9BC\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      description:
          '\uC911\uC694\uD55C \uC18C\uC2DD\uC774 \uC788\uC744 \uB54C \uC5EC\uAE30\uC5D0 \uC54C\uB824\uB4DC\uB9B4\uAC8C\uC694.',
      icon: MameroomStatePixelIcon.bell,
      size: size,
    );
  }

  final String title;
  final String description;
  final MameroomStatePixelIcon icon;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final MameroomStateSize size;

  @override
  Widget build(BuildContext context) {
    return MameroomStateView(
      variant: MameroomStateVariant.empty,
      title: title,
      description: description,
      pixelIcon: icon,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      size: size,
    );
  }
}
