import 'package:flutter/material.dart';

import '../../widgets/pixel_placeholders.dart';

enum MameroomCharacterExpression {
  neutral,
  happy,
  excited,
  surprised,
  confused,
  thinking,
  celebration,
}

class MameroomBrandCharacter extends StatelessWidget {
  const MameroomBrandCharacter({
    super.key,
    this.expression = MameroomCharacterExpression.neutral,
    this.size = 72,
  });

  final MameroomCharacterExpression expression;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MAMEROOM seed mascot ${expression.name}',
      image: true,
      child: PixelSeed(size: size),
    );
  }
}
