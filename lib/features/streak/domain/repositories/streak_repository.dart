import '../entities/streak_state.dart';

abstract interface class StreakRepository {
  Future<StreakState> loadStreak();

  Future<StreakState> recordStudyCompletion({
    required String sourceType,
    required String sourceId,
  });
}