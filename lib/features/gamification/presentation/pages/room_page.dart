import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../shared/widgets/reward_feedback_overlay.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Room'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(ShopPage.routePath),
            icon: const Icon(Icons.storefront),
            label: const Text('Shop'),
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            message: error.toString(),
            onRetry: () => ref.read(myRoomControllerProvider.notifier).load(),
          ),
          data: (room) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('M-Coin', style: Theme.of(context).textTheme.titleMedium),
                  Chip(
                    avatar: const Icon(Icons.toll, size: 18),
                    label: RewardAnimatedValue(value: '${room.walletBalance}'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _RoomCanvas(
                room: room,
                currentStreak: streak?.currentStreak ?? 0,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Owned items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (room.ownedItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('No items yet.'),
                )
              else
                ...room.ownedItems.map(
                  (item) => _OwnedItemTile(
                    item: item,
                    isPlaced: room.layouts.any((layout) => layout.item.id == item.id),
                    onPlace: () async {
                      try {
                        await ref.read(myRoomControllerProvider.notifier).place(item);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Item placed.')),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCanvas extends StatelessWidget {
  const _RoomCanvas({required this.room, required this.currentStreak});

  final MyRoomState room;
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: constraints.maxHeight * 0.36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9DCC8),
                      border: Border(top: BorderSide(color: Colors.black12)),
                    ),
                  ),
                ),
                const Positioned(left: 26, top: 22, child: _Window()),
                ...room.layouts.map((layout) {
                  return Positioned(
                    left: constraints.maxWidth * layout.positionX - 34,
                    top: constraints.maxHeight * layout.positionY - 34,
                    child: _PixelItem(item: layout.item),
                  );
                }),
                Positioned(
                  left: constraints.maxWidth * 0.46,
                  top: constraints.maxHeight * 0.40,
                  child: _PixelCharacter(currentStreak: currentStreak),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PixelCharacter extends StatelessWidget {
  const _PixelCharacter({required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 116,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3BF),
              border: Border.all(color: const Color(0xFFFF922B), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, size: 14, color: Color(0xFFE8590C)),
                const SizedBox(width: 2),
                Text('$currentStreak', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 28, height: 28, color: const Color(0xFFFFD8B8)),
          Container(width: 38, height: 28, color: Colors.white),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 16, height: 26, color: Colors.white),
              const SizedBox(width: 4),
              Container(width: 16, height: 26, color: Colors.white),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 6, color: Colors.black87),
              const SizedBox(width: 10),
              Container(width: 12, height: 6, color: Colors.black87),
            ],
          ),
        ],
      ),
    );
  }
}

class _PixelItem extends StatelessWidget {
  const _PixelItem({required this.item});

  final RoomItem item;

  @override
  Widget build(BuildContext context) {
    return switch (item.itemType) {
      'desk' => _BlockIcon(color: const Color(0xFF8B5E3C), label: 'Desk'),
      'chair' => _BlockIcon(color: const Color(0xFF5C7CFA), label: 'Chair'),
      'plant' => _BlockIcon(color: const Color(0xFF2F9E44), label: 'Plant'),
      'lamp' => _BlockIcon(color: const Color(0xFFFFC857), label: 'Lamp'),
      _ => _BlockIcon(color: Colors.grey, label: item.name),
    };
  }
}

class _BlockIcon extends StatelessWidget {
  const _BlockIcon({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black87, width: 2),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Window extends StatelessWidget {
  const _Window();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFD7F2FF),
        border: Border.all(color: Colors.black26, width: 2),
      ),
      child: const Column(
        children: [
          Expanded(child: SizedBox()),
          Divider(height: 1, color: Colors.black26),
          Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _OwnedItemTile extends StatelessWidget {
  const _OwnedItemTile({
    required this.item,
    required this.isPlaced,
    required this.onPlace,
  });

  final RoomItem item;
  final bool isPlaced;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _PixelItem(item: item),
      title: Text(item.name),
      subtitle: Text(isPlaced ? 'Placed' : 'Not placed'),
      trailing: FilledButton(
        onPressed: onPlace,
        child: Text(isPlaced ? 'Move' : 'Place'),
      ),
    );
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
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}