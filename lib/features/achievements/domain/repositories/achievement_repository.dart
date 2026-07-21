import '../entities/achievement.dart';

abstract interface class AchievementRepository {
  Future<AchievementOverview> loadOverview();
  Future<Achievement> loadAchievement(String code);
  Future<Achievement> refreshRewardState(String code);
}
