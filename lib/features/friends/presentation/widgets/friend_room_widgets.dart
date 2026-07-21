// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';

import '../../../../core/presentation/states/mameroom_states.dart';
import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../gamification/domain/entities/room_item.dart';
import '../../domain/entities/friend_room.dart';

class FriendRoomHeader extends StatelessWidget {
  const FriendRoomHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onProfile,
  });
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Row(
      children: [
        MameroomIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          tooltip: '친구 목록으로 돌아가기',
          onPressed: onBack,
        ),
        const SizedBox(width: MameroomSpacing.xs),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.mameroom.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        MameroomIconButton(
          icon: Icons.person_outline_rounded,
          tooltip: '친구 프로필 보기',
          onPressed: onProfile,
        ),
      ],
    ),
  );
}

class FriendStatusBubble extends StatelessWidget {
  const FriendStatusBubble({super.key, required this.message, this.onClose});
  final String message;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: '친구 상태: $message',
    child: Material(
      color: MameroomColors.white,
      elevation: 3,
      borderRadius: MameroomRadius.mediumRadius,
      child: InkWell(
        onTap: onClose,
        borderRadius: MameroomRadius.mediumRadius,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 190),
          padding: const EdgeInsets.symmetric(
            horizontal: MameroomSpacing.sm,
            vertical: MameroomSpacing.xs,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: MameroomColors.primaryMist),
            borderRadius: MameroomRadius.mediumRadius,
          ),
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: MameroomColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  );
}

