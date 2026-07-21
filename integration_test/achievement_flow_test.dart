import 'package:ai_memory_coach/features/achievements/domain/entities/achievement.dart';
import 'package:ai_memory_coach/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:ai_memory_coach/features/achievements/presentation/pages/achievement_page.dart';
import 'package:ai_memory_coach/features/achievements/presentation/providers/achievement_providers.dart';
import 'package:ai_memory_coach/features/coins/domain/entities/coin_wallet.dart';
import 'package:ai_memory_coach/features/coins/presentation/providers/coin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('achievement category and detail flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          achievementRepositoryProvider.overrideWithValue(
            _IntegrationRepository(),
          ),
          coinWalletProvider.overrideWith((_) async => CoinWallet.empty),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('복습'));
    await tester.pump();
    expect(find.text('복습 첫걸음'), findsOneWidget);
    await tester.tap(find.text('복습 첫걸음'));
    await tester.pumpAndSettle();
    expect(find.text('달성 조건'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('복습 첫걸음'), findsOneWidget);
    expect(find.text('달성 조건'), findsNothing);
  });
}

class _IntegrationRepository implements AchievementRepository {
  static const item = Achievement(
    code: 'review_first',
    title: '복습 첫걸음',
    description: '첫 복습을 완료해요',
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
  );
  @override
  Future<AchievementOverview> loadOverview() async => const AchievementOverview(
    summary: AchievementSummary(
      completed: 0,
      total: 1,
      badgeCount: 0,
      nextAchievement: item,
    ),
    achievements: [item],
  );
  @override
  Future<Achievement> loadAchievement(String code) async => item;
  @override
  Future<Achievement> refreshRewardState(String code) async => item;
}
