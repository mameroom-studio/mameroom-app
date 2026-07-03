import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../../shared/widgets/reward_feedback_overlay.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../streak/presentation/providers/streak_providers.dart';
import '../../domain/entities/room_item.dart';
import '../providers/gamification_providers.dart';
import 'shop_page.dart';

class RoomPage extends ConsumerWidget {
  const RoomPage({super.key});

  static const routePath = '/room';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRoomControllerProvider);
    final streak = ref.watch(streakProvider).asData?.value;

    return MameroomShell(
      showSparkles: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(myRoomControllerProvider.notifier).load(),
        ),
        data: (room) => _RoomContent(
          room: room,
          currentStreak: streak?.currentStreak ?? 0,
          onPlace: (item) async {
            try {
              await ref.read(myRoomControllerProvider.notifier).place(item);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('아이템을 방에 배치했어요.')),
                );
              }
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class _RoomContent extends StatelessWidget {
  const _RoomContent({
    required this.room,
    required this.currentStreak,
    required this.onPlace,
  });

  final MyRoomState room;
  final int currentStreak;
  final ValueChanged<RoomItem> onPlace;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.paper,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, color: colors.sun, size: 20),
                  const SizedBox(width: 6),
                  RewardAnimatedValue(value: '${room.walletBalance}'),
                ],
              ),
            ),
            const Spacer(),
            if (currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.sun.withValues(alpha: 0.22),
                  border: Border.all(color: colors.sun),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('🔥 $currentStreak일', style: Theme.of(context).textTheme.labelLarge),
              ),
            IconButton(
              tooltip: '상점',
              onPressed: () => context.push(ShopPage.routePath),
              icon: const Icon(Icons.storefront_outlined),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelRoomScene(streak: currentStreak > 0 ? currentStreak : null),
                  const SizedBox(height: 18),
                  Text(
                    '환영해요! 🎉\n나만의 방이 완성되었어요!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이제 공부하고 기억씨앗을 성장시켜봐요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (room.ownedItems.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _OwnedItemsStrip(room: room, onPlace: onPlace),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        MameroomPrimaryButton(
          label: '마메룸 시작하기',
          onPressed: () => context.go(LibraryPage.routePath),
        ),
      ],
    );
  }
}

class _OwnedItemsStrip extends StatelessWidget {
  const _OwnedItemsStrip({required this.room, required this.onPlace});

  final MyRoomState room;
  final ValueChanged<RoomItem> onPlace;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: room.ownedItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = room.ownedItems[index];
          final isPlaced = room.layouts.any((layout) => layout.item.id == item.id);
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onPlace(item),
            child: Container(
              width: 88,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPlaced ? colors.primaryMist.withValues(alpha: 0.28) : colors.paper,
                border: Border.all(color: isPlaced ? colors.primary : colors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconFor(item.itemType), color: colors.primary, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    isPlaced ? '배치됨' : '배치',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'desk' => Icons.table_bar_outlined,
      'chair' => Icons.chair_outlined,
      'plant' => Icons.local_florist_outlined,
      'lamp' => Icons.light_outlined,
      _ => Icons.widgets_outlined,
    };
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PixelSeed(size: 58),
          const SizedBox(height: 18),
          Text('방 정보를 불러오지 못했어요', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          MameroomPrimaryButton(label: '다시 시도', onPressed: onRetry),
        ],
      ),
    );
  }
}
