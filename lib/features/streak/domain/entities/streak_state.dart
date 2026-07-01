class StreakState {
  const StreakState({
    required this.currentStreak,
    required this.maxStreak,
    required this.milestoneReward,
    required this.walletBalance,
  });

  final int currentStreak;
  final int maxStreak;
  final int milestoneReward;
  final int walletBalance;

  static const empty = StreakState(
    currentStreak: 0,
    maxStreak: 0,
    milestoneReward: 0,
    walletBalance: 0,
  );
}