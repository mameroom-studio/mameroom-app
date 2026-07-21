import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../domain/entities/friend_profile.dart';
import '../controllers/friends_controller.dart';
import '../pages/friend_room_page.dart';
import '../pages/friend_search_page.dart';

class FriendsListPanel extends ConsumerWidget {
  const FriendsListPanel({super.key, this.forceEmpty = false});

  final bool forceEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsControllerProvider);
    final controller = ref.read(friendsControllerProvider.notifier);
    final friends = forceEmpty ? const <FriendProfile>[] : state.friends;
    final incoming = forceEmpty ? const <FriendProfile>[] : state.incoming;

    if (state.isRefreshing &&
        friends.isEmpty &&
        incoming.isEmpty &&
        state.friendsFailure == null &&
        state.incomingFailure == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadOverview(refreshing: true),
      child: ListView(
        key: const ValueKey('friends-mvp-list'),
        padding: const EdgeInsets.only(bottom: MameroomSpacing.lg),
        children: [
          if (state.incomingFailure != null)
            _SectionFailure(
              key: const ValueKey('incoming-section-error'),
              title: '받은 요청을 불러오지 못했어요',
              onRetry: () => controller.loadOverview(refreshing: true),
            )
          else if (incoming.isNotEmpty) ...[
            _SectionHeader(title: '받은 친구 요청', count: incoming.length),
            const SizedBox(height: MameroomSpacing.xs),
            for (final request in incoming) ...[
              _IncomingRequestCard(
                profile: request,
                onAccept: () =>
                    _runAction(context, () => controller.act(request)),
                onReject: () =>
                    _runAction(context, () => controller.reject(request)),
              ),
              const SizedBox(height: MameroomSpacing.xs),
            ],
            const SizedBox(height: MameroomSpacing.sm),
          ],
          const _SectionHeader(title: '내 친구'),
          const SizedBox(height: MameroomSpacing.xs),
          if (state.friendsFailure != null)
            _SectionFailure(
              key: const ValueKey('friends-section-error'),
              title: '친구 목록을 불러오지 못했어요',
              onRetry: () => controller.loadOverview(refreshing: true),
            )
          else if (friends.isEmpty)
            _FriendsEmptyState(
              onFind: () => context.push(FriendSearchPage.routePath),
            )
          else
            for (final friend in friends) ...[
              _FriendCard(
                friend: friend,
                onVisit: () => context.push(
                  '${FriendRoomPage.routePath.replaceFirst(':friendId', Uri.encodeComponent(friend.id))}?nickname=${Uri.encodeQueryComponent(friend.nickname)}',
                ),
                onDelete: () => _confirmDelete(context, controller, friend),
              ),
              const SizedBox(height: MameroomSpacing.xs),
            ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FriendsController controller,
    FriendProfile friend,
  ) async {
    if (friend.isProcessing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('친구를 삭제할까요?'),
        content: const Text('삭제하면 서로의 방을 방문할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('친구 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _runAction(context, () => controller.deleteFriend(friend.id));
  }

  Future<void> _runAction(
    BuildContext context,
    Future<String?> Function() action,
  ) async {
    final message = await action();
    if (context.mounted && message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(MameroomToast(message: message));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (count != null)
          Badge(
            label: Text(count.toString()),
            backgroundColor: context.mameroom.primary,
          ),
      ],
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.profile,
    required this.onAccept,
    required this.onReject,
  });

  final FriendProfile profile;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return MameroomCard(
      child: Row(
        children: [
          _FriendAvatar(profile: profile),
          const SizedBox(width: MameroomSpacing.sm),
          Expanded(child: _FriendIdentity(profile: profile)),
          const SizedBox(width: MameroomSpacing.xs),
          TextButton(
            onPressed: profile.isProcessing ? null : onReject,
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: const Text('거절'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: profile.isProcessing ? null : onAccept,
            style: FilledButton.styleFrom(
              minimumSize: const Size(52, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: profile.isProcessing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('수락'),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.onVisit,
    required this.onDelete,
  });

  final FriendProfile friend;
  final VoidCallback onVisit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${friend.nickname}님의 방 방문',
      child: MameroomInteractiveCard(
        onTap: friend.isProcessing || !friend.canVisitRoom ? null : onVisit,
        disabled: friend.isProcessing,
        child: Row(
          children: [
            _FriendAvatar(profile: friend),
            const SizedBox(width: MameroomSpacing.sm),
            Expanded(child: _FriendIdentity(profile: friend)),
            const SizedBox(width: MameroomSpacing.xs),
            FilledButton(
              onPressed: friend.isProcessing || !friend.canVisitRoom
                  ? null
                  : onVisit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text('방문하기'),
            ),
            PopupMenuButton<String>(
              tooltip: '친구 관리',
              enabled: !friend.isProcessing,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onSelected: (_) => onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('친구 삭제')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.profile});

  final FriendProfile profile;

  @override
  Widget build(BuildContext context) {
    final initial = profile.nickname.trim().isEmpty
        ? '?'
        : profile.nickname.characters.first;
    return CircleAvatar(
      backgroundColor: context.mameroom.primarySoft,
      child: Text(initial),
    );
  }
}

class _FriendIdentity extends StatelessWidget {
  const _FriendIdentity({required this.profile});

  final FriendProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          'Lv.${profile.level}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.mameroom.muted),
        ),
      ],
    );
  }
}

class _FriendsEmptyState extends StatelessWidget {
  const _FriendsEmptyState({required this.onFind});

  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    return MameroomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MameroomSpacing.md),
        child: Column(
          children: [
            Icon(
              Icons.group_outlined,
              size: 48,
              color: context.mameroom.primary,
            ),
            const SizedBox(height: MameroomSpacing.sm),
            Text(
              '아직 추가한 친구가 없어요',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MameroomSpacing.xs),
            const Text(
              '함께 공부할 친구를 찾아 서로의 방을 구경해 보세요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MameroomSpacing.sm),
            FilledButton(
              onPressed: onFind,
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              child: const Text('친구 찾기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionFailure extends StatelessWidget {
  const _SectionFailure({
    super.key,
    required this.title,
    required this.onRetry,
  });

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MameroomCard(
      child: Column(
        children: [
          Icon(Icons.refresh_rounded, color: context.mameroom.primary),
          const SizedBox(height: MameroomSpacing.xs),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text('잠시 후 다시 시도해 주세요.', textAlign: TextAlign.center),
          const SizedBox(height: MameroomSpacing.xs),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(minimumSize: const Size(100, 44)),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
