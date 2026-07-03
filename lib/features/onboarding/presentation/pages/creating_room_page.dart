import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../gamification/presentation/pages/room_page.dart';

class CreatingRoomPage extends StatefulWidget {
  const CreatingRoomPage({super.key});

  static const routePath = '/creating-room';

  @override
  State<CreatingRoomPage> createState() => _CreatingRoomPageState();
}

class _CreatingRoomPageState extends State<CreatingRoomPage> {
  double _progress = 0.18;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 260), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _progress = (_progress + 0.11).clamp(0, 1));
      if (_progress >= 1) {
        _timer?.cancel();
        Future<void>.delayed(const Duration(milliseconds: 520), () {
          if (mounted) {
            context.go(RoomPage.routePath);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final percent = (_progress * 100).round();
    return MameroomShell(
      showSparkles: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(
            '나만의 방을 만들고 있어요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '곧 멋진 공간에서 만나요!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 36),
          Expanded(
            child: Center(
              child: PixelRoomScene(
                progress: 1 - _progress,
                showFurniture: false,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: colors.line,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('방을 꾸미는 중이에요...', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
