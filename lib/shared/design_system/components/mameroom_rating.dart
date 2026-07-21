import 'package:flutter/material.dart';

import '../tokens/mameroom_colors.dart';
import 'mameroom_progress.dart';

class MameroomStarRating extends StatelessWidget {
  const MameroomStarRating({super.key, required this.value, this.max = 5});

  final double value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (index) {
        return Icon(
          index < value.round()
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          color: MameroomColors.warning,
          size: 20,
        );
      }),
    );
  }
}

class MameroomStatBar extends StatelessWidget {
  const MameroomStatBar({super.key, required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return MameroomProgressBar(value: value, label: label, compact: true);
  }
}
