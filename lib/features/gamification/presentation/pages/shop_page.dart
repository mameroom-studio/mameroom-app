import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/spacing/app_spacing.dart';
import '../../domain/entities/room_item.dart';
import '../providers/gamification_providers.dart';

class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  static const routePath = '/room/shop';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRoomControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Room Shop')),
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
                    label: Text('${room.walletBalance}'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...room.shopItems.map(
                (item) => _ShopItemTile(
                  item: item,
                  owned: room.owns(item.id),
                  canAfford: room.walletBalance >= item.price,
                  onBuy: () async {
                    try {
                      await ref.read(myRoomControllerProvider.notifier).purchase(item);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.name} purchased.')),
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

class _ShopItemTile extends StatelessWidget {
  const _ShopItemTile({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.onBuy,
  });

  final RoomItem item;
  final bool owned;
  final bool canAfford;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: _ShopIcon(type: item.itemType),
          title: Text(item.name),
          subtitle: Text('${item.price} M-Coin'),
          trailing: FilledButton(
            onPressed: owned || !canAfford ? null : onBuy,
            child: Text(owned ? 'Owned' : 'Buy'),
          ),
        ),
      ),
    );
  }
}

class _ShopIcon extends StatelessWidget {
  const _ShopIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'desk' => const Color(0xFF8B5E3C),
      'chair' => const Color(0xFF5C7CFA),
      'plant' => const Color(0xFF2F9E44),
      'lamp' => const Color(0xFFFFC857),
      _ => Colors.grey,
    };
    final icon = switch (type) {
      'desk' => Icons.table_bar,
      'chair' => Icons.chair,
      'plant' => Icons.local_florist,
      'lamp' => Icons.lightbulb_outline,
      _ => Icons.category,
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color),
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