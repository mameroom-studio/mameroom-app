import 'package:ai_memory_coach/app/router.dart';
import 'package:ai_memory_coach/features/achievements/presentation/pages/achievement_page.dart';
import 'package:ai_memory_coach/features/auth/domain/entities/app_user.dart';
import 'package:ai_memory_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:ai_memory_coach/features/notices/presentation/notice_list_page.dart';
import 'package:ai_memory_coach/features/notifications/presentation/pages/mameroom_notification_page.dart';
import 'package:ai_memory_coach/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:ai_memory_coach/features/promotions/presentation/promotion_code_page.dart';
import 'package:ai_memory_coach/features/settings/presentation/version_info_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('static routes are not captured by achievement detail', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(
          const AsyncData(
            AppUser(id: 'route-contract-user', email: 'route@test.dev'),
          ),
        ),
        hasSeenOnboardingProvider.overrideWithValue(const AsyncData(true)),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    final contracts = <String, String>{
      MameroomNotificationPage.routePath: MameroomNotificationPage.routePath,
      NoticeListPage.routePath: NoticeListPage.routePath,
      PromotionCodePage.routePath: PromotionCodePage.routePath,
      VersionInfoPage.routePath: VersionInfoPage.routePath,
    };

    for (final entry in contracts.entries) {
      expect(
        _matchedRoutePath(router, entry.key),
        entry.value,
        reason: entry.key,
      );
    }
    expect(
      _matchedRoutePath(
        router,
        '${AchievementDetailPage.routePrefix}/review_first',
      ),
      '${AchievementDetailPage.routePrefix}/:code',
    );
  });
}

String _matchedRoutePath(GoRouter router, String location) {
  final match = router.configuration
      .findMatch(Uri.parse(location))
      .matches
      .last;
  return (match.route as GoRoute).path;
}
