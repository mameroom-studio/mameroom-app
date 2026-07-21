enum AchievementCategory {
  learning,
  review,
  memory,
  growth,
  friends,
  collection,
}

enum AchievementStatus {
  notStarted,
  inProgress,
  eligible,
  completing,
  completed,
  rewardPending,
  rewarded,
  locked,
  unavailable,
  expired,
}

enum AchievementRewardType { mCoin, badge, roomDecoration, other }

enum BadgeGrade { bronze, silver, gold, platinum, diamond }

class AchievementReward {
  const AchievementReward({
    required this.type,
    required this.label,
    this.amount,
    this.assetPath,
    this.delivered = false,
  });

  final AchievementRewardType type;
  final String label;
  final int? amount;
  final String? assetPath;
  final bool delivered;
}

class Achievement {
  const Achievement({
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.current,
    required this.target,
    required this.condition,
    required this.rewards,
    this.iconAsset,
    this.completedAt,
    this.badgeGrade,
    this.isHidden = false,
  });

  final String code;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementStatus status;
  final int current;
  final int target;
  final String condition;
  final List<AchievementReward> rewards;
  final String? iconAsset;
  final DateTime? completedAt;
  final BadgeGrade? badgeGrade;
  final bool isHidden;

  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1);
}

class AchievementSummary {
  const AchievementSummary({
    required this.completed,
    required this.total,
    required this.badgeCount,
    required this.nextAchievement,
  });

  final int completed;
  final int total;
  final int badgeCount;
  final Achievement? nextAchievement;

  double get progress => total <= 0 ? 0 : (completed / total).clamp(0, 1);
}

class AchievementOverview {
  const AchievementOverview({
    required this.summary,
    required this.achievements,
  });

  final AchievementSummary summary;
  final List<Achievement> achievements;
}
