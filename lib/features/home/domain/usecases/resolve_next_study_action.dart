import '../../../quiz/domain/repositories/quiz_session_checkpoint_repository.dart';
import '../../../review/domain/repositories/review_repository.dart';
import '../entities/next_study_action.dart';
import '../repositories/next_study_repository.dart';

class ResolveNextStudyAction {
  const ResolveNextStudyAction({
    required this.checkpoints,
    required this.nextStudy,
    required this.reviews,
  });

  final QuizSessionCheckpointRepository checkpoints;
  final NextStudyRepository nextStudy;
  final ReviewRepository reviews;

  Future<NextStudyAction> call() async {
    final checkpoint = await checkpoints.loadLatest();
    if (checkpoint != null &&
        checkpoint.materialId.isNotEmpty &&
        checkpoint.questionIds.isNotEmpty &&
        checkpoint.currentIndex < checkpoint.questionIds.length) {
      return ResumeStudy(checkpoint.materialId);
    }

    final materialId = await nextStudy.findUnlearnedMaterialId();
    if (materialId != null) return StartNewStudy(materialId);

    final dueReviews = await reviews.loadDueReviews();
    if (dueReviews.isNotEmpty) return const StartReview();

    return const NoStudyAvailable();
  }
}
