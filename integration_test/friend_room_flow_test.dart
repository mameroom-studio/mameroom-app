import 'package:ai_memory_coach/features/friends/data/repositories/friend_room_repositories.dart';
import 'package:ai_memory_coach/features/friends/presentation/controllers/friend_room_controller.dart';
import 'package:ai_memory_coach/features/friends/presentation/pages/friend_room_page.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/rank_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('friends room complete read-only visit flow', (tester) async {
    final router = GoRouter(
      initialLocation: '/friends',
      routes: [
        GoRoute(path: '/friends', builder: (_, _) => const RankPage()),
        GoRoute(
          path: FriendRoomPage.routePath,
          builder: (_, state) => FriendRoomPage(
            friendId: state.pathParameters['friendId'] ?? '',
            nicknameHint: state.uri.queryParameters['nickname'] ?? '',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendRoomRepositoryProvider.overrideWithValue(
            MockFriendRoomRepository(loadDelay: Duration.zero),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Room 방문').first);
    await tester.pumpAndSettle();
    expect(find.text('김유이의 방'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('friend-room-character')));
    await tester.pump();
    expect(find.text('어서 와요!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('friend-furniture-action')));
    await tester.pumpAndSettle();
    expect(find.text('기본 책장'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('friend-profile-action')));
    await tester.pumpAndSettle();
    expect(find.text('친구 추가'), findsNothing);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('friend-cheer-button')));
    await tester.pumpAndSettle();
    expect(find.text('오늘 응원 완료'), findsOneWidget);
    expect(find.text('M-Coin +5'), findsOneWidget);
    await tester.tap(find.byTooltip('친구 목록으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('친구 목록'), findsOneWidget);
  });
}
