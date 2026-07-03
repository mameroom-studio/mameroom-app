import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/mameroom_shell.dart';
import '../../shared/widgets/pixel_placeholders.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routePath = '/';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  int _dotIndex = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 360), (_) {
      if (mounted) {
        setState(() => _dotIndex = (_dotIndex + 1) % 3);
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) {
        context.go(WelcomePage.routePath);
      }
    });
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MameroomShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const PixelLogo(),
          const SizedBox(height: 58),
          const PixelSeed(size: 72),
          const SizedBox(height: 30),
          Text(
            '공부가 기록이 되고,\n기록이 추억이 되는 나만의 방',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            'LOADING...',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          MameroomDots(count: 3, activeIndex: _dotIndex),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
