import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_memory_coach/features/friends/data/repositories/friend_room_repositories.dart';
import 'package:ai_memory_coach/features/friends/domain/entities/friend_room.dart';
import 'package:ai_memory_coach/features/friends/domain/repositories/friend_room_repository.dart';
import 'package:ai_memory_coach/features/friends/presentation/controllers/friend_room_controller.dart';
import 'package:ai_memory_coach/features/friends/presentation/pages/friend_room_page.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/rank_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const capture = bool.fromEnvironment('CAPTURE_FRIEND_ROOM');
final boundaryKey = GlobalKey();

class _PendingLoadRepository implements FriendRoomRepository {
  @override
  Future<FriendRoom> loadRoom(String friendId) =>
      Completer<FriendRoom>().future;
  @override
  Future<FriendCheerResult> sendCheer({
    required String friendId,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}

Future<void> pumpPage(
  WidgetTester tester, {
  FriendRoomRepository? repository,
  String friendId = 'friend-yui',
  Size size = const Size(390, 844),
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        friendRoomRepositoryProvider.overrideWithValue(
          repository ?? MockFriendRoomRepository(loadDelay: Duration.zero),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          child: RepaintBoundary(key: boundaryKey, child: child!),
        ),
        home: FriendRoomPage(friendId: friendId, nicknameHint: '김유이'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> shot(String name) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('test/screenshots/friend_room/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
}

void main() {
  testWidgets('capture Friend Room approved states', (tester) async {
    if (!capture) return;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => RepaintBoundary(key: boundaryKey, child: child!),
        home: const RankPage(),
      ),
    );
    await tester.pumpAndSettle();
    await shot('01_friend_list');

    await pumpPage(tester, repository: _PendingLoadRepository());
    await tester.pump();
    await shot('02_visit_loading');

    await pumpPage(tester);
    await shot('03_friend_room_default');
    await shot('04_friend_status_bubble');

    await tester.tap(find.byKey(const ValueKey('friend-room-character')));
    await tester.pump();
    await shot('05_character_interaction');

    await pumpPage(tester, friendId: 'empty-room');
    await shot('06_empty_room');

    await pumpPage(tester, friendId: 'private-room');
    await shot('07_private_room');

    await pumpPage(tester, friendId: 'unavailable-room');
    await shot('08_unavailable_room');

    await pumpPage(tester, reducedMotion: true);
    await shot('09_reduced_motion');

    await pumpPage(tester, size: const Size(360, 800));
    await shot('10_friend_room_360x800');
  });
}