class FriendRoomCanvas extends StatelessWidget {
  const FriendRoomCanvas({
    super.key,
    required this.room,
    required this.capabilities,
    required this.onCharacterTap,
    required this.onFurnitureTap,
    this.characterMessage,
    this.reducedMotion = false,
  });
  final FriendRoom room;
  final RoomCapabilities capabilities;
  final VoidCallback onCharacterTap;
  final ValueChanged<UserRoomLayout> onFurnitureTap;
  final String? characterMessage;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    if (!room.isDecorated) {
      return const MameroomStateView(
        variant: MameroomStateVariant.empty,
        title: '아직 방을 꾸미는 중이에요.',
        description: '친구가 공부하며 조금씩 방을 꾸미고 있어요.',
        pixelIcon: MameroomStatePixelIcon.room,
        size: MameroomStateSize.compact,
      );
    }
    return Semantics(
      container: true,
      label: room.accessibilityLabel ?? room.roomTitle,
      child: ClipRRect(
        borderRadius: MameroomRadius.cardRadius,
        child: AspectRatio(
          aspectRatio: 325 / 306,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/pixel/friend_room_cozy.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.none,
                    semanticLabel: room.nickname + '님의 따뜻한 픽셀 공부방',
                  ),
                  Positioned(
                    left: constraints.maxWidth * .38,
                    top: constraints.maxHeight * .47,
                    width: constraints.maxWidth * .28,
                    height: constraints.maxHeight * .42,
                    child: Semantics(
                      button: true,
                      label: '친구 캐릭터. 인사하려면 두 번 탭하세요.',
                      child: InkWell(
                        key: const ValueKey('friend-room-character'),
                        onTap: capabilities.canInteractWithCharacter
                            ? onCharacterTap
                            : null,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                    ),
                  ),
                  for (final layout in room.furnitureItems)
                    Positioned(
                      left: constraints.maxWidth * layout.positionX - 34,
                      top: constraints.maxHeight * layout.positionY - 30,
                      width: 68,
                      height: 60,
                      child: Semantics(
                        button: true,
                        label:
                            layout.item.name +
                            ', ' +
                            layout.item.rarity +
                            ' 등급. 정보를 보려면 두 번 탭하세요.',
                        child: InkWell(
                          key: ValueKey('friend-furniture-' + layout.item.id),
                          onTap: capabilities.canInspectFurniture
                              ? () => onFurnitureTap(layout)
                              : null,
                          splashColor: MameroomColors.primaryMist,
                        ),
                      ),
                    ),
                  Positioned(
                    top: constraints.maxHeight * .35,
                    left: constraints.maxWidth * .31,
                    child: AnimatedSwitcher(
                      duration: reducedMotion
                          ? Duration.zero
                          : const Duration(
                              milliseconds: MameroomDurations.normalMs,
                            ),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: characterMessage == null
                          ? FriendStatusBubble(
                              key: const ValueKey('friend-status'),
                              message: room.studyStatus,
                            )
                          : FriendStatusBubble(
                              key: ValueKey(characterMessage),
                              message: characterMessage!,
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class FriendRoomVisitBadge extends StatelessWidget {
  const FriendRoomVisitBadge({super.key, required this.state});
  final FriendRoomVisitState state;
  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (state) {
      FriendRoomVisitState.visitable ||
      FriendRoomVisitState.loaded => ('방문 가능', MameroomBadgeVariant.success),
      FriendRoomVisitState.private => ('비공개', MameroomBadgeVariant.warning),
      _ => ('현재 이용 불가', MameroomBadgeVariant.disabled),
    };
    return MameroomStatusBadge(label: label, variant: variant);
  }
}

class FriendRoomVisitLoader extends StatelessWidget {
  const FriendRoomVisitLoader({super.key, required this.nickname});
  final String nickname;
  @override
  Widget build(BuildContext context) => MameroomStateView(
    key: const ValueKey('friend-room-loading'),
    variant: MameroomStateVariant.loading,
    title: nickname.isEmpty
        ? '친구의 방으로 방문 중이에요...'
        : '$nickname의 방으로 방문 중이에요...',
    description: '따뜻한 인사와 함께 잠시만 기다려주세요.',
    pixelIcon: MameroomStatePixelIcon.room,
    showProgress: true,
    progress: null,
  );
}

class FriendRoomAccessState extends StatelessWidget {
  const FriendRoomAccessState({
    super.key,
    required this.visitState,
    required this.onBack,
    this.onRetry,
  });
  final FriendRoomVisitState visitState;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final spec = switch (visitState) {
      FriendRoomVisitState.private => (
        '비공개 방이에요.',
        '현재 이 방은 방문할 수 없어요.',
        MameroomStateVariant.permission,
      ),
      FriendRoomVisitState.failed => (
        '친구의 방을 불러오지 못했어요.',
        '잠시 후 다시 시도해주세요.',
        MameroomStateVariant.error,
      ),
      _ => (
        '현재 방문할 수 없는 방이에요.',
        '친구 관계나 방 공개 상태를 확인할 수 없어요.',
        MameroomStateVariant.warning,
      ),
    };
    return MameroomStateView(
      key: ValueKey('friend-room-' + visitState.name),
      variant: spec.$3,
      title: spec.$1,
      description: spec.$2,
      pixelIcon: visitState == FriendRoomVisitState.private
          ? MameroomStatePixelIcon.folder
          : MameroomStatePixelIcon.room,
      primaryButtonText: onRetry == null ? '돌아가기' : '다시 시도',
      secondaryButtonText: onRetry == null ? null : '돌아가기',
      onPrimaryPressed: onRetry ?? onBack,
      onSecondaryPressed: onBack,
    );
  }
}

class FriendCheerButton extends StatelessWidget {
  const FriendCheerButton({
    super.key,
    required this.status,
    required this.onPressed,
  });
  final FriendCheerStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sending = status == FriendCheerStatus.sending;
    final completed =
        status == FriendCheerStatus.sentRewardGranted ||
        status == FriendCheerStatus.sentNoReward;
    return Semantics(
      button: true,
      label: sending
          ? '응원 보내는 중'
          : completed
          ? '오늘 응원 완료'
          : '응원하기',
      child: MameroomPrimaryButton(
        key: const ValueKey('friend-cheer-button'),
        label: sending
            ? '응원 보내는 중'
            : completed
            ? '오늘 응원 완료'
            : status == FriendCheerStatus.failed
            ? '다시 응원하기'
            : '응원하기',
        leadingIcon: completed ? Icons.check_rounded : Icons.favorite_rounded,
        isLoading: sending,
        onPressed: sending ? null : onPressed,
      ),
    );
  }
}

Future<void> showFriendProfileOverlay(BuildContext context, FriendRoom room) =>
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(MameroomSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: MameroomRadius.cardRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MameroomSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Semantics(
                      label: room.nickname + '님의 프로필 이미지',
                      child: const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.face_rounded),
                      ),
                    ),
                    const SizedBox(width: MameroomSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.nickname,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          MameroomLevelBadge(level: room.level),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: MameroomSpacing.md),
                _ProfileLine(
                  icon: Icons.local_fire_department_rounded,
                  label: '연속 학습',
                  value: room.streakDays.toString() + '일',
                ),
                _ProfileLine(
                  icon: Icons.psychology_alt_rounded,
                  label: '기억률',
                  value: (room.memoryRate * 100).round().toString() + '%',
                ),
                _ProfileLine(
                  icon: Icons.school_outlined,
                  label: '학교',
                  value: room.schoolName,
                ),
                _ProfileLine(
                  icon: Icons.menu_book_rounded,
                  label: '상태',
                  value: room.studyStatus,
                ),
                const Divider(height: MameroomSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '최근 성장',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: MameroomSpacing.xs),
                for (final growth in room.recentGrowthItems.take(2))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      growth.iconKey == 'seed'
                          ? Icons.eco_rounded
                          : Icons.light_outlined,
                      color: MameroomColors.primary,
                    ),
                    title: Text(growth.label),
                  ),
                MameroomPrimaryButton(
                  label: '닫기',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MameroomSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: MameroomIconSizes.sm, color: MameroomColors.primary),
        const SizedBox(width: MameroomSpacing.xs),
        SizedBox(width: 72, child: Text(label)),
        Expanded(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}

Future<void> showFurnitureInfoBottomSheet(
  BuildContext context,
  RoomItem item,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: MameroomColors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(MameroomRadius.modal),
    ),
  ),
  builder: (context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      MameroomSpacing.lg,
      0,
      MameroomSpacing.lg,
      MameroomSpacing.lg,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: MameroomColors.primaryMist.withValues(alpha: .35),
            borderRadius: MameroomRadius.cardRadius,
          ),
          child: const Icon(
            Icons.library_books_rounded,
            size: 54,
            color: MameroomColors.primary,
          ),
        ),
        const SizedBox(height: MameroomSpacing.sm),
        Text(item.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: MameroomSpacing.xs),
        MameroomStatusBadge(label: item.rarity),
        const SizedBox(height: MameroomSpacing.md),
        Text(item.description, textAlign: TextAlign.center),
        const SizedBox(height: MameroomSpacing.lg),
        MameroomPrimaryButton(
          label: '닫기',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  ),
);
