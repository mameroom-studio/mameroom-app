import 'package:flutter/material.dart';

import '../tokens/mameroom_icon_sizes.dart';

enum MameroomIconCategory { general, action, status, item }

class MameroomIcon extends StatelessWidget {
  const MameroomIcon({
    super.key,
    required this.icon,
    this.size = MameroomIconSizes.md,
    this.semanticLabel,
    this.color,
  });

  final IconData icon;
  final double size;
  final String? semanticLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: Icon(icon, size: size, color: color),
    );
  }
}
