import 'package:ai_memory_coach/features/friends/data/repositories/friend_room_repositories.dart';
import 'package:ai_memory_coach/features/friends/presentation/controllers/friend_room_controller.dart';
import 'package:ai_memory_coach/features/friends/presentation/pages/friend_room_page.dart';
import 'package:ai_memory_coach/shared/design_system/mameroom_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRoom(
    WidgetTester tester, {
    String friendId = 'friend-yui',
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendRoomRepositoryProvider.overrideWithValue(
            MockFriendRoomRepository(loadDelay: Duration.zero),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [MameroomTheme.light]),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: FriendRoomPage(friendId: friendId, nicknameHint: '김유이'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders Friend Room as read-only MVP', (tester) async {
    await pumpRoom(tester);

    expect(find.byKey(const ValueKey('friend-room-character')), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-room-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-cheer-button')), findsNothing);
    expect(find.byKey(const ValueKey('friend-furniture-action')), findsNothing);
    expect(find.byKey(const ValueKey('friend-profile-button')), findsNothing);
    expect(find.textContaining('M-Coin'), findsNothing);
    expect(find.text('기억률'), findsNothing);
    expect(find.text('연속 학습'), findsNothing);
    expect(find.text('학교'), findsNothing);
  });

  testWidgets('renders private and unavailable states without room content', (
    tester,
  ) async {
    await pumpRoom(tester, friendId: 'private-room');
    expect(find.byKey(const ValueKey('friend-room-private')), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-room-character')), findsNothing);

    await pumpRoom(tester, friendId: 'unavailable-room');
    expect(
      find.byKey(const ValueKey('friend-room-unavailable')),
      findsOneWidget,
    );
  });

  testWidgets('small screen and 1.3 text scale do not overflow', (
    tester,
  ) async {
    await pumpRoom(tester, size: const Size(320, 700), textScale: 1.3);
    expect(tester.takeException(), isNull);
  });
}
