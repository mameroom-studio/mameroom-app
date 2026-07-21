import 'package:ai_memory_coach/features/friends/domain/entities/friend_profile.dart';
import 'package:ai_memory_coach/features/friends/domain/repositories/friends_repository.dart';
import 'package:ai_memory_coach/features/friends/presentation/controllers/friends_controller.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/home_shell_page.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/rank_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Friends MVP hides competitive UI and profile summary', (
    tester,
  ) async {
    await _pumpPage(tester, _MvpFriendsRepository());

    expect(find.text('친구'), findsWidgets);
    expect(find.text('활동'), findsNothing);
    expect(find.text('랭킹'), findsNothing);
    expect(find.text('학교'), findsNothing);
    expect(find.text('연속 학습'), findsNothing);
    expect(find.text('이번 주 시간'), findsNothing);
    expect(find.text('기억률'), findsNothing);
    expect(find.text('내 친구'), findsOneWidget);
    expect(find.text('방문하기'), findsOneWidget);
  });

  testWidgets('empty Friends MVP renders policy copy and CTA', (tester) async {
    await _pumpPage(tester, _MvpFriendsRepository(friends: const []));

    expect(find.text('아직 추가한 친구가 없어요'), findsOneWidget);
    expect(find.text('함께 공부할 친구를 찾아 서로의 방을 구경해 보세요.'), findsOneWidget);
    expect(find.text('친구 찾기'), findsOneWidget);
  });

  testWidgets('Friends MVP fits 320px at 1.3 text scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(
      TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues,
    );

    await _pumpPage(tester, _MvpFriendsRepository(), textScale: 1.3);

    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell keeps friends bottom navigation destination', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeShellPage(selectedIndex: 2, child: SizedBox.shrink()),
      ),
    );
    expect(find.text('친구'), findsOneWidget);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  FriendsRepository repository, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [friendsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const RankPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MvpFriendsRepository implements FriendsRepository {
  _MvpFriendsRepository({List<FriendProfile>? friends})
    : _friends = friends ?? const [_friend];

  final List<FriendProfile> _friends;

  @override
  Future<List<FriendProfile>> friends() async => _friends;
  @override
  Future<List<FriendProfile>> incomingRequests() async => const [];
  @override
  Future<List<FriendProfile>> recommended() async => const [];
  @override
  Future<FriendPage<FriendProfile>> search({
    required String query,
    String? cursor,
  }) async => const FriendPage(items: []);
  @override
  Future<FriendProfile> sendRequest(String userId) async => _friend;
  @override
  Future<void> respondToRequest(
    String requestId, {
    required bool accept,
  }) async {}
  @override
  Future<void> cancelRequest(String requestId) async {}
  @override
  Future<void> deleteFriend(String userId) async {}
  @override
  Future<void> blockUser(String userId) async {}
  @override
  Future<void> unblockUser(String userId) async {}
}

const _friend = FriendProfile(
  id: 'friend-1',
  nickname: '긴닉네임친구사용자테스트',
  friendCode: 'AB12CD',
  level: 123,
  statusMessage: '민감한 학습 상태',
  relationship: FriendRelationshipState.accepted,
  roomVisibility: FriendRoomVisibility.friends,
);
