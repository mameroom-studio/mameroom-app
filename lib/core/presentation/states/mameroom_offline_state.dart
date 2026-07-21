import 'package:flutter/material.dart';

import 'mameroom_state_view.dart';

class MameroomOfflineState extends StatelessWidget {
  const MameroomOfflineState({
    super.key,
    this.onRetry,
    this.size = MameroomStateSize.medium,
  });

  final VoidCallback? onRetry;
  final MameroomStateSize size;

  @override
  Widget build(BuildContext context) {
    return MameroomStateView(
      variant: MameroomStateVariant.offline,
      title: '\uC778\uD130\uB137 \uC5F0\uACB0\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      description:
          '\uC778\uD130\uB137 \uC5C6\uC774\uB3C4 \uAE30\uC874 \uD559\uC2B5\uC740 \uACC4\uC18D\uD560 \uC218 \uC788\uC5B4\uC694.',
      pixelIcon: MameroomStatePixelIcon.wifi,
      primaryButtonText: '\uC7AC\uC5F0\uACB0 \uC2DC\uB3C4',
      onPrimaryPressed: onRetry,
      size: size,
    );
  }
}
