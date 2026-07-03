import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../providers/onboarding_providers.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  static const routePath = '/welcome';

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  static const _steps = <_OnboardingStep>[
    _OnboardingStep(
      title: '공부할 파일만 넣으면',
      description: '마메룸이 핵심 개념을 찾고\n기억에 남는 문제로 바꿔줘요.',
      buttonLabel: '마메룸 시작하기',
    ),
  ];

  var _isCompleting = false;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentIndex];
    return MameroomShell(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isCompleting ? null : _completeOnboarding,
              child: const Text('건너뛰기'),
            ),
          ),
          const PixelLamp(size: 84),
          const SizedBox(height: 16),
          Text(
            '나만의 기억 방을 만들어요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 0.95,
                child: PixelRoomScene(showFurniture: true),
              ),
            ),
          ),
          const SizedBox(height: 18),
          MameroomPrimaryButton(
            label: step.buttonLabel,
            isLoading: _isCompleting,
            onPressed: _completeOnboarding,
          ),
          const SizedBox(height: 18),
          MameroomDots(count: _steps.length, activeIndex: _currentIndex),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) {
      return;
    }
    if (_currentIndex < _steps.length - 1) {
      setState(() => _currentIndex += 1);
      return;
    }

    setState(() => _isCompleting = true);
    await ref.read(onboardingControllerProvider).complete();
    if (!mounted) {
      return;
    }

    final isAuthenticated = ref.read(currentUserProvider).asData?.value != null;
    context.go(isAuthenticated ? LibraryPage.routePath : LoginPage.routePath);
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.buttonLabel,
  });

  final String title;
  final String description;
  final String buttonLabel;
}
