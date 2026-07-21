import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/states/mameroom_states.dart';
import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../home/presentation/pages/home_shell_page.dart';
import '../../domain/entities/room_item.dart';
import '../providers/gamification_providers.dart';
import 'shop_page.dart';

class RoomPage extends ConsumerWidget {
  const RoomPage({super.key});

  static const routePath = '/room';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRoomControllerProvider);

    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: state.when(
        loading: () => Center(child: MameroomLoadingState.room()),
        error: (error, _) => MameroomErrorState.network(
          onRetry: () => ref.read(myRoomControllerProvider.notifier).load(),
        ),
        data: (room) => _RoomEditorContent(room: room),
      ),
    );
  }
}

class _RoomEditorContent extends StatefulWidget {
  const _RoomEditorContent({required this.room});

  final MyRoomState room;

  @override
  State<_RoomEditorContent> createState() => _RoomEditorContentState();
}

class _RoomEditorContentState extends State<_RoomEditorContent> {
  bool _isEditing = false;
  String? _selectedLayoutId;

  @override
  void didUpdateWidget(covariant _RoomEditorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final layouts = _visibleLayouts;
    if (layouts.isNotEmpty &&
        !layouts.any((layout) => layout.id == _selectedLayoutId)) {
      _selectedLayoutId = layouts.first.id;
    }
  }

  List<UserRoomLayout> get _visibleLayouts {
    final realLayouts = widget.room.layouts;
    if (realLayouts.isEmpty) {
      return _defaultLayouts;
    }
    final ids = realLayouts.map((layout) => layout.item.id).toSet();
    final missingDefaults = _defaultLayouts
        .where((layout) => !ids.contains(layout.item.id))
        .toList(growable: false);
    return [...realLayouts, ...missingDefaults];
  }

