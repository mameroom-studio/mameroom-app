import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../../coins/domain/entities/coin_wallet.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../../streak/presentation/providers/streak_providers.dart';
import '../../data/datasources/quiz_remote_data_source.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../../domain/usecases/quiz_usecase.dart';

final quizRemoteDataSourceProvider = Provider<QuizRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return QuizRemoteDataSource(client);
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepositoryImpl(
    remoteDataSource: ref.watch(quizRemoteDataSourceProvider),
  );
});

final quizUseCaseProvider = Provider<QuizUseCase>((ref) {
  return QuizUseCase(ref.watch(quizRepositoryProvider));
});

final quizControllerProvider =
    StateNotifierProvider<QuizController, AsyncValue<QuizSessionState>>((ref) {
  return QuizController(ref);
});


class ReinforcementQueueItem {
  const ReinforcementQueueItem({
    required this.question,
    required this.availableAfterIndex,
    required this.failedAttempts,
  });

  final Question question;
  final int availableAfterIndex;
  final int failedAttempts;
}

class QuizSessionState {
  const QuizSessionState({
    required this.materialId,
    required this.materialTitle,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.selectedAnswer,
    required this.isAnswerChecked,
    required this.questionStartedAt,
    this.initialQuestionCount = 0,
    this.incorrectQueue = const [],
    this.hintLevelsByQuestion = const {},
    this.passedQuestionIds = const {},
    this.passedConceptIds = const {},
    this.failedQuestionId,
    this.isSaving = false,
    this.memoryUpdates = const [],
    this.coinReward = CoinRewardSummary.empty,
    this.isRewarding = false,
    this.rewardsAwarded = false,
  });

  factory QuizSessionState.initial() {
    return QuizSessionState(
      materialId: '',
      materialTitle: '학습 자료',
      questions: const [],
      currentIndex: 0,
      answers: const [],
      selectedAnswer: '',
      isAnswerChecked: false,
      questionStartedAt: DateTime.now(),
    );
  }

  final String materialId;
  final String materialTitle;
  final List<Question> questions;
  final int currentIndex;
  final List<QuizAnswerResult> answers;
  final String selectedAnswer;
  final bool isAnswerChecked;
  final DateTime questionStartedAt;
  final int initialQuestionCount;
  final List<ReinforcementQueueItem> incorrectQueue;
  final Map<String, int> hintLevelsByQuestion;
  final Set<String> passedQuestionIds;
  final Set<String> passedConceptIds;
  final String? failedQuestionId;
  final bool isSaving;
  final List<MemoryUpdate> memoryUpdates;
  final CoinRewardSummary coinReward;
  final bool isRewarding;
  final bool rewardsAwarded;

