sealed class NextStudyAction {
  const NextStudyAction();
}

class ResumeStudy extends NextStudyAction {
  const ResumeStudy(this.materialId);
  final String materialId;
}

class StartNewStudy extends NextStudyAction {
  const StartNewStudy(this.materialId);
  final String materialId;
}

class StartReview extends NextStudyAction {
  const StartReview();
}

class NoStudyAvailable extends NextStudyAction {
  const NoStudyAvailable();
}
