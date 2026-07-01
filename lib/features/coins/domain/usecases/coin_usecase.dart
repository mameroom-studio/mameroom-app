import '../entities/coin_wallet.dart';
import '../repositories/coin_repository.dart';

class CoinUseCase {
  const CoinUseCase(this.repository);

  final CoinRepository repository;

  Future<CoinWallet> loadWallet() => repository.loadWallet();

  Future<CoinRewardSummary> awardQuizCompletion({
    required String materialId,
    required List<CoinRewardAnswer> answers,
    required List<CoinRewardMemoryChange> memoryChanges,
  }) {
    return repository.awardQuizCompletion(
      materialId: materialId,
      answers: answers,
      memoryChanges: memoryChanges,
    );
  }

  Future<CoinRewardSummary> awardReviewCompletion({
    required String reviewSessionId,
    required List<CoinRewardAnswer> answers,
    required List<CoinRewardMemoryChange> memoryChanges,
  }) {
    return repository.awardReviewCompletion(
      reviewSessionId: reviewSessionId,
      answers: answers,
      memoryChanges: memoryChanges,
    );
  }
}