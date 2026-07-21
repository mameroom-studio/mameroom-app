import 'package:flutter/material.dart';

import 'mameroom_modal_theme.dart';

class MameroomModalIcon extends StatelessWidget {
  const MameroomModalIcon({
    super.key,
    required this.variant,
    this.icon,
    this.size = 76,
  });

  final MameroomModalVariant variant;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = variant.palette(context);
    final iconData = icon ?? palette.iconData;
    return SizedBox(
      width: size + 30,
      height: size + 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            top: 8,
            child: _Sparkle(color: palette.accent.withValues(alpha: 0.42)),
          ),
          Positioned(
            right: 8,
            top: 17,
            child: _Sparkle(color: palette.accent.withValues(alpha: 0.34)),
          ),
          Positioned(
            right: 26,
            bottom: 5,
            child: _Sparkle(color: palette.accent.withValues(alpha: 0.26)),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: palette.soft,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          Container(
            width: size * 0.74,
            height: size * 0.74,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: 2,
              ),
            ),
            child: Icon(iconData, color: Colors.white, size: size * 0.42),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome_rounded, color: color, size: 14);
  }
}
