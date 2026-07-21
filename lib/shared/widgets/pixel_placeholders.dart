import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../design_system/theme/mameroom_theme_extension.dart';

class PixelLogo extends StatelessWidget {
  const PixelLogo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 122.0 : 178.0;
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        AppAssets.mameroomIcon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class PixelSeed extends StatelessWidget {
  const PixelSeed({this.size = 64, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SeedPainter(context.mameroom)),
    );
  }
}

class PixelLamp extends StatelessWidget {
  const PixelLamp({this.size = 92, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LampPainter(colors)),
    );
  }
}

class PixelCharacter extends StatelessWidget {
  const PixelCharacter({this.size = 120, this.streak, super.key});

  final double size;
  final int? streak;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.35,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomPaint(
            size: Size(size, size * 1.35),
            painter: _CharacterPainter(context.mameroom),
          ),
          if (streak != null)
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.mameroom.sun,
                  border: Border.all(color: context.mameroom.wood, width: 2),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '🔥 $streak',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.mameroom.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PixelRoomScene extends StatelessWidget {
  const PixelRoomScene({
    this.progress,
    this.showFurniture = true,
    this.streak,
    super.key,
  });

  final double? progress;
  final bool showFurniture;
  final int? streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return AspectRatio(
      aspectRatio: 1.04,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoomPainter(colors, progress: progress),
            ),
          ),
          if (showFurniture) ...[
            Positioned(left: 28, top: 72, child: _PixelWindow(colors: colors)),
            Positioned(right: 32, top: 72, child: _PixelShelf(colors: colors)),
            Positioned(top: 34, child: PixelLamp(size: 54)),
            Positioned(right: 38, top: 38, child: _PixelPlant(colors: colors)),
          ],
          Positioned(
            bottom: 56,
            child: PixelCharacter(size: 82, streak: streak),
          ),
          Positioned(right: 78, bottom: 54, child: PixelSeed(size: 42)),
        ],
      ),
    );
  }
}

class PixelSeedCardArt extends StatelessWidget {
  const PixelSeedCardArt({required this.color, required this.icon, super.key});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 34),
    );
  }
}

class _PixelWindow extends StatelessWidget {
  const _PixelWindow({required this.colors});

  final MameroomTheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFDFF6FF),
        border: Border.all(color: colors.wood, width: 3),
      ),
      child: Column(
        children: [
          Expanded(child: Container(color: Colors.transparent)),
          Container(height: 3, color: colors.wood),
          Expanded(child: Container(color: Colors.transparent)),
        ],
      ),
    );
  }
}

class _PixelShelf extends StatelessWidget {
  const _PixelShelf({required this.colors});

  final MameroomTheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 92,
      decoration: BoxDecoration(
        color: colors.wood,
        border: Border.all(color: colors.ink, width: 2),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(height: 4, color: colors.ink.withValues(alpha: 0.55)),
          const SizedBox(height: 20),
          Container(height: 4, color: colors.ink.withValues(alpha: 0.55)),
          const SizedBox(height: 18),
          Container(height: 4, color: colors.ink.withValues(alpha: 0.55)),
        ],
      ),
    );
  }
}

class _PixelPlant extends StatelessWidget {
  const _PixelPlant({required this.colors});

  final MameroomTheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.eco, color: colors.seedGreen, size: 34),
        Container(width: 28, height: 22, color: colors.wood),
      ],
    );
  }
}

class _SeedPainter extends CustomPainter {
  const _SeedPainter(this.colors);

  final MameroomTheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 16;
    final outline = Paint()..color = colors.ink;
    final body = Paint()..color = const Color(0xFFFFE1C8);
    final blush = Paint()..color = colors.blossom;
    final green = Paint()..color = colors.seedGreen;