  Question? get currentQuestion {
    if (questions.isEmpty || currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  Set<String> get correctQuestionIds => answers
      .where((answer) => answer.isCorrect)
      .map((answer) => answer.question.id)
      .toSet();

  Set<String> get initialQuestionIds => questions
      .take(initialQuestionCount)
      .map((question) => question.id)
      .toSet();

  Set<String> get passedInitialQuestionIds => questions
      .take(initialQuestionCount)
      .where((question) =>
          passedQuestionIds.contains(question.id) ||
          passedConceptIds.contains(question.conceptId))
      .map((question) => question.id)
      .toSet();

  int get remainingQuestionCount {
    final unresolved = initialQuestionIds
        .difference(correctQuestionIds)
        .difference(passedInitialQuestionIds)
        .length;
    final queued = incorrectQueue
        .where((item) => !_isPassedQuestion(item.question))
        .length;
    return unresolved + queued;
  }

  int get currentRetryCount {
    final question = currentQuestion;
    if (question == null) {
      return 0;
    }
    return answers.where((answer) => answer.question.id == question.id).length;
  }

  int get currentHintLevel {
    final question = currentQuestion;
    if (question == null) {
      return 0;
    }
    return hintLevelsByQuestion[question.id] ?? 0;
  }

  bool get canUseHint {
    final question = currentQuestion;
    return question?.type == QuizQuestionType.fillBlank &&
        !isAnswerChecked &&
        !isSaving &&
        currentHintLevel < 2;
  }

  bool get isReinforcementQuestion => currentRetryCount > 0;

  bool get hasHardStop => failedQuestionId != null;

  bool get allQuestionsResolved {
    if (initialQuestionIds.isEmpty) {
      return false;
    }
    final resolved = {...correctQuestionIds, ...passedInitialQuestionIds};
    return initialQuestionIds.difference(resolved).isEmpty;
  }

  bool get isSessionTerminal => hasHardStop || allQuestionsResolved || remainingQuestionCount == 0;

  bool get isLastQuestion => isAnswerChecked && isSessionTerminal;

  QuizAnswerResult? get currentAnswer {
    if (!isAnswerChecked || answers.isEmpty) {
      return null;
    }
    return answers.last;
  }

  QuizResultSummary get summary => QuizResultSummary(answers: answers);

  bool _isPassedQuestion(Question question) {
    return passedQuestionIds.contains(question.id) ||
        passedConceptIds.contains(question.conceptId);
  }

  double get averageMemoryScore {
    if (memoryUpdates.isEmpty) {
      return 0;
    }
    final total = memoryUpdates.fold<double>(
      0,
      (sum, item) => sum + item.memoryScore,
    );
    return total / memoryUpdates.length;
  }

  double get averageMemoryDelta {
    if (memoryUpdates.isEmpty) {
      return 0;
    }
    final total = memoryUpdates.fold<double>(0, (sum, item) => sum + item.delta);
    return total / memoryUpdates.length;
  }

  DateTime? get nextReviewAt {
    if (memoryUpdates.isEmpty) {
      return null;
    }
    return memoryUpdates
        .map((item) => item.nextReviewAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  QuizSessionState copyWith({
    String? materialId,
    String? materialTitle,
    List<Question>? questions,
    int? currentIndex,
    List<QuizAnswerResult>? answers,
    String? selectedAnswer,
    bool? isAnswerChecked,
    DateTime? questionStartedAt,
    int? initialQuestionCount,
    List<ReinforcementQueueItem>? incorrectQueue,
    Map<String, int>? hintLevelsByQuestion,
    Set<String>? passedQuestionIds,
    Set<String>? passedConceptIds,
    String? failedQuestionId,
    bool clearFailedQuestionId = false,
    bool? isSaving,
    List<MemoryUpdate>? memoryUpdates,
    CoinRewardSummary? coinReward,
    bool? isRewarding,
    bool? rewardsAwarded,
  }) {
    return QuizSessionState(
      materialId: materialId ?? this.materialId,
      materialTitle: materialTitle ?? this.materialTitle,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isAnswerChecked: isAnswerChecked ?? this.isAnswerChecked,
      questionStartedAt: questionStartedAt ?? this.questionStartedAt,
      initialQuestionCount: initialQuestionCount ?? this.initialQuestionCount,
      incorrectQueue: incorrectQueue ?? this.incorrectQueue,
      hintLevelsByQuestion: hintLevelsByQuestion ?? this.hintLevelsByQuestion,
      passedQuestionIds: passedQuestionIds ?? this.passedQuestionIds,
      passedConceptIds: passedConceptIds ?? this.passedConceptIds,
      failedQuestionId: clearFailedQuestionId ? null : failedQuestionId ?? this.failedQuestionId,
      isSaving: isSaving ?? this.isSaving,
      memoryUpdates: memoryUpdates ?? this.memoryUpdates,
      coinReward: coinReward ?? this.coinReward,
      isRewarding: isRewarding ?? this.isRewarding,
      rewardsAwarded: rewardsAwarded ?? this.rewardsAwarded,
    );
  }
}

class QuizController extends StateNotifier<AsyncValue<QuizSessionState>> {
  QuizController(this._ref) : super(AsyncData(QuizSessionState.initial()));

  final Ref _ref;

  Future<void> load({required String materialId}) async {
    state = const AsyncLoading();
    try {
      final loadResult = await _ref
          .read(quizUseCaseProvider)
          .loadInitialQuestions(materialId: materialId);
      final questions = loadResult.questions;
      state = AsyncData(
        QuizSessionState(
          materialId: materialId,
          materialTitle: loadResult.materialTitle,
          questions: questions,
          currentIndex: 0,
          answers: const [],
          selectedAnswer: '',
          isAnswerChecked: false,
          questionStartedAt: DateTime.now(),
          initialQuestionCount: questions.length,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void selectAnswer(String answer) {
    final value = state.asData?.value;
    if (value == null || value.isAnswerChecked) {
      return;
    }
    state = AsyncData(value.copyWith(selectedAnswer: answer));
  }

  Future<void> checkAnswer() async {
    final value = state.asData?.value;
    final question = value?.currentQuestion;
    if (value == null || question == null || value.selectedAnswer.trim().isEmpty) {
      return;
    }

    final selected = value.selectedAnswer.trim();
    final isCorrect = _normalize(selected) == _normalize(question.answer);
    final responseTimeMs = DateTime.now().difference(value.questionStartedAt).inMilliseconds;
    final retryCount = value.currentRetryCount;
    final attemptNumber = retryCount + 1;
    final hintLevel = value.currentHintLevel;
    final answer = QuizAnswerResult(
      question: question,
      selectedAnswer: selected,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      attemptNumber: attemptNumber,
      retryCount: retryCount,
      hintUsed: hintLevel > 0,
      hintLevel: hintLevel,
    );

    state = AsyncData(value.copyWith(isSaving: true));
    try {
      final memoryUpdate = await _ref.read(quizUseCaseProvider).saveAttempt(
            materialId: value.materialId,
            questionId: question.id,
            selectedAnswer: selected,
            isCorrect: isCorrect,
            responseTimeMs: responseTimeMs,
            retryCount: retryCount,
            hintUsed: hintLevel > 0,
            hintLevel: hintLevel,
          );
      final queue = _queueAfterAnswer(
        session: value,
        answer: answer,
      );
      state = AsyncData(
        value.copyWith(
          answers: [...value.answers, answer],
          memoryUpdates: [...value.memoryUpdates, memoryUpdate],
          incorrectQueue: queue.queue,
          failedQuestionId: queue.failedQuestionId,
          isAnswerChecked: true,
          isSaving: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<String?> awardCompletionRewards() async {
    final value = state.asData?.value;
    if (value == null || value.rewardsAwarded || value.isRewarding) {
      return null;
    }

    state = AsyncData(value.copyWith(isRewarding: true));
    try {
      var reward = await _ref.read(coinUseCaseProvider).awardQuizCompletion(
            materialId: value.materialId,
            answers: value.answers
                .map(
                  (answer) => CoinRewardAnswer(
                    questionId: answer.question.id,
                    isCorrect: answer.isCorrect,
                  ),
                )
                .toList(growable: false),
            memoryChanges: value.memoryUpdates
                .map(
                  (update) => CoinRewardMemoryChange(
                    conceptId: update.conceptId,
                    increased: update.delta > 0,
                  ),
                )
                .toList(growable: false),
          );
      final streak = await recordStreakCompletion(
        _ref,
        sourceType: 'quiz',
        sourceId: value.materialId,
      );
      if (streak.milestoneReward > 0) {
        reward = reward.combine(
          CoinRewardSummary(
            earnedCoins: streak.milestoneReward,
            balance: streak.walletBalance,
            bonusCoins: streak.milestoneReward,
          ),
        );
      }
      _ref.invalidate(coinWalletProvider);
      state = AsyncData(
        value.copyWith(
          coinReward: reward,
          isRewarding: false,
          rewardsAwarded: true,
        ),
      );
      return null;
    } catch (_) {
      state = AsyncData(value.copyWith(isRewarding: false));
      return 'Reward could not be applied. Your quiz result was saved.';
    }
  }

  void goNext() {
    final value = state.asData?.value;
    if (value == null || !value.isAnswerChecked || value.isSessionTerminal) {
      return;
    }

    final next = _nextQuestionState(value);
    state = AsyncData(
      value.copyWith(
        questions: next.questions,
        incorrectQueue: next.queue,
        currentIndex: next.currentIndex,
        selectedAnswer: '',
        isAnswerChecked: false,
        questionStartedAt: DateTime.now(),
      ),
    );
  }

  void useHint() {
    final value = state.asData?.value;
    final question = value?.currentQuestion;
    if (value == null || question == null || !value.canUseHint) {
      return;
    }

    final currentLevel = value.hintLevelsByQuestion[question.id] ?? 0;
    state = AsyncData(
      value.copyWith(
        hintLevelsByQuestion: {
          ...value.hintLevelsByQuestion,
          question.id: currentLevel + 1,
        },
      ),
    );
  }

  Future<void> passCurrentQuestion({
    required LearningPassType passType,
    required LearningPassReason reason,
  }) async {
    final value = state.asData?.value;
    final question = value?.currentQuestion;
    if (value == null || question == null || value.isAnswerChecked || value.isSaving) {
      return;
    }

    state = AsyncData(value.copyWith(isSaving: true));
    try {
      await _ref.read(quizUseCaseProvider).passLearningItem(
            materialId: value.materialId,
            question: question,
            passType: passType,
            reason: reason,
          );

      final passedQuestionIds = {...value.passedQuestionIds};
      final passedConceptIds = {...value.passedConceptIds};
      if (passType == LearningPassType.question) {
        passedQuestionIds.add(question.id);
      } else {
        passedConceptIds.add(question.conceptId);
      }

      final updated = value.copyWith(
        passedQuestionIds: passedQuestionIds,
        passedConceptIds: passedConceptIds,
        incorrectQueue: value.incorrectQueue
            .where(
              (item) => passType == LearningPassType.question
                  ? item.question.id != question.id
                  : item.question.conceptId != question.conceptId,
            )
            .toList(growable: false),
        selectedAnswer: '',
        isAnswerChecked: false,
        isSaving: false,
        questionStartedAt: DateTime.now(),
      );

      if (updated.isSessionTerminal) {
        state = AsyncData(updated);
        return;
      }

      final next = _nextQuestionState(updated);
      state = AsyncData(
        updated.copyWith(
          questions: next.questions,
          incorrectQueue: next.queue,
          currentIndex: next.currentIndex,
          questionStartedAt: DateTime.now(),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
  Future<void> saveFeedback(String feedbackType) async {
    final value = state.asData?.value;
    final question = value?.currentQuestion;
    if (question == null) {
      return;
    }
    await _ref.read(quizUseCaseProvider).saveFeedback(
          questionId: question.id,
          feedbackType: feedbackType,
        );
  }

  _QueueUpdate _queueAfterAnswer({
    required QuizSessionState session,
    required QuizAnswerResult answer,
  }) {
    final queue = session.incorrectQueue
        .where((item) => item.question.id != answer.question.id)
        .toList(growable: true);

    if (answer.isCorrect) {
      return _QueueUpdate(queue: queue);
    }

    if (answer.attemptNumber >= 3) {
      return _QueueUpdate(
        queue: queue,
        failedQuestionId: answer.question.id,
      );
    }

    queue.add(
      ReinforcementQueueItem(
        question: answer.question,
        availableAfterIndex: session.currentIndex + 3,
        failedAttempts: answer.attemptNumber,
      ),
    );
    return _QueueUpdate(queue: queue);
  }

  _NextQuestionState _nextQuestionState(QuizSessionState session) {
    var naturalNextIndex = session.currentIndex + 1;
    while (naturalNextIndex < session.questions.length) {
      final candidate = session.questions[naturalNextIndex];
      if (!_isQuestionPassed(session, candidate)) {
        return _NextQuestionState(
          questions: session.questions,
          queue: session.incorrectQueue,
          currentIndex: naturalNextIndex,
        );
      }
      naturalNextIndex += 1;
    }

    final currentQuestionId = session.currentQuestion?.id;
    final dueIndex = session.incorrectQueue.indexWhere(
      (item) =>
          item.availableAfterIndex <= session.currentIndex &&
          item.question.id != currentQuestionId &&
          !_isQuestionPassed(session, item.question),
    );
    final selectedIndex = dueIndex >= 0
        ? dueIndex
        : session.incorrectQueue.indexWhere(
            (item) =>
                item.question.id != currentQuestionId &&
                !_isQuestionPassed(session, item.question),
          );

    if (selectedIndex < 0) {
      return _NextQuestionState(
        questions: session.questions,
        queue: session.incorrectQueue,
        currentIndex: session.currentIndex,
      );
    }

    final selected = session.incorrectQueue[selectedIndex];
    final queue = [...session.incorrectQueue]..removeAt(selectedIndex);
    final questions = [...session.questions, selected.question];
    return _NextQuestionState(
      questions: questions,
      queue: queue,
      currentIndex: questions.length - 1,
    );
  }

  bool _isQuestionPassed(QuizSessionState session, Question question) {
    return session.passedQuestionIds.contains(question.id) ||
        session.passedConceptIds.contains(question.conceptId);
  }
  String _normalize(String value) => value.trim().toLowerCase();
}

class _QueueUpdate {
  const _QueueUpdate({required this.queue, this.failedQuestionId});

  final List<ReinforcementQueueItem> queue;
  final String? failedQuestionId;
}

class _NextQuestionState {
  const _NextQuestionState({
    required this.questions,
    required this.queue,
    required this.currentIndex,
  });

  final List<Question> questions;
  final List<ReinforcementQueueItem> queue;
  final int currentIndex;
}