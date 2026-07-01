import '../../domain/entities/streak_state.dart';
import '../../domain/repositories/streak_repository.dart';
import '../datasources/streak_remote_data_source.dart';

class StreakRepositoryImpl implements StreakRepository {
  const StreakRepositoryImpl({required StreakRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final StreakRemoteDataSource _remoteDataSource;

  @override
  Future<StreakState> loadStreak() {
    return _remoteDataSource.loadStreak();
  }

  @override
  Future<StreakState> recordStudyCompletion({
    required String sourceType,
    required String sourceId,
  }) {
    return _remoteDataSource.recordStudyCompletion(
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }
}