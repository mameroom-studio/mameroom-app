import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../friends/presentation/controllers/friends_controller.dart';
import '../../../friends/presentation/pages/friend_search_page.dart';
import '../../../friends/presentation/widgets/friends_list_panel.dart';

class RankPage extends ConsumerWidget {
  const RankPage({super.key, this.showEmptyFriends = false});

  final bool showEmptyFriends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingCount = ref.watch(
      friendsControllerProvider.select((state) => state.incoming.length),
    );
    return MameroomShell(
      showSparkles: false,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FriendsHeader(incomingCount: showEmptyFriends ? 0 : incomingCount),
          const SizedBox(height: MameroomSpacing.sm),
          Expanded(child: FriendsListPanel(forceEmpty: showEmptyFriends)),
        ],
      ),
    );
  }
}

class _FriendsHeader extends StatelessWidget {
  const _FriendsHeader({this.incomingCount});

  final int? incomingCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Expanded(
          child: Text(
            '친구',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Badge(
          isLabelVisible: (incomingCount ?? 0) > 0,
          label: Text('${incomingCount ?? 0}'),
          child: _HeaderAction(
            icon: Icons.person_add_alt_1_rounded,
            tooltip: '친구 추가',
            onPressed: () => context.push(FriendSearchPage.routePath),
          ),
        ),
        const SizedBox(width: MameroomSpacing.xs),
        _HeaderAction(
          icon: Icons.search_rounded,
          tooltip: '사용자 검색',
          onPressed: () => context.push(FriendSearchPage.routePath),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(icon, color: colors.ink),
      style: IconButton.styleFrom(
        backgroundColor: colors.paper,
        side: BorderSide(color: colors.line),
      ),
    );
  }
}
