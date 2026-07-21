import 'package:ai_memory_coach/features/profile/data/profile_repository.dart';
import 'package:ai_memory_coach/features/profile/domain/profile_edit_snapshot.dart';
import 'package:ai_memory_coach/features/profile/presentation/edit_profile_page.dart';
import 'package:ai_memory_coach/features/profile/presentation/profile_providers.dart';
import 'package:ai_memory_coach/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _IntegrationRepository implements ProfileRepository {
  var saved = false;
  final data = ProfileEditSnapshot(
    nickname: '마메룸사용자',
    bio: '',
    todayGoal: '',
    updatedAt: DateTime.utc(2026, 7, 19),
    trees: const [],
    badges: const [],
  );
  @override
  Future<ProfileEditSnapshot> load() async => data;
  @override
  Future<ProfileEditSnapshot> save({
    required String nickname,
    required String bio,
    required String todayGoal,
    required DateTime expectedUpdatedAt,
    String? featuredTreeId,
    String? featuredBadgeId,
  }) async {
    saved = true;
    return data;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('edit profile draft validates and saves', (tester) async {
    final repository = _IntegrationRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EditProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-nickname')),
      '새로운닉네임',
    );
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pump();
    expect(repository.saved, isTrue);
  });
}