    void rect(Paint paint, int x, int y, int w, int h) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        paint,
      );
    }

    rect(outline, 5, 6, 6, 8);
    rect(body, 6, 7, 4, 6);
    rect(outline, 7, 10, 1, 1);
    rect(outline, 10, 10, 1, 1);
    rect(blush, 5, 11, 1, 1);
    rect(blush, 11, 11, 1, 1);
    rect(outline, 8, 4, 1, 3);
    rect(green, 6, 2, 3, 2);
    rect(green, 9, 2, 4, 2);
    rect(outline, 5, 2, 1, 2);
    rect(outline, 13, 2, 1, 2);
  }

  @override
  bool shouldRepaint(covariant _SeedPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _LampPainter extends CustomPainter {
  const _LampPainter(this.colors);

  final MameroomTheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 16;
    final dark = Paint()..color = colors.ink;
    final purple = Paint()..color = colors.primarySoft;
    final glow = Paint()..color = colors.sun.withValues(alpha: 0.22);
    final light = Paint()..color = colors.sun;

    canvas.drawPath(
      Path()
        ..moveTo(8 * unit, 5 * unit)
        ..lineTo(3 * unit, 14 * unit)
        ..lineTo(13 * unit, 14 * unit)
        ..close(),
      glow,
    );
    canvas.drawRect(Rect.fromLTWH(7.4 * unit, 0, 1.2 * unit, 5 * unit), dark);
    canvas.drawRect(
      Rect.fromLTWH(5 * unit, 5 * unit, 6 * unit, 2 * unit),
      dark,
    );
    canvas.drawRect(
      Rect.fromLTWH(4 * unit, 7 * unit, 8 * unit, 3 * unit),
      purple,
    );
    canvas.drawRect(
      Rect.fromLTWH(5 * unit, 10 * unit, 6 * unit, 1 * unit),
      dark,
    );
    canvas.drawRect(
      Rect.fromLTWH(7 * unit, 11 * unit, 2 * unit, 1 * unit),
      light,
    );
  }

  @override
  bool shouldRepaint(covariant _LampPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _CharacterPainter extends CustomPainter {
  const _CharacterPainter(this.colors);

  final MameroomTheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 20;
    final ink = Paint()..color = colors.ink;
    final skin = Paint()..color = const Color(0xFFFFD8B8);
    final hair = Paint()..color = const Color(0xFF1D2540);
    final white = Paint()..color = Colors.white;
    final green = Paint()..color = colors.seedGreen;

    void rect(Paint paint, int x, int y, int w, int h) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        paint,
      );
    }

    rect(hair, 5, 5, 10, 5);
    rect(hair, 4, 8, 12, 3);
    rect(skin, 6, 9, 8, 6);
    rect(ink, 7, 11, 1, 1);
    rect(ink, 12, 11, 1, 1);
    rect(hair, 8, 2, 4, 3);
    rect(green, 6, 0, 4, 2);
    rect(green, 10, 0, 4, 2);
    rect(white, 5, 16, 10, 8);
    rect(ink, 5, 16, 10, 1);
    rect(white, 5, 24, 4, 6);
    rect(white, 11, 24, 4, 6);
    rect(ink, 5, 30, 4, 1);
    rect(ink, 11, 30, 4, 1);
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter(this.colors, {this.progress});

  final MameroomTheme colors;
  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()..color = colors.primaryMist.withValues(alpha: 0.24);
    final floor = Paint()..color = const Color(0xFFF3D3AE);
    final line = Paint()
      ..color = colors.wood.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final shellLine = Paint()
      ..color = colors.primaryPale
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final wallPath = Path()
      ..moveTo(size.width * 0.17, size.height * 0.24)
      ..lineTo(size.width * 0.50, size.height * 0.08)
      ..lineTo(size.width * 0.83, size.height * 0.24)
      ..lineTo(size.width * 0.83, size.height * 0.66)
      ..lineTo(size.width * 0.50, size.height * 0.82)
      ..lineTo(size.width * 0.17, size.height * 0.66)
      ..close();
    canvas.drawPath(wallPath, wall);
    canvas.drawPath(wallPath, shellLine);

    final floorPath = Path()
      ..moveTo(size.width * 0.17, size.height * 0.66)
      ..lineTo(size.width * 0.50, size.height * 0.82)
      ..lineTo(size.width * 0.83, size.height * 0.66)
      ..lineTo(size.width * 0.83, size.height * 0.82)
      ..lineTo(size.width * 0.50, size.height * 0.98)
      ..lineTo(size.width * 0.17, size.height * 0.82)
      ..close();
    canvas.drawPath(floorPath, floor);
    canvas.drawPath(floorPath, line);

    if (progress != null) {
      final curtain = Paint()
        ..color = Colors.white.withValues(alpha: 1 - progress!.clamp(0, 1));
      canvas.drawRect(Offset.zero & size, curtain);
    }
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.progress != progress;
  }
}
