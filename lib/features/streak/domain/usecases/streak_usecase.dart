import '../entities/streak_state.dart';
import '../repositories/streak_repository.dart';

class StreakUseCase {
  const StreakUseCase(this.repository);

  final StreakRepository repository;

  Future<StreakState> loadStreak() => repository.loadStreak();

  Future<StreakState> recordStudyCompletion({
    required String sourceType,
    required String sourceId,
  }) {
    return repository.recordStudyCompletion(
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }
}