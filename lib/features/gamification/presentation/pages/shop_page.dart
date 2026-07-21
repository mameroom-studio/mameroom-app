import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/modals/mameroom_modals.dart';
import '../../../../core/presentation/states/mameroom_states.dart';
import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../home/presentation/pages/home_shell_page.dart';
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
  int _tab = 0;
  String? _highlightedId;

  static const _tabs = [_recommend, _furniture, _decor, _arboretum, _package];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRoomControllerProvider);
    final colors = context.mameroom;
    return Scaffold(
      backgroundColor: colors.cloud,
      body: SafeArea(
        child: state.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(18),
            child: MameroomLoadingState.shop(),
          ),
          error: (error, _) => MameroomErrorState.network(
            onRetry: () => ref.read(myRoomControllerProvider.notifier).load(),
          ),
          data: (room) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: CustomScrollView(
                key: const ValueKey('game-shop-scroll'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    sliver: SliverList.list(
                      children: [
                        _Header(room: room),
                        const SizedBox(height: 12),
                        _CoinHero(balance: room.walletBalance),
                        const SizedBox(height: 12),
                        _Tabs(
                          labels: _tabs,
                          selected: _tab,
                          onTap: (v) => setState(() => _tab = v),
                        ),
                        const SizedBox(height: 12),
                        if (_tab == 0)
                          _FeaturedItem(
                            item: _featured(room.shopItems),
                            owned: _featured(room.shopItems) == null
                                ? false
                                : room.owns(_featured(room.shopItems)!.id),
                            canAfford: _featured(room.shopItems) == null
                                ? false
                                : room.walletBalance >=
                                      _featured(room.shopItems)!.price,
                            onTap: _showDetail,
                            onBuy: _buyFromCard,
                          ),
                        if (_tab == 0) const SizedBox(height: 16),
                        _SectionHeader(
                          title: _tab == 4
                              ? _recommendedPackage
                              : _popularItems,
                          actionLabel: _tab == 4 ? null : _viewAll,
                          onAction: () => setState(() => _tab = 0),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  if (_tab == 4)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                      sliver: SliverToBoxAdapter(
                        child: _PackageCard(
                          items: room.shopItems,
                          onBuy: () {
                            final first = room.shopItems.isEmpty
                                ? null
                                : room.shopItems.first;
                            if (first != null) _buyFromCard(first);
                          },
                        ),
                      ),
                    )
                  else if (_filtered(room.shopItems).isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(14, 0, 14, 18),
                        child: MameroomEmptyState(
                          title: _comingSoonItems,
                          description: '',
                          icon: MameroomStatePixelIcon.shop,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                      sliver: _ProductGrid(
                        items: _filtered(room.shopItems),
                        owned: room.ownedItemIds,
                        balance: room.walletBalance,
                        highlightedId: _highlightedId,
                        onTap: _showDetail,
                        onBuy: _buyFromCard,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _ShopBottomNav(),
    );
  }

  List<RoomItem> _filtered(List<RoomItem> items) {
    if (_tab == 0) return items;
    final label = _tabs[_tab];
    return items
        .where((item) => _categoryOf(item.itemType) == label)
        .toList(growable: false);
  }

  RoomItem? _featured(List<RoomItem> items) {
    if (items.isEmpty) return null;
    final sorted = [...items]..sort((a, b) => b.price.compareTo(a.price));
    return sorted.first;
  }

  Future<void> _showDetail(RoomItem item) async {
    final room = ref.read(myRoomControllerProvider).asData?.value;
    if (room == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.mameroom.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _DetailSheet(
        item: item,
        owned: room.owns(item.id),
        canAfford: room.walletBalance >= item.price,
        onBuy: () async {
          Navigator.of(context).pop();
          await _buyFromCard(item);
        },
      ),
    );
  }

  Future<void> _buyFromCard(RoomItem item) async {
    final room = ref.read(myRoomControllerProvider).asData?.value;
    if (room == null || room.owns(item.id)) return;
    if (room.walletBalance < item.price) {
      await MameroomPopupService.showError(
        context,
        title: _notEnoughCoinTitle,
        message: _notEnoughCoinMessage,
      );
      return;
    }
    await _purchase(item);
  }

  Future<void> _purchase(RoomItem item) async {
    try {
      await ref.read(myRoomControllerProvider.notifier).purchase(item);
      if (!mounted) return;
      setState(() => _highlightedId = item.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_purchaseDone \${item.name}'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: _decorateRoom,
            onPressed: () => context.go(RoomPage.routePath),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await MameroomPopupService.showError(
        context,
        title: _purchaseFailed,
        message: _purchaseError(error),
      );
    }
  }

  String _purchaseError(Object error) {
    final text = error.toString();
    if (text.contains('Not enough M-Coin')) {
      return _notEnoughCoinMessage;
    }
    if (text.contains('duplicate') ||
        text.contains('already') ||
        text.contains('unique')) {
      return _alreadyOwned;
    }
    return text.replaceFirst('Exception: ', '');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.room});

  final MyRoomState room;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        IconButton(
          tooltip: _back,
          onPressed: () => context.go(RoomPage.routePath),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primary),
        ),
        Expanded(
          child: Text(
            _shop,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.ink,
            ),
          ),
        ),
        _CoinPill(value: room.walletBalance),
      ],
    );
  }
}

