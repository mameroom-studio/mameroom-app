class CoinWallet {
  const CoinWallet({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.todayEarned,
  });

  final int balance;
  final int totalEarned;
  final int totalSpent;
  final int todayEarned;

  static const empty = CoinWallet(
    balance: 0,
    totalEarned: 0,
    totalSpent: 0,
    todayEarned: 0,
  );
}

class CoinRewardAnswer {
  const CoinRewardAnswer({
    required this.questionId,
    required this.isCorrect,
  });

  final String questionId;
  final bool isCorrect;
}

class CoinRewardMemoryChange {
  const CoinRewardMemoryChange({
    required this.conceptId,
    required this.increased,
  });

  final String conceptId;
  final bool increased;
}

class CoinRewardSummary {
  const CoinRewardSummary({
    required this.earnedCoins,
    required this.balance,
    required this.bonusCoins,
  });

  final int earnedCoins;
  final int balance;
  final int bonusCoins;

  static const empty = CoinRewardSummary(
    earnedCoins: 0,
    balance: 0,
    bonusCoins: 0,
  );

  CoinRewardSummary combine(CoinRewardSummary other) {
    return CoinRewardSummary(
      earnedCoins: earnedCoins + other.earnedCoins,
      balance: other.balance,
      bonusCoins: bonusCoins + other.bonusCoins,
    );
  }
}