  String get _selectedId {
    final layouts = _visibleLayouts;
    if (layouts.isEmpty) return '';
    return _selectedLayoutId ?? layouts.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final layouts = _visibleLayouts;
    final selectedId = _selectedId;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _RoomMetrics.from(constraints);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.sidePadding,
                  metrics.topPadding,
                  metrics.sidePadding,
                  metrics.bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RoomHeader(
                      onBack: () => context.go(HomeShellPage.homeRoutePath),
                      onShop: () => context.push(ShopPage.routePath),
                    ),
                    SizedBox(height: metrics.gap),
                    _TopStats(
                      coinBalance: room.walletBalance,
                      placedCount: layouts.length,
                    ),
                    SizedBox(height: metrics.gap),
                    SizedBox(
                      height: metrics.roomHeight,
                      child: _RoomCanvas(
                        layouts: layouts,
                        selectedLayoutId: selectedId,
                        onSelect: (layout) => setState(() {
                          _selectedLayoutId = layout.id;
                        }),
                      ),
                    ),
                    SizedBox(height: metrics.gap),
                    _PlacedFurnitureStrip(
                      layouts: layouts,
                      selectedLayoutId: selectedId,
                      onSelect: (layout) => setState(() {
                        _selectedLayoutId = layout.id;
                      }),
                    ),
                    SizedBox(height: metrics.gap),
                    if (_isEditing)
                      _EditToolbar(
                        onMove: () => _showPlaceholder(context, '이동'),
                        onRotate: () => _showPlaceholder(context, '회전'),
                        onStore: () => _showPlaceholder(context, '보관'),
                        onDelete: () => _showPlaceholder(context, '삭제'),
                        onDone: () {
                          setState(() => _isEditing = false);
                          context.go(HomeShellPage.homeRoutePath);
                        },
                      )
                    else
                      _EditModeButton(
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoomMetrics {
  const _RoomMetrics({
    required this.sidePadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.gap,
    required this.roomHeight,
  });

  final double sidePadding;
  final double topPadding;
  final double bottomPadding;
  final double gap;
  final double roomHeight;

  static _RoomMetrics from(BoxConstraints constraints) {
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 390.0;
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : 844.0;
    final dense = width < 380 || height < 820;
    final roomHeight = (height * (dense ? 0.39 : 0.41)).clamp(292.0, 368.0);
    return _RoomMetrics(
      sidePadding: width < 380 ? 14 : 18,
      topPadding: dense ? 8 : 12,
      bottomPadding: dense ? 8 : 12,
      gap: dense ? 8 : 10,
      roomHeight: roomHeight,
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.onBack, required this.onShop});

  final VoidCallback onBack;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _CircleIconButton(
            tooltip: 'Home',
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '방 꾸미기',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: FilledButton.icon(
              onPressed: onShop,
              icon: const Icon(Icons.shopping_cart_outlined, size: 17),
              label: const Text('상점'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: MameroomSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopStats extends StatelessWidget {
  const _TopStats({required this.coinBalance, required this.placedCount});

  final int coinBalance;
  final int placedCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            icon: Icons.monetization_on_rounded,
            label: 'M-Coin',
            value: _comma(coinBalance),
            helper: '현재 보유 코인',
            color: colors.sun,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.chair_rounded,
            label: '배치중',
            value: '$placedCount',
            helper: '현재 방의 가구',
            color: colors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MameroomSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(MameroomRadius.large),
        boxShadow: _softShadow(colors),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCanvas extends StatelessWidget {
  const _RoomCanvas({
    required this.layouts,
    required this.selectedLayoutId,
    required this.onSelect,
  });

  final List<UserRoomLayout> layouts;
  final String selectedLayoutId;
  final ValueChanged<UserRoomLayout> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBD4),
          border: Border.all(color: const Color(0xFFD7B083)),
          boxShadow: _softShadow(colors),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scale = (width / 390).clamp(0.72, 1.08).toDouble();

            Widget sprite(UserRoomLayout layout) {
              final selected = layout.id == selectedLayoutId;
              return Positioned(
                left: width * layout.positionX - (30 * scale),
                top: height * layout.positionY - (30 * scale),
                child: GestureDetector(
                  onTap: () => onSelect(layout),
                  child: _RoomItemSprite(
                    item: layout.item,
                    selected: selected,
                    size: _spriteSize(layout.item.itemType) * scale,
                  ),
                ),
              );
            }

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _RoomPainter(colors)),
                ),
                Positioned(
                  left: width * 0.49,
                  bottom: height * 0.13,
                  child: PixelCharacter(size: 64 * scale),
                ),
                for (final layout in layouts) sprite(layout),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlacedFurnitureStrip extends StatelessWidget {
  const _PlacedFurnitureStrip({
    required this.layouts,
    required this.selectedLayoutId,
    required this.onSelect,
  });

  final List<UserRoomLayout> layouts;
  final String selectedLayoutId;
  final ValueChanged<UserRoomLayout> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(
        MameroomSpacing.sm,
        10,
        MameroomSpacing.sm,
        10,
      ),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(MameroomRadius.large),
        boxShadow: _softShadow(colors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 배치된 가구',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MameroomSpacing.xs),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: layouts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: MameroomSpacing.xs),
              itemBuilder: (context, index) {
                final layout = layouts[index];
                final selected = layout.id == selectedLayoutId;
                return _FurnitureChip(
                  layout: layout,
                  selected: selected,
                  onTap: () => onSelect(layout),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FurnitureChip extends StatelessWidget {
  const _FurnitureChip({
    required this.layout,
    required this.selected,
    required this.onTap,
  });

  final UserRoomLayout layout;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final itemColor = _colorFor(layout.item.itemType);
    return InkWell(
      borderRadius: BorderRadius.circular(MameroomRadius.medium),
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryMist.withValues(alpha: 0.65)
              : colors.primaryMist.withValues(alpha: 0.22),
          border: Border.all(
            color: selected ? colors.primary : colors.line,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(MameroomRadius.medium),
        ),
        child: Column(
          children: [
            Icon(_iconFor(layout.item.itemType), color: itemColor, size: 19),
            const SizedBox(height: 2),
            Text(
              layout.item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditModeButton extends StatelessWidget {
  const _EditModeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text('편집'),
      ),
    );
  }
}

class _EditToolbar extends StatelessWidget {
  const _EditToolbar({
    required this.onMove,
    required this.onRotate,
    required this.onStore,
    required this.onDelete,
    required this.onDone,
  });

  final VoidCallback onMove;
  final VoidCallback onRotate;
  final VoidCallback onStore;
  final VoidCallback onDelete;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      height: 66,
      padding: const EdgeInsets.all(MameroomSpacing.xs),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _softShadow(colors),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToolbarButton(
              icon: Icons.open_with_rounded,
              label: '이동',
              onTap: onMove,
            ),
          ),
          Expanded(
            child: _ToolbarButton(
              icon: Icons.rotate_right_rounded,
              label: '회전',
              onTap: onRotate,
            ),
          ),
          Expanded(
            child: _ToolbarButton(
              icon: Icons.inventory_2_outlined,
              label: '보관',
              onTap: onStore,
            ),
          ),
          Expanded(
            child: _ToolbarButton(
              icon: Icons.delete_outline_rounded,
              label: '삭제',
              onTap: onDelete,
            ),
          ),
          Expanded(
            child: _ToolbarButton(
              icon: Icons.check_rounded,
              label: '완료',
              onTap: onDone,
              primary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(MameroomRadius.medium),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary
                ? colors.primary
                : colors.primaryMist.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(MameroomRadius.medium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: primary ? MameroomColors.white : colors.primary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: primary ? MameroomColors.white : colors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomItemSprite extends StatelessWidget {
  const _RoomItemSprite({
    required this.item,
    required this.selected,
    required this.size,
  });

  final RoomItem item;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final color = _colorFor(item.itemType);
    return Tooltip(
      message: item.name,
      child: AnimatedContainer(
        key: ValueKey(item.id),
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.24 : 0.15),
          border: Border.all(
            color: selected ? colors.primary : color,
            width: selected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(MameroomRadius.medium),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.36),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(_iconFor(item.itemType), color: color, size: size * 0.56),
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter(this.colors);

  final MameroomTheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()..color = MameroomColors.white;
    final floor = Paint()..color = colors.primaryMist.withValues(alpha: 0.28);
    final line = Paint()
      ..color = colors.line
      ..strokeWidth = 2;
    final accent = Paint()..color = colors.primaryPale.withValues(alpha: 0.34);
    canvas.drawRect(Offset.zero & size, wall);
    final floorTop = size.height * 0.67;
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop),
      floor,
    );
    canvas.drawLine(Offset(0, floorTop), Offset(size.width, floorTop), line);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.23,
        size.height * 0.13,
        size.width * 0.2,
        size.height * 0.18,
      ),
      accent,
    );
    canvas.drawLine(
      Offset(size.width * 0.33, size.height * 0.13),
      Offset(size.width * 0.33, size.height * 0.31),
      line,
    );
    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.22),
      Offset(size.width * 0.43, size.height * 0.22),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: colors.ink),
      style: IconButton.styleFrom(
        backgroundColor: colors.paper,
        side: BorderSide(color: colors.line),
        fixedSize: const Size.square(38),
      ),
    );
  }
}

void _showPlaceholder(BuildContext context, String label) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$label 기능은 준비 중입니다.')));
}

List<BoxShadow> _softShadow(MameroomTheme colors) => [
  BoxShadow(
    color: colors.primary.withValues(alpha: 0.07),
    blurRadius: 14,
    offset: const Offset(0, 7),
  ),
];

IconData _iconFor(String type) {
  return switch (type) {
    'bed' => Icons.bed_rounded,
    'desk' => Icons.table_bar_outlined,
    'chair' => Icons.chair_outlined,
    'plant' => Icons.local_florist_outlined,
    'lamp' => Icons.light_outlined,
    'rug' => Icons.crop_landscape_outlined,
    'window' => Icons.window_rounded,
    'shelf' => Icons.library_books_rounded,
    'decor' => Icons.auto_awesome_rounded,
    _ => Icons.widgets_outlined,
  };
}

Color _colorFor(String type) {
  return switch (type) {
    'bed' => const Color(0xFF7C5CFF),
    'desk' => const Color(0xFF8B5E3C),
    'chair' => const Color(0xFF5C7CFA),
    'plant' => const Color(0xFF2F9E44),
    'lamp' => const Color(0xFFFFC857),
    'rug' => const Color(0xFF9C6ADE),
    'window' => const Color(0xFF6EA8FE),
    'shelf' => const Color(0xFF7A5230),
    'decor' => const Color(0xFFFFA94D),
    _ => MameroomColors.gray500,
  };
}

double _spriteSize(String type) {
  return switch (type) {
    'bed' => 70,
    'desk' => 58,
    'chair' => 46,
    'rug' => 64,
    'window' => 52,
    'shelf' => 54,
    _ => 48,
  };
}

String _comma(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

const _defaultBed = RoomItem(
  id: 'default-bed',
  itemCode: 'default_bed',
  name: '침대',
  description: '기본 침대',
  itemType: 'bed',
  rarity: 'common',
  price: 0,
  assetKey: 'default_bed',
  assetPath: 'default_bed.png',
  defaultPositionX: 0.18,
  defaultPositionY: 0.56,
  isActive: true,
);

const _defaultDesk = RoomItem(
  id: 'default-desk',
  itemCode: 'default_desk',
  name: '책상',
  description: '기본 책상',
  itemType: 'desk',
  rarity: 'common',
  price: 0,
  assetKey: 'default_desk',
  assetPath: 'default_desk.png',
  defaultPositionX: 0.76,
  defaultPositionY: 0.56,
  isActive: true,
);

const _defaultChair = RoomItem(
  id: 'default-chair',
  itemCode: 'default_chair',
  name: '의자',
  description: '기본 의자',
  itemType: 'chair',
  rarity: 'common',
  price: 0,
  assetKey: 'default_chair',
  assetPath: 'default_chair.png',
  defaultPositionX: 0.66,
  defaultPositionY: 0.67,
  isActive: true,
);

const _defaultRug = RoomItem(
  id: 'default-rug',
  itemCode: 'default_rug',
  name: '러그',
  description: '기본 러그',
  itemType: 'rug',
  rarity: 'common',
  price: 0,
  assetKey: 'default_rug',
  assetPath: 'default_rug.png',
  defaultPositionX: 0.45,
  defaultPositionY: 0.78,
  isActive: true,
);

const _defaultWindow = RoomItem(
  id: 'default-window',
  itemCode: 'default_window',
  name: '창문',
  description: '기본 창문',
  itemType: 'window',
  rarity: 'common',
  price: 0,
  assetKey: 'default_window',
  assetPath: 'default_window.png',
  defaultPositionX: 0.33,
  defaultPositionY: 0.24,
  isActive: true,
);

const _defaultPlant = RoomItem(
  id: 'default-plant',
  itemCode: 'default_plant',
  name: '화분',
  description: '기본 장식',
  itemType: 'plant',
  rarity: 'common',
  price: 0,
  assetKey: 'default_plant',
  assetPath: 'default_plant.png',
  defaultPositionX: 0.10,
  defaultPositionY: 0.36,
  isActive: true,
);

const _defaultShelf = RoomItem(
  id: 'default-shelf',
  itemCode: 'default_shelf',
  name: '책장',
  description: '기본 장식',
  itemType: 'shelf',
  rarity: 'common',
  price: 0,
  assetKey: 'default_shelf',
  assetPath: 'default_shelf.png',
  defaultPositionX: 0.89,
  defaultPositionY: 0.40,
  isActive: true,
);

const _defaultLayouts = [
  UserRoomLayout(
    id: 'layout-default-bed',
    item: _defaultBed,
    positionX: 0.18,
    positionY: 0.56,
  ),
  UserRoomLayout(
    id: 'layout-default-desk',
    item: _defaultDesk,
    positionX: 0.76,
    positionY: 0.56,
  ),
  UserRoomLayout(
    id: 'layout-default-chair',
    item: _defaultChair,
    positionX: 0.66,
    positionY: 0.67,
  ),
  UserRoomLayout(
    id: 'layout-default-rug',
    item: _defaultRug,
    positionX: 0.45,
    positionY: 0.78,
  ),
  UserRoomLayout(
    id: 'layout-default-window',
    item: _defaultWindow,
    positionX: 0.33,
    positionY: 0.24,
  ),
  UserRoomLayout(
    id: 'layout-default-plant',
    item: _defaultPlant,
    positionX: 0.10,
    positionY: 0.36,
  ),
  UserRoomLayout(
    id: 'layout-default-shelf',
    item: _defaultShelf,
    positionX: 0.89,
    positionY: 0.40,
  ),
];
