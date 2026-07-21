import 'package:ai_memory_coach/features/coins/domain/entities/coin_wallet.dart';
import 'package:ai_memory_coach/features/coins/presentation/providers/coin_providers.dart';
import 'package:ai_memory_coach/features/gamification/domain/entities/room_item.dart';
import 'package:ai_memory_coach/features/gamification/presentation/pages/room_page.dart';
import 'package:ai_memory_coach/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/home_shell_page.dart';
import 'package:ai_memory_coach/features/home/domain/entities/next_study_action.dart';
import 'package:ai_memory_coach/features/home/presentation/providers/next_study_providers.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/learning_report_page.dart';
import 'package:ai_memory_coach/features/library/presentation/providers/library_mock_providers.dart';
import 'package:ai_memory_coach/features/notifications/presentation/widgets/mameroom_notification_badge.dart';
import 'package:ai_memory_coach/features/review/presentation/pages/review_page.dart';
import 'package:ai_memory_coach/features/streak/domain/entities/streak_state.dart';
import 'package:ai_memory_coach/features/streak/presentation/providers/streak_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeRoomController extends MyRoomController {
  _FakeRoomController(super.ref) {
    state = const AsyncData(
      MyRoomState(
        walletBalance: 3200,
        shopItems: [_desk],
        ownedItemIds: {'desk'},
        layouts: [
          UserRoomLayout(
            id: 'layout-desk',
            item: _desk,
            positionX: 0.42,
            positionY: 0.62,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> load() async {}
}

const _desk = RoomItem(
  id: 'desk',
  itemCode: 'wood_desk',
  name: 'Wood Desk',
  description: 'Desk',
  itemType: 'desk',
  rarity: 'common',
  price: 100,
  assetKey: 'desk',
  assetPath: 'desk.png',
  defaultPositionX: 0.5,
  defaultPositionY: 0.5,
  isActive: true,
);

Widget _homeApp() {
  final router = GoRouter(
    initialLocation: HomeShellPage.homeRoutePath,
    routes: [
      GoRoute(
        path: HomeShellPage.homeRoutePath,
        builder: (context, state) => const HomeTabRoute(),
      ),
      GoRoute(
        path: RoomPage.routePath,
        builder: (context, state) => const Scaffold(body: Text('room-editor')),
      ),
      GoRoute(
        path: ReviewPage.routePath,
        builder: (context, state) => const Scaffold(body: Text('review-start')),
      ),
      GoRoute(
        path: LearningReportPage.routePath,
        builder: (context, state) => const LearningReportPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const Scaffold(body: Text('notification-page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      libraryDashboardProvider.overrideWith((ref) async {
        return const LibraryDashboard(
          todayReviewCount: 17,
          totalMemoryPercent: 84,
          materials: [],
          recentRecords: [],
        );
      }),
      coinWalletProvider.overrideWith((ref) async {
        return const CoinWallet(
          balance: 1280,
          totalEarned: 2000,
          totalSpent: 720,
          todayEarned: 80,
        );
      }),
      streakProvider.overrideWith((ref) async {
        return const StreakState(
          currentStreak: 7,
          maxStreak: 11,
          milestoneReward: 0,
          walletBalance: 1280,
        );
      }),
      myRoomControllerProvider.overrideWith((ref) => _FakeRoomController(ref)),
      dueReviewCountProvider.overrideWith((ref) async => 17),
      nextStudyActionResolverProvider.overrideWith(
        (ref) =>
            () async => const StartReview(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('home dashboard is single-screen and hides diamonds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.text('MAMEROOM'), findsOneWidget);
    expect(find.text('\uC624\uB298\uC758 \uD559\uC2B5'), findsOneWidget);
    expect(find.text('\uACF5\uBD80 \uC2DC\uC791\uD558\uAE30'), findsOneWidget);
    expect(find.text('\uB0B4 \uD559\uC2B5'), findsOneWidget);
    expect(find.text('Diamond'), findsNothing);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('home primary actions route to room editor and study flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('\uAFB8\uBBF8\uAE30'));
    await tester.pumpAndSettle();
    expect(find.text('room-editor'), findsOneWidget);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('\uACF5\uBD80 \uC2DC\uC791\uD558\uAE30'));
    await tester.pumpAndSettle();
    expect(find.text('review-start'), findsOneWidget);
  });

  testWidgets('home learning report card opens detail page', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('\uB0B4 \uD559\uC2B5'));
    await tester.pumpAndSettle();

    expect(find.text('\uC8FC\uAC04'), findsOneWidget);
    expect(find.text('\uC624\uB298 \uC694\uC57D'), findsOneWidget);
    expect(find.text('\uB0B4 \uD559\uC2B5'), findsWidgets);
  });
  testWidgets('home notification opens notifications and back restores home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    final badge = tester.widget<MameroomNotificationBadge>(
      find.byType(MameroomNotificationBadge),
    );
    expect(badge.count, greaterThan(0));
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();

    expect(find.text('notification-page'), findsOneWidget);
    expect(find.text('MAMEROOM'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('notification-page'), findsNothing);
    expect(find.text('MAMEROOM'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
}
