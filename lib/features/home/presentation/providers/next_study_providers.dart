import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../../quiz/data/repositories/shared_preferences_quiz_session_checkpoint_repository.dart';
import '../../../quiz/domain/repositories/quiz_session_checkpoint_repository.dart';
import '../../../review/presentation/providers/review_providers.dart';
import '../../data/repositories/supabase_next_study_repository.dart';
import '../../domain/entities/next_study_action.dart';
import '../../domain/usecases/resolve_next_study_action.dart';

final quizSessionCheckpointRepositoryProvider =
    Provider<QuizSessionCheckpointRepository>((ref) {
      final client = ref.watch(supabaseClientProvider);
      final user = client?.auth.currentUser;
      if (user == null) {
        throw StateError('User session is required to resolve next study.');
      }
      return SharedPreferencesQuizSessionCheckpointRepository(userId: user.id);
    });

typedef NextStudyActionResolver = Future<NextStudyAction> Function();

final nextStudyActionResolverProvider = Provider<NextStudyActionResolver>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return () async => const NoStudyAvailable();
  }
  final useCase = ResolveNextStudyAction(
    checkpoints: ref.watch(quizSessionCheckpointRepositoryProvider),
    nextStudy: SupabaseNextStudyRepository(client),
    reviews: ref.watch(reviewRepositoryProvider),
  );
  return useCase.call;
});

final dueReviewCountProvider = FutureProvider<int>((ref) async {
  return (await ref.watch(reviewUseCaseProvider).loadDueReviews()).length;
});

final resolvingNextStudyProvider = StateProvider<bool>((ref) => false);
