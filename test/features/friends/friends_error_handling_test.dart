import 'package:ai_memory_coach/features/friends/domain/entities/friend_profile.dart';
import 'package:ai_memory_coach/features/friends/domain/entities/friends_failure.dart';
import 'package:ai_memory_coach/features/friends/domain/repositories/friends_repository.dart';
import 'package:ai_memory_coach/features/friends/presentation/controllers/friends_controller.dart';
import 'package:ai_memory_coach/features/friends/presentation/widgets/friends_list_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overview loads only friends and incoming for MVP', () async {
    final repository = _FriendsRepository();
    final controller = FriendsController(repository);
    addTearDown(controller.dispose);

    await controller.loadOverview();

    expect(repository.friendsCalls, 1);
    expect(repository.incomingCalls, 1);
    expect(repository.recommendedCalls, 0);
  });

  testWidgets('friends failure preserves successful incoming section', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      _FriendsRepository(
        friendsError: const FriendsFailure(
          FriendsFailureKind.schema,
          'safe message',
          operation: 'list_friend_profiles:friends',
        ),
        incoming: const [_incoming],
      ),
    );

    expect(find.byKey(const ValueKey('friends-section-error')), findsOneWidget);
    expect(find.text('친구 목록을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('받은 친구 요청'), findsOneWidget);
    expect(find.text('요청친구'), findsOneWidget);
  });

  testWidgets('incoming failure preserves successful friends section', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      _FriendsRepository(
        incomingError: const FriendsFailure(
          FriendsFailureKind.authorization,
          'safe message',
          operation: 'list_friend_profiles:incoming',
        ),
        friends: const [_friend],
      ),
    );

    expect(
      find.byKey(const ValueKey('incoming-section-error')),
      findsOneWidget,
    );
    expect(find.text('친구목록사용자'), findsOneWidget);
    expect(find.text('방문하기'), findsOneWidget);
  });

  testWidgets('accept and reject update only the request card', (tester) async {
    final repository = _FriendsRepository(incoming: const [_incoming]);
    await _pumpPanel(tester, repository);

    await tester.tap(find.text('수락'));
    await tester.pumpAndSettle();
    expect(repository.acceptCalls, 1);
    expect(find.text('요청친구'), findsNothing);
    expect(find.text('친구목록사용자'), findsOneWidget);
  });

  testWidgets('delete requires confirmation and refreshes list', (
    tester,
  ) async {
    final repository = _FriendsRepository(friends: const [_friend]);
    await _pumpPanel(tester, repository);

    await tester.tap(find.byTooltip('친구 관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('친구 삭제').last);
    await tester.pumpAndSettle();

    expect(find.text('친구를 삭제할까요?'), findsOneWidget);
    expect(find.text('삭제하면 서로의 방을 방문할 수 없어요.'), findsOneWidget);

    await tester.tap(find.text('친구 삭제').last);
    await tester.pumpAndSettle();
    expect(repository.deleteCalls, 1);
    expect(find.text('아직 추가한 친구가 없어요'), findsOneWidget);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester,
  FriendsRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [friendsRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: Scaffold(body: FriendsListPanel())),
    ),
  );
  await tester.pumpAndSettle();
}

class _FriendsRepository implements FriendsRepository {
  _FriendsRepository({
    this.friendsError,
    this.incomingError,
    List<FriendProfile>? friends,
    List<FriendProfile>? incoming,
  }) : _friends = [...?friends],
       _incoming = [...?incoming];

  final Object? friendsError;
  final Object? incomingError;
  final List<FriendProfile> _friends;
  final List<FriendProfile> _incoming;
  int friendsCalls = 0;
  int incomingCalls = 0;
  int recommendedCalls = 0;
  int acceptCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<FriendProfile>> friends() async {
    friendsCalls++;
    if (friendsError != null) throw friendsError!;
    return [..._friends];
  }

  @override
  Future<List<FriendProfile>> incomingRequests() async {
    incomingCalls++;
    if (incomingError != null) throw incomingError!;
    return [..._incoming];
  }

  @override
  Future<List<FriendProfile>> recommended() async {
    recommendedCalls++;
    return const [];
  }

  @override
  Future<void> respondToRequest(
    String requestId, {
    required bool accept,
  }) async {
    _incoming.removeAt(0);
    if (accept) {
      acceptCalls++;
      _friends.add(
        _friend.copyWith(
          relationship: FriendRelationshipState.accepted,
          requestId: null,
        ),
      );
    }
  }

  @override
  Future<void> deleteFriend(String userId) async {
    deleteCalls++;
    _friends.removeWhere((item) => item.id == userId);
  }

  @override
  Future<FriendPage<FriendProfile>> search({
    required String query,
    String? cursor,
  }) async => const FriendPage(items: []);
  @override
  Future<FriendProfile> sendRequest(String userId) async => _friend;
  @override
  Future<void> cancelRequest(String requestId) async {}
  @override
  Future<void> blockUser(String userId) async {}
  @override
  Future<void> unblockUser(String userId) async {}
}

const _friend = FriendProfile(
  id: 'friend-1',
  nickname: '친구목록사용자',
  friendCode: 'AB12CD',
  level: 123,
  statusMessage: '노출 금지 학습 상태',
  relationship: FriendRelationshipState.accepted,
  roomVisibility: FriendRoomVisibility.friends,
);

const _incoming = FriendProfile(
  id: 'incoming-1',
  nickname: '요청친구',
  friendCode: 'EF34GH',
  level: 19,
  statusMessage: '노출 금지 학습 상태',
  relationship: FriendRelationshipState.incomingPending,
  roomVisibility: FriendRoomVisibility.friends,
  requestId: 'request-1',
);
