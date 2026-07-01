import '../../domain/entities/coin_wallet.dart';
import '../../domain/repositories/coin_repository.dart';
import '../datasources/coin_remote_data_source.dart';

class CoinRepositoryImpl implements CoinRepository {
  const CoinRepositoryImpl({required CoinRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final CoinRemoteDataSource _remoteDataSource;

  @override
  Future<CoinWallet> loadWallet() {
    return _remoteDataSource.loadWallet();
  }

  @override
  Future<CoinRewardSummary> awardQuizCompletion({
    required String materialId,
    required List<CoinRewardAnswer> answers,
    required List<CoinRewardMemoryChange> memoryChanges,
  }) {
    return _remoteDataSource.awardQuizCompletion(
      materialId: materialId,
      answers: answers,
      memoryChanges: memoryChanges,
    );
  }

  @override
  Future<CoinRewardSummary> awardReviewCompletion({
    required String reviewSessionId,
    required List<CoinRewardAnswer> answers,
    required List<CoinRewardMemoryChange> memoryChanges,
  }) {
    return _remoteDataSource.awardReviewCompletion(
      reviewSessionId: reviewSessionId,
      answers: answers,
      memoryChanges: memoryChanges,
    );
  }
}