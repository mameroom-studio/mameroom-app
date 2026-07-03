import '../../../coins/domain/entities/coin_wallet.dart';
import '../../presentation/providers/quiz_providers.dart';
import 'question.dart';

class QuizResultSnapshot {
  const QuizResultSnapshot({
    required this.summary,
    required this.averageMemoryScore,
    required this.averageMemoryDelta,
    required this.nextReviewAt,
    required this.coinReward,
    this.rewardWarning,
  });

  factory QuizResultSnapshot.fromSession(
    QuizSessionState session, {
    String? rewardWarning,
  }) {
    return QuizResultSnapshot(
      summary: session.summary,
      averageMemoryScore: session.averageMemoryScore,
      averageMemoryDelta: session.averageMemoryDelta,
      nextReviewAt: session.nextReviewAt,
      coinReward: session.coinReward,
      rewardWarning: rewardWarning,
    );
  }

  final QuizResultSummary summary;
  final double averageMemoryScore;
  final double averageMemoryDelta;
  final DateTime? nextReviewAt;
  final CoinRewardSummary coinReward;
  final String? rewardWarning;
}
