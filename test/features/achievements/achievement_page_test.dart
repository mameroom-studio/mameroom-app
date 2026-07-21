import 'package:ai_memory_coach/features/achievements/domain/entities/achievement.dart';
import 'package:ai_memory_coach/features/achievements/domain/entities/achievement_failure.dart';
import 'package:ai_memory_coach/features/auth/domain/entities/app_user.dart';
import 'package:ai_memory_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/home_shell_page.dart';
import 'package:ai_memory_coach/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:ai_memory_coach/features/achievements/presentation/pages/achievement_page.dart';
import 'package:ai_memory_coach/features/achievements/presentation/providers/achievement_providers.dart';
import 'package:ai_memory_coach/features/coins/domain/entities/coin_wallet.dart';
import 'package:ai_memory_coach/features/coins/presentation/providers/coin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('filters cards by the confirmed six-category policy', (
    tester,
  ) async {
    final repository = _FakeAchievementRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AsyncData(AppUser(id: 'achievement-user', email: null)),
          ),
          achievementRepositoryProvider.overrideWithValue(repository),
          coinWalletProvider.overrideWith((_) async => CoinWallet.empty),
        ],
        child: const MaterialApp(home: AchievementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('첫 복습'), findsOneWidget);
    expect(find.text('첫 친구'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('achievement-category-review')));
    await tester.pump();

    expect(find.text('첫 복습'), findsOneWidget);
    expect(find.text('첫 친구'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long text and large scale do not overflow on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AsyncData(AppUser(id: 'achievement-user', email: null)),
          ),
          achievementRepositoryProvider.overrideWithValue(
            _FakeAchievementRepository(),
          ),
          coinWalletProvider.overrideWith((_) async => CoinWallet.empty),
        ],
        child: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(home: AchievementPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('achievement list opens scoped detail and back restores list', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AchievementPage.routePath,
      routes: [
        GoRoute(
          path: AchievementPage.routePath,
          builder: (_, _) => const AchievementPage(),
        ),
        GoRoute(
          path: '${AchievementDetailPage.routePrefix}/:code',
          builder: (_, state) =>
              AchievementDetailPage(code: state.pathParameters['code']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AsyncData(AppUser(id: 'achievement-user', email: null)),
          ),
          achievementRepositoryProvider.overrideWithValue(
            _FakeAchievementRepository(),
          ),
          coinWalletProvider.overrideWith((_) async => CoinWallet.empty),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('achievement-card-review_first'));
    await tester.ensureVisible(card);
    final cardTap = find.descendant(of: card, matching: find.byType(InkWell));
    tester.widget<InkWell>(cardTap).onTap!();
    await tester.pumpAndSettle();
    expect(find.byType(AchievementDetailPage), findsOneWidget);
    expect(router.canPop(), isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AchievementDetailPage), findsNothing);
    expect(card, findsOneWidget);
  });

  testWidgets('empty overview renders guided state and Study CTA', (
    tester,
  ) async {
    final repository = _FakeAchievementRepository()..empty = true;
    final router = GoRouter(
      initialLocation: AchievementPage.routePath,
      routes: [
        GoRoute(
          path: AchievementPage.routePath,
          builder: (_, _) => const AchievementPage(),
        ),
        GoRoute(
          path: HomeShellPage.studyRoutePath,
          builder: (_, _) => const Text('STUDY_DESTINATION'),
        ),
        GoRoute(
          path: HomeShellPage.myInfoRoutePath,
          builder: (_, _) => const Text('MY_DESTINATION'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AsyncData(AppUser(id: 'achievement-user', email: null)),
          ),
          achievementRepositoryProvider.overrideWithValue(repository),
          coinWalletProvider.overrideWith((_) async => CoinWallet.empty),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('업적'), findsOneWidget);
    expect(find.text('아직 기록된 업적이 없어요'), findsOneWidget);
    await tester.tap(find.text('공부 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('STUDY_DESTINATION'), findsOneWidget);
  });

  testWidgets('temporary failure keeps header and explicit retry succeeds', (
    tester,
  ) async {
    final repository = _FakeAchievementRepository()
      ..loadError = const AchievementFailure(
        AchievementFailureKind.server,
        '업적을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
        operation: 'get_achievement_overview',
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AsyncData(AppUser(id: 'achievement-user', email: null)),
          ),
          achievementRepositoryProvider.overrideWithValue(repository),
          coinWalletProvider.overrideWith((_) async => CoinWallet.empty),
        ],
        child: const MaterialApp(home: AchievementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('업적'), findsOneWidget);
    expect(find.text('업적을 불러오지 못했어요.'), findsOneWidget);
    expect(repository.loadCount, 1);
    repository.loadError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(repository.loadCount, 2);
    expect(find.text('첫 복습'), findsOneWidget);
  });

  testWidgets('unauthenticated state is distinct from network failure', (
    tester,
  ) async {
    final repository = _FakeAchievementRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(const AsyncData(null)),
          achievementRepositoryProvider.overrideWithValue(repository),
          coinWalletProvider.overrideWith((_) async => CoinWallet.empty),
        ],
        child: const MaterialApp(home: AchievementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('업적'), findsOneWidget);
    expect(find.text('로그인 정보를 확인할 수 없어요'), findsOneWidget);
    expect(repository.loadCount, 0);
  });
}

class _FakeAchievementRepository implements AchievementRepository {
  int loadCount = 0;
  bool empty = false;
  Object? loadError;
  final items = const [
    Achievement(
      code: 'review_first',
      title: '첫 복습',
      description: '기억을 오래 지키기 위한 첫 복습을 아주 차분하게 완료해요',
      category: AchievementCategory.review,
      status: AchievementStatus.inProgress,
      current: 1,
      target: 3,
      condition: '복습 3회 완료',
      rewards: [
        AchievementReward(
          type: AchievementRewardType.mCoin,
          label: 'M-Coin',
          amount: 30,
        ),
      ],
    ),
    Achievement(
      code: 'friend_first',
      title: '첫 친구',
      description: '친구 한 명과 연결하기',
      category: AchievementCategory.friends,
      status: AchievementStatus.rewarded,
      current: 1,
      target: 1,
      condition: '친구 1명 추가',
      rewards: [
        AchievementReward(
          type: AchievementRewardType.badge,
          label: '새싹 친구',
          delivered: true,
        ),
      ],
    ),
  ];

  @override
  Future<AchievementOverview> loadOverview() async {
    loadCount++;
    final error = loadError;
    if (error != null) throw error;
    if (empty) {
      return const AchievementOverview(
        summary: AchievementSummary(
          completed: 0,
          total: 0,
          badgeCount: 0,
          nextAchievement: null,
        ),
        achievements: [],
      );
    }
    return AchievementOverview(
      summary: AchievementSummary(
        completed: 1,
        total: 2,
        badgeCount: 1,
        nextAchievement: items.first,
      ),
      achievements: items,
    );
  }

  @override
  Future<Achievement> loadAchievement(String code) async =>
      items.firstWhere((item) => item.code == code);

  @override
  Future<Achievement> refreshRewardState(String code) => loadAchievement(code);
}
