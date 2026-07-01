import '../entities/coin_wallet.dart';

abstract interface class CoinRepository {
  Future<CoinWallet> loadWallet();

  Future<CoinRewardSummary> awardQuizCompletion({
    required String materialId,
    required List<CoinRewardAnswer> answers,
    required List<CoinRewardMemoryChange> memoryChanges,
  });

  Future<CoinRewardSummary> awardReviewCompletion({
    required String reviewSessionId,
    required List<CoinRewardAnswer> answers,
    required List<CoinRewardMemoryChange> memoryChanges,
  });
}