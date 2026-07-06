import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../../shared/widgets/reward_feedback_overlay.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../memory_seed/domain/entities/memory_seed.dart';
import '../../../memory_seed/presentation/pages/arboretum_page.dart';
import '../../../memory_seed/presentation/providers/memory_seed_providers.dart';
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
    final seedState = ref.watch(memorySeedControllerProvider);

    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(myRoomControllerProvider.notifier).load(),
        ),
        data: (room) => _RoomContent(
          room: room,
          currentStreak: streak?.currentStreak ?? 0,
          seedState: seedState,
        ),
      ),
    );
  }
}

class _RoomContent extends StatelessWidget {
  const _RoomContent({required this.room, required this.currentStreak, required this.seedState});

  final MyRoomState room;
  final int currentStreak;
  final AsyncValue<MemorySeed?> seedState;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '라이브러리',
                onPressed: () => context.go(LibraryPage.routePath),
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primary),
              ),
              Expanded(
                child: Text(
                  'My Memory Room',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: '상점',
                onPressed: () => context.push(ShopPage.routePath),
                icon: Icon(Icons.storefront_outlined, color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: Icons.monetization_on,
                  label: 'M-Coin',
                  value: '${room.walletBalance}',
                  color: colors.sun,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoPill(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Streak',
                  value: '$currentStreak일',
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RoomPreview(room: room, currentStreak: currentStreak, seed: seedState.asData?.value),
          const SizedBox(height: 16),
          _InventorySection(room: room),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(ArboretumPage.routePath),
                  icon: const Icon(Icons.park_outlined),
                  label: const Text('씨앗 정원'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push(ShopPage.routePath),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('상점 가기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
          RewardAnimatedValue(value: value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _RoomPreview extends StatelessWidget {
  const _RoomPreview({required this.room, required this.currentStreak, required this.seed});

  final MyRoomState room;
  final int currentStreak;
  final MemorySeed? seed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 10))],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _BasicRoomPainter(colors))),
                Positioned(
                  left: constraints.maxWidth * 0.08,
                  top: constraints.maxHeight * 0.13,
                  child: Text('흰 벽', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.muted)),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.08,
                  bottom: constraints.maxHeight * 0.12,
                  child: Text('기본 바닥', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.muted)),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.42,
                  top: constraints.maxHeight * 0.38,
                  child: const PixelCharacter(size: 82),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.06,
                  top: constraints.maxHeight * 0.34,
                  child: _MemorySeedInRoom(seed: seed),
                ),
                for (final layout in room.layouts)
                  Positioned(
                    left: constraints.maxWidth * layout.positionX - 24,
                    top: constraints.maxHeight * layout.positionY - 24,
                    child: _RoomItemSprite(item: layout.item),
                  ),
                if (currentStreak > 0)
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Chip(label: Text('$currentStreak일 연속')),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InventorySection extends StatelessWidget {
  const _InventorySection({required this.room});

  final MyRoomState room;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('보유 아이템', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (room.ownedItems.isEmpty)
            Text('아직 보유한 아이템이 없어요.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in room.ownedItems)
                  Chip(
                    avatar: Icon(_iconFor(item.itemType), size: 18),
                    label: Text(item.name),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MemorySeedInRoom extends StatelessWidget {
  const _MemorySeedInRoom({required this.seed});

  final MemorySeed? seed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final current = seed;
    final label = current == null ? '기억씨앗 준비 중' : current.stageLabel;
    final progress = current?.progress ?? 0.0;
    return Container(
      width: 106,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.paper.withValues(alpha: 0.92),
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PixelSeed(size: 42),
          const SizedBox(height: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: progress, minHeight: 6),
          const SizedBox(height: 4),
          Text(
            current == null ? '0/100' : '${current.growthValue}/${current.maxGrowthValue}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _RoomItemSprite extends StatelessWidget {
  const _RoomItemSprite({required this.item});

  final RoomItem item;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(item.itemType);
    return Tooltip(
      message: item.name,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_iconFor(item.itemType), color: color, size: 28),
      ),
    );
  }
}

class _BasicRoomPainter extends CustomPainter {
  const _BasicRoomPainter(this.colors);

  final MameroomTheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()..color = Colors.white;
    final floor = Paint()..color = colors.primaryMist.withValues(alpha: 0.28);
    final line = Paint()
      ..color = colors.line
      ..strokeWidth = 2;
    canvas.drawRect(Offset.zero & size, wall);
    final floorTop = size.height * 0.68;
    canvas.drawRect(Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop), floor);
    canvas.drawLine(Offset(0, floorTop), Offset(size.width, floorTop), line);
  }

  @override
  bool shouldRepaint(covariant _BasicRoomPainter oldDelegate) => oldDelegate.colors != colors;
}

IconData _iconFor(String type) {
  return switch (type) {
    'desk' => Icons.table_bar_outlined,
    'chair' => Icons.chair_outlined,
    'plant' => Icons.local_florist_outlined,
    'lamp' => Icons.light_outlined,
    'rug' => Icons.crop_landscape_outlined,
    'clock' => Icons.schedule_outlined,
    _ => Icons.widgets_outlined,
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
