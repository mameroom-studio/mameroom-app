import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/achievement_remote_data_source.dart';
import '../../data/repositories/achievement_repository_impl.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/achievement_failure.dart';
import '../../domain/repositories/achievement_repository.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return AchievementRepositoryImpl(AchievementRemoteDataSource(client));
});

final achievementOverviewProvider = FutureProvider<AchievementOverview>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    throw const AchievementFailure(
      AchievementFailureKind.authentication,
      '로그인 정보를 확인할 수 없어요.',
      operation: 'get_achievement_overview',
    );
  }
  return ref.watch(achievementRepositoryProvider).loadOverview();
}, retry: (_, _) => null);

final achievementDetailProvider = FutureProvider.family<Achievement, String>((
  ref,
  code,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    throw const AchievementFailure(
      AchievementFailureKind.authentication,
      '로그인 정보를 확인할 수 없어요.',
      operation: 'get_achievement_detail',
    );
  }
  return ref.watch(achievementRepositoryProvider).loadAchievement(code);
}, retry: (_, _) => null);
