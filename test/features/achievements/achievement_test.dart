import 'package:ai_memory_coach/features/achievements/domain/entities/achievement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('progress is capped and achievement stays separate from badge', () {
    const achievement = Achievement(
      code: 'learning_100',
      title: '백 번의 배움',
      description: '문제 100개 풀기',
      category: AchievementCategory.learning,
      status: AchievementStatus.rewarded,
      current: 120,
      target: 100,
      condition: '문제 100개 풀기',
      rewards: [
        AchievementReward(
          type: AchievementRewardType.badge,
          label: '배움 배지',
          delivered: true,
        ),
      ],
    );

    expect(achievement.progress, 1);
    expect(achievement.rewards.single.type, AchievementRewardType.badge);
  });

  test('summary safely handles an empty definition set', () {
    const summary = AchievementSummary(
      completed: 0,
      total: 0,
      badgeCount: 0,
      nextAchievement: null,
    );
    expect(summary.progress, 0);
  });
}
