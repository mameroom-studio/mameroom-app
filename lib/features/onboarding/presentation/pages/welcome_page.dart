import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/presentation/pages/home_shell_page.dart';
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
      title: '공부는 금방 잊혀집니다.',
      icon: '📚',
      description: '오늘 공부한 내용,\n얼마나 기억하고 계신가요?',
    ),
    _OnboardingStep(
      title: 'AI가 기억을 만들어줍니다.',
      icon: '🧠',
      description: 'PDF를 업로드하면\nAI가 기억 문제를 생성합니다.',
    ),
    _OnboardingStep(
      title: '기억은 씨앗이 됩니다.',
      icon: '🌱',
      description: '하나의 기억은\n하나의 씨앗이 됩니다.',
    ),
    _OnboardingStep(
      title: '당신만의 방이 성장합니다.',
      icon: '🏠',
      description: '공부가 기록이 되고,\n기록이 추억이 됩니다.',
    ),
    _OnboardingStep(
      title: '당신의 첫 기억을 심어볼까요?',
      icon: '🌱',
      description: '',
      isFinal: true,
    ),
  ];

  late final PageController _pageController;
  var _isCompleting = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentIndex];
    return MameroomShell(
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isCompleting ? null : _finishOnboarding,
                child: const Text('건너뛰기'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return _OnboardingPanel(step: _steps[index]);
                },
              ),
            ),
            const SizedBox(height: 18),
            MameroomPrimaryButton(
              label: step.isFinal ? '시작하기' : '다음',
              isLoading: _isCompleting,
              onPressed: _completeOnboarding,
            ),
            const SizedBox(height: 18),
            MameroomDots(count: _steps.length, activeIndex: _currentIndex),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) {
      return;
    }
    if (_currentIndex < _steps.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    if (_isCompleting) {
      return;
    }
    setState(() => _isCompleting = true);
    await ref.read(onboardingControllerProvider).complete();
    if (!mounted) {
      return;
    }

    final isAuthenticated = ref.read(currentUserProvider).asData?.value != null;
    context.go(isAuthenticated ? HomeShellPage.homeRoutePath : LoginPage.routePath);
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.icon,
    required this.description,
    this.isFinal = false,
  });

  final String title;
  final String icon;
  final String description;
  final bool isFinal;
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 560;
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: compact ? 8 : 18),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                SizedBox(height: compact ? 18 : 28),
                Text(
                  step.icon,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: compact ? 58 : 74, height: 1),
                ),
                SizedBox(height: compact ? 18 : 28),
                if (step.description.isNotEmpty)
                  Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                SizedBox(height: compact ? 20 : 34),
                FractionallySizedBox(
                  widthFactor: compact ? 0.72 : 0.88,
                  child: PixelRoomScene(
                    progress: step.isFinal ? 1 : 0.28,
                    showFurniture: step.isFinal,
                  ),
                ),
                SizedBox(height: compact ? 8 : 18),
              ],
            ),
          ),
        );
      },
    );
  }
}

