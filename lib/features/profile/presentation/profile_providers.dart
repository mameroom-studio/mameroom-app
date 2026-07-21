import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/supabase/supabase_client_provider.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile_edit_snapshot.dart';
import '../domain/profile_failure.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase client is not initialized.');
  return SupabaseProfileRepository(client);
});

final profileEditProvider = FutureProvider<ProfileEditSnapshot>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    throw const ProfileFailure(
      ProfileFailureKind.authentication,
      '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.',
      operation: 'get_my_edit_profile',
    );
  }
  return ref.watch(profileRepositoryProvider).load();
}, retry: (_, _) => null);
