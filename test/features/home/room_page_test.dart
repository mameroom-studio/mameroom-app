import 'package:ai_memory_coach/features/coins/domain/entities/coin_wallet.dart';
import 'package:ai_memory_coach/features/coins/presentation/providers/coin_providers.dart';
import 'package:ai_memory_coach/features/gamification/domain/entities/room_item.dart';
import 'package:ai_memory_coach/features/gamification/presentation/pages/room_page.dart';
import 'package:ai_memory_coach/features/gamification/presentation/pages/shop_page.dart';
import 'package:ai_memory_coach/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/home_shell_page.dart';
import 'package:ai_memory_coach/features/library/presentation/providers/library_mock_providers.dart';
import 'package:ai_memory_coach/features/review/presentation/pages/review_page.dart';
import 'package:ai_memory_coach/features/streak/domain/entities/streak_state.dart';
import 'package:ai_memory_coach/features/streak/presentation/providers/streak_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeRoomController extends MyRoomController {
  _FakeRoomController(super.ref, this.seedState) {
    state = AsyncData(seedState);
  }

  final MyRoomState seedState;

  @override
  Future<void> load() async {
    state = AsyncData(seedState);
  }
}

const _desk = RoomItem(
  id: 'desk',
  itemCode: 'wood_desk',
  name: '책상',
  description: 'Desk',
  itemType: 'desk',
  rarity: 'common',
  price: 100,
  assetKey: 'desk',
  assetPath: 'desk.png',
  defaultPositionX: 0.72,
  defaultPositionY: 0.56,
  isActive: true,
);

const _emptyRoom = MyRoomState(
  walletBalance: 3200,
  shopItems: [_desk],
  ownedItemIds: {'desk'},
  layouts: [],
);

const _placedRoom = MyRoomState(
  walletBalance: 3200,
  shopItems: [_desk],
  ownedItemIds: {'desk'},
  layouts: [
    UserRoomLayout(
      id: 'layout-desk',
      item: _desk,
      positionX: 0.72,
      positionY: 0.56,
    ),
  ],
);

Widget _roomApp({MyRoomState room = _emptyRoom}) {
  final router = GoRouter(
    initialLocation: RoomPage.routePath,
    routes: [
      GoRoute(
        path: HomeShellPage.homeRoutePath,
        builder: (context, state) => const HomeTabRoute(),
      ),
      GoRoute(
        path: RoomPage.routePath,
        builder: (context, state) => const RoomPage(),
      ),
      GoRoute(
        path: ShopPage.routePath,
        builder: (context, state) => const Scaffold(body: Text('shop-page')),
      ),
      GoRoute(
        path: ReviewPage.routePath,
        builder: (context, state) => const Scaffold(body: Text('review-start')),
      ),
    ],
  );

  return ProviderScope(
    overrides: _overrides(room),
    child: MaterialApp.router(routerConfig: router),
  );
}

Widget _homeApp({MyRoomState room = _placedRoom}) {
  final router = GoRouter(
    initialLocation: HomeShellPage.homeRoutePath,
    routes: [
      GoRoute(
        path: HomeShellPage.homeRoutePath,
        builder: (context, state) => const HomeTabRoute(),
      ),
      GoRoute(
        path: RoomPage.routePath,
        builder: (context, state) => const RoomPage(),
      ),
      GoRoute(
        path: ShopPage.routePath,
        builder: (context, state) => const Scaffold(body: Text('shop-page')),
      ),
      GoRoute(
        path: ReviewPage.routePath,
        builder: (context, state) => const Scaffold(body: Text('review-start')),
      ),
    ],
  );

  return ProviderScope(
    overrides: _overrides(room),
    child: MaterialApp.router(routerConfig: router),
  );
}

// ignore: strict_top_level_inference
// ignore: strict_top_level_inference
_overrides(MyRoomState room) {
  return [
    myRoomControllerProvider.overrideWith(
      (ref) => _FakeRoomController(ref, room),
    ),
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
  ];
}

Future<void> _pumpAt(WidgetTester tester, Widget app, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
    'room editor renders game-like default room and compact controls',
    (tester) async {
      await _pumpAt(tester, _roomApp(), const Size(390, 844));

      expect(find.text('방 꾸미기'), findsOneWidget);
      expect(find.text('M-Coin'), findsOneWidget);
      expect(find.text('배치중'), findsOneWidget);
      for (final key in [
        'default-bed',
        'default-desk',
        'default-chair',
        'default-rug',
        'default-window',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      expect(find.text('상점에서 가구를 구매하세요.'), findsNothing);
      expect(find.text('상점'), findsOneWidget);
      expect(find.text('가구 이동'), findsNothing);
      expect(find.text('보관함'), findsNothing);
      expect(find.text('편집'), findsOneWidget);

      await tester.tap(find.text('편집'));
      await tester.pumpAndSettle();

      for (final label in ['이동', '회전', '보관', '삭제', '완료']) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets('room editor item selection highlights selected furniture', (
    tester,
  ) async {
    await _pumpAt(tester, _roomApp(), const Size(390, 844));

    await tester.tap(find.text('책상').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('default-desk')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in <Size>[
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('room editor has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      await _pumpAt(tester, _roomApp(), size);
      await tester.tap(find.text('편집'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home decorate opens room editor and done returns home', (
    tester,
  ) async {
    await _pumpAt(tester, _homeApp(), const Size(390, 844));

    await tester.tap(find.text('꾸미기'));
    await tester.pumpAndSettle();
    expect(find.text('방 꾸미기'), findsOneWidget);

    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(find.text('MAMEROOM'), findsOneWidget);
    expect(find.text('꾸미기'), findsOneWidget);
  });
}
