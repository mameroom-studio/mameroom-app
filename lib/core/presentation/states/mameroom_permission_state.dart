import 'package:flutter/material.dart';

import 'mameroom_state_view.dart';

class MameroomPermissionState extends StatelessWidget {
  const MameroomPermissionState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onAllow,
    this.size = MameroomStateSize.medium,
  });

  factory MameroomPermissionState.camera({VoidCallback? onAllow}) {
    return MameroomPermissionState(
      title: '\uCE74\uBA54\uB77C \uAD8C\uD55C',
      description:
          '\uCE74\uBA54\uB77C \uC0AC\uC6A9 \uAD8C\uD55C\uC774 \uD544\uC694\uD569\uB2C8\uB2E4.',
      icon: MameroomStatePixelIcon.camera,
      onAllow: onAllow,
    );
  }

  factory MameroomPermissionState.photos({VoidCallback? onAllow}) {
    return MameroomPermissionState(
      title: '\uC0AC\uC9C4 \uAD8C\uD55C',
      description:
          '\uC0AC\uC9C4 \uC811\uADFC \uAD8C\uD55C\uC774 \uD544\uC694\uD569\uB2C8\uB2E4.',
      icon: MameroomStatePixelIcon.image,
      onAllow: onAllow,
    );
  }

  factory MameroomPermissionState.notifications({VoidCallback? onAllow}) {
    return MameroomPermissionState(
      title: '\uC54C\uB9BC \uAD8C\uD55C',
      description:
          '\uC911\uC694\uD55C \uC18C\uC2DD\uC744 \uB193\uCE58\uC9C0 \uC54A\uB3C4\uB85D \uD5C8\uC6A9\uD574\uC8FC\uC138\uC694.',
      icon: MameroomStatePixelIcon.bell,
      onAllow: onAllow,
    );
  }

  factory MameroomPermissionState.storage({VoidCallback? onAllow}) {
    return MameroomPermissionState(
      title: '\uC800\uC7A5\uC18C \uAD8C\uD55C',
      description:
          '\uD30C\uC77C \uC800\uC7A5\uC744 \uC704\uD574 \uC800\uC7A5\uC18C \uAD8C\uD55C\uC774 \uD544\uC694\uD569\uB2C8\uB2E4.',
      icon: MameroomStatePixelIcon.folder,
      onAllow: onAllow,
    );
  }

  final String title;
  final String description;
  final MameroomStatePixelIcon icon;
  final VoidCallback? onAllow;
  final MameroomStateSize size;

  @override
  Widget build(BuildContext context) {
    return MameroomStateView(
      variant: MameroomStateVariant.permission,
      title: title,
      description: description,
      pixelIcon: icon,
      primaryButtonText: '\uD5C8\uC6A9\uD558\uAE30',
      onPrimaryPressed: onAllow,
      size: size,
    );
  }
}
