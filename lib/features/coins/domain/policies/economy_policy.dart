class CoinAwardPolicy {
  const CoinAwardPolicy({
    required this.amount,
    required this.transactionType,
    required this.sourceType,
    required this.sourceId,
    required this.reason,
    required this.idempotencyKey,
  });

  final int amount;
  final String transactionType;
  final String sourceType;
  final String sourceId;
  final String reason;
  final String idempotencyKey;
}

class EconomyPolicy {
  const EconomyPolicy._();

  static const correctAnswerCoins = 1;
  static const fiveCorrectStreakBonusCoins = 2;
  static const reviewCompletionCoins = 20;
  static const memoryIncreaseCoins = 50;
  static const firstStudyCoins = 10;
  static const todayGoalCompletionCoins = 20;
  static const streak7AchievementCoins = 70;
  static const streak30AchievementCoins = 300;
  static const streak100AchievementCoins = 1000;

  static const correctAnswerType = 'correct_answer';
  static const streakBonusType = 'streak_bonus';
  static const reviewCompleteType = 'review_complete';
  static const memoryIncreaseType = 'memory_increase';
  static const firstStudyType = 'first_study';
  static const todayGoalCompleteType = 'today_goal_complete';
  static const achievementRewardType = 'achievement_reward';
  static const roomPurchaseType = 'room_purchase';
  static const streak7BonusType = 'streak_7_bonus';
  static const streak30BonusType = 'streak_30_bonus';
  static const streak100BonusType = 'streak_100_bonus';

  static const quizSource = 'quiz';
  static const reviewSource = 'review';
  static const memorySource = 'memory';
  static const studySource = 'study';
  static const roomItemSource = 'room_item';
  static const streakSource = 'streak';
  static const achievementSource = 'achievement';
  static const goalSource = 'goal';

  static CoinAwardPolicy correctAnswer({
    required String questionId,
    required String sourceType,
  }) {
    return CoinAwardPolicy(
      amount: correctAnswerCoins,
      transactionType: correctAnswerType,
      sourceType: sourceType,
      sourceId: questionId,
      reason: 'Correct answer',
      idempotencyKey: '$sourceType:$correctAnswerType:$questionId',
    );
  }

  static CoinAwardPolicy fiveCorrectStreak({
    required String sourceType,
    required String sourceId,
  }) {
    return CoinAwardPolicy(
      amount: fiveCorrectStreakBonusCoins,
      transactionType: streakBonusType,
      sourceType: sourceType,
      sourceId: sourceId,
      reason: 'Five correct answers in a row',
      idempotencyKey: '$sourceType:$streakBonusType:$sourceId',
    );
  }

  static CoinAwardPolicy memoryIncrease({required String conceptId}) {
    return CoinAwardPolicy(
      amount: memoryIncreaseCoins,
      transactionType: memoryIncreaseType,
      sourceType: memorySource,
      sourceId: conceptId,
      reason: 'Memory score increased',
      idempotencyKey: '$memorySource:$memoryIncreaseType:$conceptId',
    );
  }

  static CoinAwardPolicy firstStudy({required String materialId}) {
    return CoinAwardPolicy(
      amount: firstStudyCoins,
      transactionType: firstStudyType,
      sourceType: studySource,
      sourceId: materialId,
      reason: 'First study completion',
      idempotencyKey: '$studySource:$firstStudyType:$materialId',
    );
  }

  static CoinAwardPolicy reviewComplete({required String reviewSessionId}) {
    return CoinAwardPolicy(
      amount: reviewCompletionCoins,
      transactionType: reviewCompleteType,
      sourceType: reviewSource,
      sourceId: reviewSessionId,
      reason: 'Review completed',
      idempotencyKey: '$reviewSource:$reviewCompleteType:$reviewSessionId',
    );
  }

  static int achievementRewardForStreak(int streak) {
    return switch (streak) {
      7 => streak7AchievementCoins,
      30 => streak30AchievementCoins,
      100 => streak100AchievementCoins,
      _ => 0,
    };
  }
}
