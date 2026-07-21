import '../entities/quiz_session_checkpoint.dart';

abstract interface class QuizSessionCheckpointRepository {
  Future<QuizSessionCheckpoint?> loadLatest();

  Future<void> save(QuizSessionCheckpoint checkpoint);

  Future<void> clear();
}
