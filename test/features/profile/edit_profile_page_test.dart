import 'package:ai_memory_coach/app/theme.dart';
import 'package:ai_memory_coach/features/profile/data/profile_repository.dart';
import 'package:ai_memory_coach/features/profile/domain/profile_edit_snapshot.dart';
import 'package:ai_memory_coach/features/profile/domain/profile_failure.dart';
import 'package:ai_memory_coach/features/profile/presentation/edit_profile_page.dart';
import 'package:ai_memory_coach/features/profile/presentation/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeProfileRepository implements ProfileRepository {
  var loadCount = 0;
  var saveCount = 0;
  String? savedNickname;
  Object? loadError;

  final snapshot = ProfileEditSnapshot(
    nickname: '기존닉네임',
    bio: '소개',
    todayGoal: '오늘 목표',
    updatedAt: DateTime.utc(2026, 7, 19),
    featuredTreeId: 'tree-1',
    featuredBadgeId: 'badge-1',
    trees: const [ProfileChoice(id: 'tree-1', title: '벚꽃 기억나무')],
    badges: const [ProfileChoice(id: 'badge-1', title: '기억 마스터')],
  );

  @override
  Future<ProfileEditSnapshot> load() async {
    loadCount++;
    final error = loadError;
    if (error != null) throw error;
    return snapshot;
  }

  @override
  Future<ProfileEditSnapshot> save({
    required String nickname,
    required String bio,
    required String todayGoal,
    required DateTime expectedUpdatedAt,
    String? featuredTreeId,
    String? featuredBadgeId,
  }) async {
    saveCount++;
    savedNickname = nickname;
    return snapshot;
  }
}

Widget _app(_FakeProfileRepository repository) {
  final router = GoRouter(
    initialLocation: EditProfilePage.routePath,
    routes: [
      GoRoute(
        path: EditProfilePage.routePath,
        builder: (_, _) => const EditProfilePage(),
      ),
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
    ],
  );
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(repository),
      profileEditProvider.overrideWith((ref) => repository.load()),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

void main() {
  testWidgets('shows read-only character preview and coming-soon dialog', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.text('기존닉네임'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('character-preview')));
    await tester.pumpAndSettle();
    expect(find.text('준비 중인 기능입니다.'), findsOneWidget);
  });

  testWidgets('accepts 30-character nickname and submits once', (tester) async {
    final repository = _FakeProfileRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    final nickname = '가' * 30;
    await tester.enterText(
      find.byKey(const ValueKey('profile-nickname')),
      nickname,
    );
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pump();

    expect(repository.saveCount, 1);
    expect(repository.savedNickname, nickname);
  });

  testWidgets('rejects a one-character nickname', (tester) async {
    final repository = _FakeProfileRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('profile-nickname')), '가');
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pump();

    expect(find.text('닉네임은 2~30자로 입력해 주세요.'), findsOneWidget);
    expect(repository.saveCount, 0);
  });

  testWidgets('keeps header and back navigation when loading fails', (
    tester,
  ) async {
    final repository = _FakeProfileRepository()
      ..loadError = const ProfileFailure(
        ProfileFailureKind.network,
        '인터넷 연결을 확인한 뒤 다시 시도해 주세요.',
        operation: 'get_my_edit_profile',
      );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('프로필 수정'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('인터넷 연결을 확인한 뒤 다시 시도해 주세요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-retry')), findsOneWidget);
  });

  testWidgets('retry reloads only profile data and restores the form', (
    tester,
  ) async {
    final repository = _FakeProfileRepository()
      ..loadError = const ProfileFailure(
        ProfileFailureKind.server,
        '프로필 서비스를 불러오지 못했습니다.',
        operation: 'get_my_edit_profile',
      );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    repository.loadError = null;
    await tester.tap(find.byKey(const ValueKey('profile-retry')));
    await tester.pumpAndSettle();

    expect(repository.loadCount, 2);
    expect(find.text('기존닉네임'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
  });

  testWidgets('shows parsing failure without exposing internal details', (
    tester,
  ) async {
    final repository = _FakeProfileRepository()
      ..loadError = const ProfileFailure(
        ProfileFailureKind.parsing,
        '프로필 정보를 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.',
        operation: 'get_my_edit_profile',
      );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('프로필 정보를 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expect(find.textContaining('profile_response_'), findsNothing);
  });
}
