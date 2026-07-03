import 'package:flutter/material.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../quiz/domain/entities/question.dart';
import 'study_components.dart';

class CorrectAnswerScreen extends StatelessWidget {
  const CorrectAnswerScreen({
    required this.memoryBefore,
    required this.memoryAfter,
    required this.coinAmount,
    required this.onNext,
    super.key,
  });

  final double memoryBefore;
  final double memoryAfter;
  final int coinAmount;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.86, end: 1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Column(
            children: [
              Text('정답이에요!', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on, color: colors.sun, size: 58),
                  const SizedBox(width: 12),
                  Text('+$coinAmount\nCOIN', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: 26),
              const PixelCharacter(size: 118),
            ],
          ),
        ),
        const Spacer(),
        StudyCard(
          child: Column(
            children: [
              Text('기억이 성장했어요!', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${(memoryBefore * 100).round()}%', style: Theme.of(context).textTheme.headlineMedium),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Icon(Icons.play_arrow_rounded, color: colors.primary),
                  ),
                  Text('${(memoryAfter * 100).round()}%', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: colors.primary)),
                ],
              ),
              const SizedBox(height: 10),
              MemoryGauge(value: memoryAfter, compact: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        StudyPrimaryButton(label: '다음 문제', onPressed: onNext),
      ],
    );
  }
}

class IncorrectAnswerScreen extends StatelessWidget {
  const IncorrectAnswerScreen({
    required this.answer,
    required this.isHardStop,
    required this.hintText,
    required this.onNext,
    super.key,
  });

  final QuizAnswerResult answer;
  final bool isHardStop;
  final String hintText;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Text('아쉬워요!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 6),
        Text('다시 기억해볼까요?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        StudyCard(
          child: Column(
            children: [
              Text('정답은', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(answer.question.answer, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: colors.primary)),
              const SizedBox(height: 8),
              Text('입니다.', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StudyCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              PixelSeedCardArt(color: colors.blossom, icon: Icons.park),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isHardStop ? '오늘은 여기까지! 다음 복습 스케줄로 이월할게요.' : '이 문제는 3문제 뒤에 다시 출제될 거예요!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StudyCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('힌트', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.primary)),
              const SizedBox(height: 8),
              Text(hintText, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        const Spacer(),
        StudyPrimaryButton(label: '다음 문제', onPressed: onNext),
      ],
    );
  }
}

class MemoryGrowthPopup extends StatelessWidget {
  const MemoryGrowthPopup({required this.before, required this.after, super.key});

  final double before;
  final double after;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
            ),
            Text('벚꽃 기억씨앗', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.75, end: 1),
              duration: const Duration(milliseconds: 620),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: PixelSeedCardArt(color: colors.blossom, icon: Icons.park),
            ),
            const SizedBox(height: 16),
            Text('Lv.3 풋봉오리', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Text('기억률 성장', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${(before * 100).round()}%', style: Theme.of(context).textTheme.headlineMedium),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.play_arrow_rounded, color: colors.primary),
                ),
                Text('${(after * 100).round()}%', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: colors.primary)),
              ],
            ),
            const SizedBox(height: 10),
            MemoryGauge(value: after, compact: true),
            const SizedBox(height: 20),
            Text('기억이 더 깊어지고 있어요!', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class ComboRewardPopup extends StatelessWidget {
  const ComboRewardPopup({required this.comboCount, required this.coinAmount, super.key});

  final int comboCount;
  final int coinAmount;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Dialog(
      backgroundColor: colors.ink.withValues(alpha: 0.92),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, color: Colors.white70)),
            ),
            Text('$comboCount COMBO!', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 12),
            const Text('🔥 🔥 🔥 🔥 🔥', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text('연속 정답 보너스!', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 26),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.08),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Icon(Icons.monetization_on, color: colors.sun, size: 92),
            ),
            const SizedBox(height: 12),
            Text('+$coinAmount\nCOIN', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
