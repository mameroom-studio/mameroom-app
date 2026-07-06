import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../shared/widgets/reward_feedback_overlay.dart';
import '../../domain/entities/room_item.dart';
import '../providers/gamification_providers.dart';
import 'room_page.dart';

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
      appBar: AppBar(
        title: const Text('상점'),
        actions: [
          IconButton(
            tooltip: '내 방 보기',
            onPressed: () => context.push(RoomPage.routePath),
            icon: const Icon(Icons.meeting_room_outlined),
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
          data: (room) => RewardFeedbackOverlay(
            messages: _rewardMessages,
            trigger: _rewardTrigger,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('보유 M-Coin', style: Theme.of(context).textTheme.titleMedium),
                    Chip(
                      avatar: const Icon(Icons.toll, size: 18),
                      label: RewardAnimatedValue(value: '${room.walletBalance}'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('구매한 아이템은 내 방에 자동으로 배치됩니다.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                ...room.shopItems.map(
                  (item) => _ShopItemTile(
                    item: item,
                    owned: room.owns(item.id),
                    canAfford: room.walletBalance >= item.price,
                    highlighted: _highlightedItemId == item.id,
                    onBuy: () => _purchase(item),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _purchase(RoomItem item) async {
    try {
      await ref.read(myRoomControllerProvider.notifier).purchase(item);
      if (!mounted) {
        return;
      }
      setState(() {
        _highlightedItemId = item.id;
        _rewardMessages = ['구매 완료', item.name];
        _rewardTrigger += 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 완료')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_purchaseErrorMessage(error))),
      );
    }
  }

  String _purchaseErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('Not enough M-Coin')) {
      return 'M-Coin이 부족합니다';
    }
    if (message.contains('duplicate') || message.contains('already') || message.contains('unique')) {
      return '이미 보유한 아이템입니다';
    }
    return message.replaceFirst('Exception: ', '');
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
    final color = _colorFor(item.itemType);
    return TweenAnimationBuilder<double>(
      key: ValueKey('${item.id}-$highlighted'),
      tween: Tween<double>(begin: highlighted ? 0.96 : 1, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: highlighted ? Theme.of(context).colorScheme.primary : Colors.black12,
              width: highlighted ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: _ShopIcon(type: item.itemType),
            title: Text(item.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.description.isNotEmpty) Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  children: [
                    Text('${item.price} M-Coin'),
                    Text(_rarityLabel(item.rarity), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
            trailing: FilledButton(
              onPressed: owned || !canAfford ? null : onBuy,
              child: Text(owned ? '보유중' : '구매'),
            ),
          ),
        ),
      ),
    );
  }

  String _rarityLabel(String rarity) {
    return switch (rarity) {
      'common' => 'Common',
      'uncommon' => 'Uncommon',
      'rare' => 'Rare',
      _ => rarity,
    };
  }
}

class _ShopIcon extends StatelessWidget {
  const _ShopIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(type);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_iconFor(type), color: color),
    );
  }
}

IconData _iconFor(String type) {
  return switch (type) {
    'desk' => Icons.table_bar,
    'chair' => Icons.chair,
    'plant' => Icons.local_florist,
    'lamp' => Icons.lightbulb_outline,
    'rug' => Icons.crop_landscape_outlined,
    'clock' => Icons.schedule_outlined,
    _ => Icons.category,
  };
}

Color _colorFor(String type) {
  return switch (type) {
    'desk' => const Color(0xFF8B5E3C),
    'chair' => const Color(0xFF5C7CFA),
    'plant' => const Color(0xFF2F9E44),
    'lamp' => const Color(0xFFFFC857),
    'rug' => const Color(0xFF9C6ADE),
    'clock' => const Color(0xFF495057),
    _ => Colors.grey,
  };
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
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
