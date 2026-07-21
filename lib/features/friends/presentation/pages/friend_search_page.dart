import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/states/mameroom_states.dart';
import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../domain/entities/friend_profile.dart';
import '../../domain/policies/friend_relationship_policy.dart';
import '../controllers/friends_controller.dart';
import 'friend_room_page.dart';

class FriendSearchPage extends ConsumerStatefulWidget {
  const FriendSearchPage({super.key});
  static const routePath = '/friends/search';
  @override
  ConsumerState<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends ConsumerState<FriendSearchPage> {
  final _search = TextEditingController();
  bool _showRequests = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsControllerProvider);
    final controller = ref.read(friendsControllerProvider.notifier);
    return Scaffold(
      body: MameroomShell(
        showSparkles: false,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inset = constraints.maxWidth >= 720
                  ? MameroomSpacing.xl
                  : MameroomSpacing.md;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          inset,
                          MameroomSpacing.sm,
                          inset,
                          MameroomSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: context.pop,
                              tooltip: '\uB4A4\uB85C',
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            Expanded(
                              child: Text(
                                '\uCE5C\uAD6C \uCC3E\uAE30',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            Badge(
                              isLabelVisible: state.incoming.isNotEmpty,
                              label: Text('${state.incoming.length}'),
                              child: IconButton(
                                onPressed: () => setState(
                                  () => _showRequests = !_showRequests,
                                ),
                                tooltip: '\uBC1B\uC740 \uC694\uCCAD',
                                icon: const Icon(Icons.mail_outline_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: inset),
                        child: TextField(
                          key: const Key('friend-search-field'),
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) {
                            controller.queryChanged(value);
                            setState(() {});
                          },
                          onSubmitted: (_) => controller.search(),
                          decoration: InputDecoration(
                            hintText:
                                '\uB2C9\uB124\uC784 \uB610\uB294 \uCE5C\uAD6C \uCF54\uB4DC\uB97C \uC785\uB825\uD558\uC138\uC694.',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip:
                                        '\uAC80\uC0C9\uC5B4 \uC9C0\uC6B0\uAE30',
                                    onPressed: () {
                                      _search.clear();
                                      controller.queryChanged('');
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: inset,
                          vertical: MameroomSpacing.xs,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: const [
                              FilterChip(
                                label: Text('\uC804\uCCB4'),
                                selected: true,
                                onSelected: null,
                              ),
                              SizedBox(width: MameroomSpacing.xs),
                              Chip(label: Text('\uB2C9\uB124\uC784')),
                              SizedBox(width: MameroomSpacing.xs),
                              Chip(label: Text('\uCE5C\uAD6C\uCF54\uB4DC')),
                              SizedBox(width: MameroomSpacing.xs),
                              Chip(
                                label: Text('\uD559\uAD50 \u00B7 COMING SOON'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () =>
                              controller.loadOverview(refreshing: true),
                          child: AnimatedSwitcher(
                            duration: const Duration(
                              milliseconds: MameroomDurations.normalMs,
                            ),
                            child: _content(state, controller, inset),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(
    FriendsState state,
    FriendsController controller,
    double inset,
  ) {
    if (_showRequests) {
      return _profiles(
        key: const ValueKey('requests'),
        title: '\uBC1B\uC740 \uC694\uCCAD',
        items: state.incoming,
        inset: inset,
        empty: const MameroomEmptyState(
          title:
              '\uBC1B\uC740 \uCE5C\uAD6C \uC694\uCCAD\uC774 \uC5C6\uC5B4\uC694.',
          description:
              '\uC0C8 \uC694\uCCAD\uC774 \uC624\uBA74 \uC5EC\uAE30\uC5D0 \uC54C\uB824\uB4DC\uB9B4\uAC8C\uC694.',
          icon: MameroomStatePixelIcon.friends,
        ),
        controller: controller,
      );
    }
    if (state.isLoading && state.results.isEmpty) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (state.errorMessage != null) {
      return ListView(
        key: const ValueKey('error'),
        padding: EdgeInsets.all(inset),
        children: [MameroomErrorState.network(onRetry: controller.search)],
      );
    }
    if (state.validationMessage != null) {
      return ListView(
        key: const ValueKey('validation'),
        padding: EdgeInsets.all(inset),
        children: [
          MameroomEmptyState(
            title:
                '\uAC80\uC0C9 \uC870\uAC74\uC744 \uD655\uC778\uD574 \uC8FC\uC138\uC694.',
            description: state.validationMessage!,
            icon: MameroomStatePixelIcon.search,
          ),
        ],
      );
    }
    final searching = state.query.trim().isNotEmpty;
    final items = searching ? state.results : state.recommended;
    return _profiles(
      key: ValueKey(searching ? 'results' : 'initial'),
      title: searching
          ? '\uAC80\uC0C9 \uACB0\uACFC'
          : '\uCD94\uCC9C \uCE5C\uAD6C',
      items: items,
      inset: inset,
      empty: MameroomEmptyState(
        title: '\uAC80\uC0C9 \uACB0\uACFC\uAC00 \uC5C6\uC5B4\uC694.',
        description:
            '\uB2C9\uB124\uC784\uC774\uB098 \uCE5C\uAD6C \uCF54\uB4DC\uB97C \uB2E4\uC2DC \uD655\uC778\uD574 \uC8FC\uC138\uC694.',
        icon: MameroomStatePixelIcon.search,
      ),
      controller: controller,
    );
  }

  Widget _profiles({
    required Key key,
    required String title,
    required List<FriendProfile> items,
    required double inset,
    required Widget empty,
    required FriendsController controller,
  }) {
    return ListView(
      key: key,
      padding: EdgeInsets.fromLTRB(inset, 0, inset, MameroomSpacing.xl),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: context.mameroom.ink,
          ),
        ),
        const SizedBox(height: MameroomSpacing.xs),
        if (items.isEmpty) empty,
        for (final profile in items) ...[
          _FriendCard(
            profile: profile,
            onAction: () async => _toast(await controller.act(profile)),
            onVisit: profile.canVisitRoom
                ? () => context.push(
                    '${FriendRoomPage.routePath.replaceFirst(':friendId', profile.id)}?nickname=${Uri.encodeQueryComponent(profile.nickname)}',
                  )
                : null,
          ),
          const SizedBox(height: MameroomSpacing.xs),
        ],
      ],
    );
  }

  void _toast(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(MameroomToast(message: message));
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.profile,
    required this.onAction,
    this.onVisit,
  });
  final FriendProfile profile;
  final VoidCallback onAction;
  final VoidCallback? onVisit;

  @override
  Widget build(BuildContext context) {
    final presentation = FriendRelationshipPolicy.presentation(
      profile.relationship,
    );
    return MameroomCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.mameroom.primarySoft,
              borderRadius: MameroomRadius.mediumRadius,
            ),
            child: Text(
              profile.nickname.isEmpty
                  ? '?'
                  : profile.nickname.characters.first,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: MameroomSpacing.sm),
          Expanded(
            child: Column(
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
                  'Lv.${profile.level} \u00B7 ${profile.statusMessage}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  presentation.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.mameroom.muted,
                  ),
                ),
              ],
            ),
          ),
          if (onVisit != null)
            IconButton(
              onPressed: onVisit,
              tooltip: 'Room \uBC29\uBB38',
              icon: const Icon(Icons.meeting_room_outlined),
            ),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: presentation.enabled && !profile.isProcessing
                  ? onAction
                  : null,
              child: profile.isProcessing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(presentation.label),
            ),
          ),
        ],
      ),
    );
  }
}
