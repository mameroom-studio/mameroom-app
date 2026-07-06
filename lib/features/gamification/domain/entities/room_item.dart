class RoomItem {
  const RoomItem({
    required this.id,
    required this.itemCode,
    required this.name,
    required this.description,
    required this.itemType,
    required this.rarity,
    required this.price,
    required this.assetKey,
    required this.assetPath,
    required this.defaultPositionX,
    required this.defaultPositionY,
    required this.isActive,
  });

  final String id;
  final String itemCode;
  final String name;
  final String description;
  final String itemType;
  final String rarity;
  final int price;
  final String assetKey;
  final String assetPath;
  final double defaultPositionX;
  final double defaultPositionY;
  final bool isActive;
}

class UserRoomLayout {
  const UserRoomLayout({
    required this.id,
    required this.item,
    required this.positionX,
    required this.positionY,
  });

  final String id;
  final RoomItem item;
  final double positionX;
  final double positionY;
}

class MyRoomState {
  const MyRoomState({
    required this.walletBalance,
    required this.shopItems,
    required this.ownedItemIds,
    required this.layouts,
  });

  final int walletBalance;
  final List<RoomItem> shopItems;
  final Set<String> ownedItemIds;
  final List<UserRoomLayout> layouts;

  List<RoomItem> get ownedItems {
    return shopItems
        .where((item) => ownedItemIds.contains(item.id))
        .toList(growable: false);
  }

  bool owns(String itemId) => ownedItemIds.contains(itemId);
}
