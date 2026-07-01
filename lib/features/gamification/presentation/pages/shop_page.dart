import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../shared/widgets/reward_feedback_overlay.dart';
import '../../domain/entities/room_item.dart';
import '../providers/gamification_providers.dart';

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  static const routePath = '/room/shop';

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  List<String> _rewardMessages = const [];
  int _rewardTrigger = 0;
  String? _highlightedItemId;

  @override
  Widget build(BuildContext context) {
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
          data: (room) => RewardFeedbackOverlay(
            messages: _rewardMessages,
            trigger: _rewardTrigger,
            child: ListView(
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
                const SizedBox(height: AppSpacing.lg),
                ...room.shopItems.map(
                  (item) => _ShopItemTile(
                    item: item,
                    owned: room.owns(item.id),
                    canAfford: room.walletBalance >= item.price,
                    highlighted: _highlightedItemId == item.id,
                    onBuy: () async {
                      try {
                        await ref.read(myRoomControllerProvider.notifier).purchase(item);
                        if (context.mounted) {
                          setState(() {
                            _highlightedItemId = item.id;
                            _rewardMessages = ['구매 완료', item.name];
                            _rewardTrigger += 1;
                          });
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
      ),
    );
  }
}

class _ShopItemTile extends StatelessWidget {
  const _ShopItemTile({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.highlighted,
    required this.onBuy,
  });

  final RoomItem item;
  final bool owned;
  final bool canAfford;
  final bool highlighted;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${item.id}-$highlighted'),
      tween: Tween<double>(begin: highlighted ? 0.94 : 1, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedOpacity(
        opacity: highlighted ? 0.92 : 1,
        duration: const Duration(milliseconds: 180),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: highlighted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black12,
                width: highlighted ? 2 : 1,
              ),
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