class _CoinHero extends StatelessWidget {
  const _CoinHero({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primarySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _shadow(colors),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'M-Coin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Text(
                    _comma(balance),
                    key: ValueKey(balance),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _HeroChip(label: _thisWeekEarned, value: '+520'),
                    _HeroChip(label: _studyTodayReward, value: '+40 Coin'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: List.generate(labels.length, (i) {
        final active = selected == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 5),
            child: Material(
              color: active ? colors.primary : colors.paper,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(i),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? colors.primary : colors.line,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tabIcon(i),
                        size: 15,
                        color: active ? Colors.white : colors.primary,
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          style: TextStyle(
                            color: active ? Colors.white : colors.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FeaturedItem extends StatelessWidget {
  const _FeaturedItem({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.onTap,
    required this.onBuy,
  });

  final RoomItem? item;
  final bool owned;
  final bool canAfford;
  final ValueChanged<RoomItem> onTap;
  final ValueChanged<RoomItem> onBuy;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final item = this.item;
    if (item == null) {
      return const MameroomEmptyState(
        title: _comingSoonItems,
        description: '',
        icon: MameroomStatePixelIcon.shop,
      );
    }
    final rarity = _rarity(item.rarity, item.price);
    return InkWell(
      onTap: () => onTap(item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.primaryPale),
          boxShadow: _shadow(colors),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _PixelIcon(type: item.itemType, size: 118),
                const Positioned(top: -7, left: -7, child: _TinyBadge(_hot)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RarityBadge(rarity: rarity),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stars,
                    style: TextStyle(
                      color: colors.sun,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _PriceLine(price: item.price),
                  const SizedBox(height: 5),
                  _MotivationText(price: item.price),
                  const SizedBox(height: 10),
                  _BuyButton(
                    owned: owned,
                    canAfford: canAfford,
                    onPressed: () => onBuy(item),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.items,
    required this.owned,
    required this.balance,
    required this.highlightedId,
    required this.onTap,
    required this.onBuy,
  });

  final List<RoomItem> items;
  final Set<String> owned;
  final int balance;
  final String? highlightedId;
  final ValueChanged<RoomItem> onTap;
  final ValueChanged<RoomItem> onBuy;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 252,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return _ItemCard(
          item: item,
          owned: owned.contains(item.id),
          canAfford: balance >= item.price,
          active: highlightedId == item.id,
          isNew: i <= 1,
          onTap: () => onTap(item),
          onBuy: () => onBuy(item),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.active,
    required this.isNew,
    required this.onTap,
    required this.onBuy,
  });

  final RoomItem item;
  final bool owned;
  final bool canAfford;
  final bool active;
  final bool isNew;
  final VoidCallback onTap;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final rarity = _rarity(item.rarity, item.price);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? colors.primary : colors.line,
            width: active ? 2 : 1,
          ),
          boxShadow: _shadow(colors),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (isNew) const _TinyBadge(_new),
                if (!isNew) _RarityBadge(rarity: rarity, compact: true),
                const Spacer(),
                if (owned)
                  Icon(Icons.check_circle_rounded, color: colors.seedGreen),
              ],
            ),
            Expanded(
              child: Center(child: _PixelIcon(type: item.itemType, size: 82)),
            ),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            _PriceLine(price: item.price, compact: true),
            const SizedBox(height: 3),
            _MotivationText(price: item.price, compact: true),
            const SizedBox(height: 8),
            _BuyButton(
              owned: owned,
              canAfford: canAfford,
              compact: true,
              onPressed: onBuy,
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.items, required this.onBuy});

  final List<RoomItem> items;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final shown = items.take(3).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primaryPale),
        boxShadow: _shadow(colors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _TinyBadge('20% OFF'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Starter Pack',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final item in shown) ...[
                Expanded(
                  child: Column(
                    children: [
                      _PixelIcon(type: item.itemType, size: 70),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                if (item != shown.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _PriceLine(price: 2800),
              Text(
                '3,600',
                style: TextStyle(
                  color: colors.muted,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(
                width: 96,
                height: 38,
                child: FilledButton(onPressed: onBuy, child: const Text(_buy)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.onBuy,
  });

  final RoomItem item;
  final bool owned;
  final bool canAfford;
  final Future<void> Function() onBuy;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final rarity = _rarity(item.rarity, item.price);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _PixelIcon(type: item.itemType, size: 150),
                      const SizedBox(height: 8),
                      Text(
                        _roomPreviewSoon,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RarityBadge(rarity: rarity),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description.isEmpty
                            ? _defaultDescription
                            : item.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.muted,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PriceLine(price: item.price),
                      const SizedBox(height: 6),
                      _MotivationText(price: item.price),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BuyButton(owned: owned, canAfford: canAfford, onPressed: onBuy),
          ],
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.price, this.compact = false});

  final int price;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.monetization_on_rounded,
          color: colors.sun,
          size: compact ? 15 : 18,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${_comma(price)} M-Coin',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _MotivationText extends StatelessWidget {
  const _MotivationText({required this.price, this.compact = false});

  final int price;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final needed = (price / 20).ceil();
    return Text(
      compact ? _reviewGoalShort(needed) : _reviewGoal(needed),
      maxLines: compact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: context.mameroom.primary,
        fontWeight: FontWeight.w900,
        fontSize: compact ? 10.5 : null,
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.owned,
    required this.canAfford,
    required this.onPressed,
    this.compact = false,
  });

  final bool owned;
  final bool canAfford;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = owned ? _owned : _buy;
    return SizedBox(
      height: compact ? 34 : 42,
      child: FilledButton(
        onPressed: owned ? null : onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, color: colors.sun, size: 18),
          const SizedBox(width: 4),
          Text(
            _comma(value),
            style: TextStyle(color: colors.ink, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.mameroom.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity, this.compact = false});

  final Rarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: rarity.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          color: rarity.color,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PixelIcon extends StatelessWidget {
  const _PixelIcon({required this.type, required this.size});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _itemColor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(size * 0.16),
      ),
      child: Icon(_itemIcon(type), color: color, size: size * 0.56),
    );
  }
}

class _ShopBottomNav extends StatelessWidget {
  const _ShopBottomNav();

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: 3,
    onDestinationSelected: (i) {
      switch (i) {
        case 0:
          context.go(HomeShellPage.homeRoutePath);
        case 1:
          context.go(HomeShellPage.studyRoutePath);
        case 2:
          context.go(RoomPage.routePath);
        case 3:
          context.go(ShopPage.routePath);
        case 4:
          context.go(HomeShellPage.myInfoRoutePath);
      }
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: _home,
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_rounded),
        label: _study,
      ),
      NavigationDestination(
        icon: Icon(Icons.park_outlined),
        selectedIcon: Icon(Icons.park_rounded),
        label: _arboretum,
      ),
      NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront_rounded),
        label: _shop,
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: _myInfo,
      ),
    ],
  );
}

enum Rarity {
  common('Common', Color(0xFF9AA0A6)),
  rare('Rare', Color(0xFF2F80ED)),
  epic('Epic', Color(0xFF8A5CF6)),
  legendary('Legendary', Color(0xFFFF9F1C)),
  mythic('Mythic', Color(0xFFE9407A));

  const Rarity(this.label, this.color);

  final String label;
  final Color color;
}

Rarity _rarity(String raw, int price) {
  final value = raw.toLowerCase();
  if (value.contains('mythic')) return Rarity.mythic;
  if (value.contains('legend')) return Rarity.legendary;
  if (value.contains('epic')) return Rarity.epic;
  if (value.contains('rare')) return Rarity.rare;
  if (price >= 2800) return Rarity.mythic;
  if (price >= 2000) return Rarity.legendary;
  if (price >= 1400) return Rarity.epic;
  if (price >= 900) return Rarity.rare;
  return Rarity.common;
}

String _categoryOf(String type) => switch (type) {
  'desk' || 'chair' || 'bed' || 'bookcase' || 'shelf' => _furniture,
  'plant' || 'tree' || 'fountain' => _arboretum,
  'package' => _package,
  _ => _decor,
};

IconData _tabIcon(int index) => switch (index) {
  0 => Icons.star_rounded,
  1 => Icons.chair_rounded,
  2 => Icons.local_florist_rounded,
  3 => Icons.park_rounded,
  _ => Icons.card_giftcard_rounded,
};

IconData _itemIcon(String type) => switch (type) {
  'desk' => Icons.table_bar_rounded,
  'chair' => Icons.chair_rounded,
  'bed' => Icons.bed_rounded,
  'plant' || 'tree' => Icons.local_florist_rounded,
  'lamp' => Icons.lightbulb_rounded,
  'rug' => Icons.crop_landscape_rounded,
  'clock' => Icons.schedule_rounded,
  'fountain' => Icons.water_drop_rounded,
  'package' => Icons.inventory_2_rounded,
  _ => Icons.weekend_rounded,
};

Color _itemColor(String type) => switch (type) {
  'desk' || 'bookcase' || 'shelf' => const Color(0xFF8B5E3C),
  'chair' || 'bed' => const Color(0xFF705CFF),
  'plant' || 'tree' => const Color(0xFF6DAE3A),
  'lamp' => const Color(0xFFFFC857),
  'rug' => const Color(0xFF9C6ADE),
  'clock' => const Color(0xFF495057),
  'fountain' => const Color(0xFF31A9FF),
  'package' => const Color(0xFF8A5CF6),
  _ => const Color(0xFF705CFF),
};

List<BoxShadow> _shadow(MameroomTheme colors) => [
  BoxShadow(
    color: colors.primary.withValues(alpha: 0.08),
    blurRadius: 18,
    offset: const Offset(0, 8),
  ),
];

String _comma(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

String _reviewGoal(int needed) =>
    '\uBCF5\uC2B5 $needed\uBB38\uC81C\uBA74 \uAD6C\uB9E4 \uAC00\uB2A5';
String _reviewGoalShort(int needed) =>
    '\uBCF5\uC2B5 $needed\uBB38\uC81C\uBA74 OK';

const _shop = '\uC0C1\uC810';
const _back = '\uB4A4\uB85C\uAC00\uAE30';
const _home = '\uD648';
const _study = '\uACF5\uBD80';
const _myInfo = '\uB0B4 \uC815\uBCF4';
const _recommend = '\uCD94\uCC9C';
const _furniture = '\uAC00\uAD6C';
const _decor = '\uC7A5\uC2DD';
const _arboretum = '\uC218\uBAA9\uC6D0';
const _package = '\uD328\uD0A4\uC9C0';
const _popularItems = '\uC778\uAE30 \uC0C1\uD488';
const _recommendedPackage = '\uCD94\uCC9C \uD328\uD0A4\uC9C0';
const _viewAll = '\uB354\uBCF4\uAE30';
const _thisWeekEarned = '\uC774\uBC88 \uC8FC \uD68D\uB4DD';
const _studyTodayReward = '\uC624\uB298 \uACF5\uBD80\uD558\uBA74';
const _hot = 'HOT';
const _new = 'NEW';
const _stars = '\u2605\u2605\u2605\u2605\u2605';
const _buy = '\uAD6C\uB9E4';
const _owned = '\uBCF4\uC720\uC911';
const _purchaseDone = '\uAD6C\uB9E4 \uC644\uB8CC!';
const _decorateRoom = '\uBC29 \uAFB8\uBBF8\uB7EC \uAC00\uAE30';
const _purchaseFailed = '\uAD6C\uB9E4 \uC2E4\uD328';
const _notEnoughCoinTitle = 'M-Coin \uBD80\uC871';
const _notEnoughCoinMessage =
    '\uC624\uB298 \uACF5\uBD80\uB97C \uC644\uB8CC\uD558\uBA74 +40 Coin\uC744 \uD68D\uB4DD\uD560 \uC218 \uC788\uC5B4\uC694.';
const _alreadyOwned =
    '\uC774\uBBF8 \uBCF4\uC720\uD55C \uC544\uC774\uD15C\uC785\uB2C8\uB2E4.';
const _defaultDescription =
    '\uB0B4 \uBC29\uC744 \uB354 \uC544\uB291\uD558\uAC8C \uBC14\uAFFF\uC8FC\uB294 \uD2B9\uBCC4\uD55C \uC544\uC774\uD15C\uC774\uC5D0\uC694.';
const _roomPreviewSoon = 'Room Preview \uC900\uBE44 \uC911';
const _comingSoonItems =
    '\uACE7 \uC0C8\uB85C\uC6B4 \uC544\uC774\uD15C\uC774 \uCD94\uAC00\uB429\uB2C8\uB2E4.';
