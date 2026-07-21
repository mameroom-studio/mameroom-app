import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../data/repositories/friend_room_repositories.dart';
import '../../data/repositories/supabase_friend_room_repository.dart';
import '../../domain/entities/friend_room.dart';
import '../controllers/friend_room_controller.dart';
import '../widgets/friend_room_widgets.dart';

class FriendRoomPage extends ConsumerWidget {
  const FriendRoomPage({
    super.key,
    required this.friendId,
    this.nicknameHint = '',
  });

  static const routePath = '/friends/:friendId/room';
  final String friendId;
  final String nicknameHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendRoomControllerProvider(friendId));
    final controller = ref.read(
      friendRoomControllerProvider(friendId).notifier,
    );
    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(MameroomSpacing.sm),
              child: state.when(
                loading: () => FriendRoomVisitLoader(nickname: nicknameHint),
                error: (error, _) => FriendRoomAccessState(
                  visitState: error is FriendRoomAccessDeniedException
                      ? FriendRoomVisitState.private
                      : error is FriendRoomUnavailableException
                      ? FriendRoomVisitState.unavailable
                      : FriendRoomVisitState.failed,
                  onBack: () => Navigator.of(context).maybePop(),
                  onRetry: error is FriendRoomNotFoundException
                      ? null
                      : controller.load,
                ),
                data: (value) => _FriendRoomContent(
                  value: value,
                  onBack: () => Navigator.of(context).maybePop(),
                  onCharacterTap: controller.interactWithCharacter,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendRoomContent extends StatelessWidget {
  const _FriendRoomContent({
    required this.value,
    required this.onBack,
    required this.onCharacterTap,
  });

  final FriendRoomState value;
  final VoidCallback onBack;
  final VoidCallback onCharacterTap;

  @override
  Widget build(BuildContext context) {
    final room = value.room;
    if (room.visitState == FriendRoomVisitState.private ||
        room.visitState == FriendRoomVisitState.unavailable) {
      return Column(
        children: [
          FriendRoomHeader(
            title: room.roomTitle,
            onBack: onBack,
            onProfile: null,
          ),
          const SizedBox(height: MameroomSpacing.sm),
          Expanded(
            child: FriendRoomAccessState(
              visitState: room.visitState,
              onBack: onBack,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FriendRoomHeader(
          title: room.roomTitle,
          onBack: onBack,
          onProfile: null,
        ),
        const SizedBox(height: MameroomSpacing.xs),
        Row(
          children: [
            FriendRoomVisitBadge(state: room.visitState),
            const SizedBox(width: MameroomSpacing.xs),
            Expanded(
              child: Text(
                '친구가 꾸민 공부방을 구경해 보세요.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.mameroom.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: MameroomSpacing.xs),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('friend-room-scroll'),
            child: FriendRoomCanvas(
              room: room,
              capabilities: RoomCapabilities.friendReadOnly,
              characterMessage: value.characterMessage,
              reducedMotion: MediaQuery.disableAnimationsOf(context),
              onCharacterTap: onCharacterTap,
              onFurnitureTap: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}
