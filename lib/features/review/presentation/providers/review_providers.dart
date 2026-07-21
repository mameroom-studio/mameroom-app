import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../../../core/config/env.dart';
import '../../../coins/domain/entities/coin_wallet.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../../streak/presentation/providers/streak_providers.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../data/repositories/mock_review_repository.dart';
import '../../domain/entities/review_schedule.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/usecases/review_usecase.dart';

final reviewRemoteDataSourceProvider = Provider<ReviewRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return ReviewRemoteDataSource(client);
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (Env.useMockReview) return MockReviewRepository();
  return ReviewRepositoryImpl(
    remoteDataSource: ref.watch(reviewRemoteDataSourceProvider),
  );
});

final reviewUseCaseProvider = Provider<ReviewUseCase>((ref) {
  return ReviewUseCase(ref.watch(reviewRepositoryProvider));
});

final reviewControllerProvider =
    StateNotifierProvider<ReviewController, AsyncValue<ReviewSessionState>>((
      ref,
    ) {
      return ReviewController(ref);
    });

class ReviewSessionState {
  const ReviewSessionState({
    required this.items,
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

  factory ReviewSessionState.initial() {
    return ReviewSessionState(
      items: const [],
      currentIndex: 0,
      answers: const [],
      selectedAnswer: '',
      isAnswerChecked: false,
      questionStartedAt: DateTime.now(),
    );
  }

  final List<ReviewSchedule> items;
  final int currentIndex;
  final List<ReviewAnswerResult> answers;
  final String selectedAnswer;
  final bool isAnswerChecked;
  final DateTime questionStartedAt;
  final bool isSaving;
  final List<MemoryUpdate> memoryUpdates;
  final CoinRewardSummary coinReward;
  final bool isRewarding;
  final bool rewardsAwarded;

  ReviewSchedule? get currentItem {
    if (items.isEmpty || currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex];
  }

  bool get isLastQuestion => currentIndex >= items.length - 1;
  int get dueCount => items.length;
  ReviewResultSummary get summary => ReviewResultSummary(answers: answers);

  ReviewAnswerResult? get currentAnswer {
    if (!isAnswerChecked || answers.isEmpty) {
      return null;
    }
    return answers.last;
  }

  DateTime? get nextReviewAt {
    if (memoryUpdates.isEmpty) {
      return null;
    }
    return memoryUpdates
        .map((item) => item.nextReviewAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  ReviewSessionState copyWith({
    List<ReviewSchedule>? items,
    int? currentIndex,
    List<ReviewAnswerResult>? answers,
    String? selectedAnswer,
    bool? isAnswerChecked,
    DateTime? questionStartedAt,
    bool? isSaving,
    List<MemoryUpdate>? memoryUpdates,
    CoinRewardSummary? coinReward,
    bool? isRewarding,
    bool? rewardsAwarded,
  }) {
    return ReviewSessionState(
      items: items ?? this.items,
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

class ReviewController extends StateNotifier<AsyncValue<ReviewSessionState>> {
  ReviewController(this._ref) : super(AsyncData(ReviewSessionState.initial()));

  final Ref _ref;

  Future<void> loadTodayReviews() async {
    state = const AsyncLoading();
    try {
      final items = await _ref.read(reviewUseCaseProvider).loadDueReviews();
      state = AsyncData(
        ReviewSessionState(
          items: items,
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
    final item = value?.currentItem;
    if (value == null || item == null || value.selectedAnswer.trim().isEmpty) {
      return;
    }

    final selected = value.selectedAnswer.trim();
    final isCorrect = _normalize(selected) == _normalize(item.question.answer);
    final responseTimeMs = DateTime.now()
        .difference(value.questionStartedAt)
        .inMilliseconds;
    final answer = ReviewAnswerResult(
      item: item,
      selectedAnswer: selected,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
    );

    state = AsyncData(value.copyWith(isSaving: true));
    try {
      final memoryUpdate = await _ref
          .read(reviewUseCaseProvider)
          .completeReview(
            item: item,
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

  Future<void> passCurrentItem({
    required LearningPassType passType,
    required LearningPassReason reason,
  }) async {
    final value = state.asData?.value;
    final item = value?.currentItem;
    if (value == null ||
        item == null ||
        value.isAnswerChecked ||
        value.isSaving) {
      return;
    }

    state = AsyncData(value.copyWith(isSaving: true));
    try {
      await _ref
          .read(reviewUseCaseProvider)
          .passLearningItem(item: item, passType: passType, reason: reason);

      final updatedItems = value.items
          .where((candidate) {
            if (passType == LearningPassType.question) {
              return candidate.question.id != item.question.id;
            }
            return candidate.conceptId != item.conceptId;
          })
          .toList(growable: false);
      final nextIndex = updatedItems.isEmpty
          ? 0
          : value.currentIndex.clamp(0, updatedItems.length - 1).toInt();

      state = AsyncData(
        value.copyWith(
          items: updatedItems,
          currentIndex: nextIndex,
          selectedAnswer: '',
          isAnswerChecked: false,
          isSaving: false,
          questionStartedAt: DateTime.now(),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> awardCompletionRewards() async {
    final value = state.asData?.value;
    if (value == null ||
        value.items.isEmpty ||
        value.rewardsAwarded ||
        value.isRewarding) {
      return;
    }

    state = AsyncData(value.copyWith(isRewarding: true));
    try {
      var reward = await _ref
          .read(coinUseCaseProvider)
          .awardReviewCompletion(
            reviewSessionId: value.items.first.id,
            answers: value.answers
                .map(
                  (answer) => CoinRewardAnswer(
                    questionId: answer.item.question.id,
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
        sourceType: 'review',
        sourceId: value.items.first.id,
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

  String _normalize(String value) => value.trim().toLowerCase();
}
