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

class QuizSessionState {
  const QuizSessionState({
    required this.materialId,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.selectedAnswer,
    required this.isAnswerChecked,
    required this.questionStartedAt,
    this.isSaving = false,
    this.memoryUpdates = const [],
    this.coinReward = CoinRewardSummary.empty,
    this.isRewarding = false,
    this.rewardsAwarded = false,
  });

  factory QuizSessionState.initial() {
    return QuizSessionState(
      materialId: '',
      questions: const [],
      currentIndex: 0,
      answers: const [],
      selectedAnswer: '',
      isAnswerChecked: false,
      questionStartedAt: DateTime.now(),
    );
  }

  final String materialId;
  final List<Question> questions;
  final int currentIndex;
  final List<QuizAnswerResult> answers;
  final String selectedAnswer;
  final bool isAnswerChecked;
  final DateTime questionStartedAt;
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

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  QuizAnswerResult? get currentAnswer {
    if (!isAnswerChecked || answers.isEmpty) {
      return null;
    }
    return answers.last;
  }

  QuizResultSummary get summary => QuizResultSummary(answers: answers);

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
    List<Question>? questions,
    int? currentIndex,
    List<QuizAnswerResult>? answers,
    String? selectedAnswer,
    bool? isAnswerChecked,
    DateTime? questionStartedAt,
    bool? isSaving,
    List<MemoryUpdate>? memoryUpdates,
    CoinRewardSummary? coinReward,
    bool? isRewarding,
    bool? rewardsAwarded,
  }) {
    return QuizSessionState(
      materialId: materialId ?? this.materialId,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isAnswerChecked: isAnswerChecked ?? this.isAnswerChecked,
      questionStartedAt: questionStartedAt ?? this.questionStartedAt,
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
      final questions = await _ref
          .read(quizUseCaseProvider)
          .loadInitialQuestions(materialId: materialId);
      state = AsyncData(
        QuizSessionState(
          materialId: materialId,
          questions: questions,
          currentIndex: 0,
          answers: const [],
          selectedAnswer: '',
          isAnswerChecked: false,
          questionStartedAt: DateTime.now(),
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
    final answer = QuizAnswerResult(
      question: question,
      selectedAnswer: selected,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
    );

    state = AsyncData(value.copyWith(isSaving: true));
    try {
      final memoryUpdate = await _ref.read(quizUseCaseProvider).saveAttempt(
            materialId: value.materialId,
            questionId: question.id,
            selectedAnswer: selected,
            isCorrect: isCorrect,
            responseTimeMs: responseTimeMs,
          );
      state = AsyncData(
        value.copyWith(
          answers: [...value.answers, answer],
          memoryUpdates: [...value.memoryUpdates, memoryUpdate],
          isAnswerChecked: true,
          isSaving: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> awardCompletionRewards() async {
    final value = state.asData?.value;
    if (value == null || value.rewardsAwarded || value.isRewarding) {
      return;
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
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void goNext() {
    final value = state.asData?.value;
    if (value == null || !value.isAnswerChecked || value.isLastQuestion) {
      return;
    }
    state = AsyncData(
      value.copyWith(
        currentIndex: value.currentIndex + 1,
        selectedAnswer: '',
        isAnswerChecked: false,
        questionStartedAt: DateTime.now(),
      ),
    );
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

  String _normalize(String value) => value.trim().toLowerCase();
}