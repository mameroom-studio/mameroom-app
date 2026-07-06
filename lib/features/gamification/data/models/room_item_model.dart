import '../../domain/entities/room_item.dart';

class RoomItemModel extends RoomItem {
  const RoomItemModel({
    required super.id,
    required super.itemCode,
    required super.name,
    required super.description,
    required super.itemType,
    required super.rarity,
    required super.price,
    required super.assetKey,
    required super.assetPath,
    required super.defaultPositionX,
    required super.defaultPositionY,
    required super.isActive,
  });

  factory RoomItemModel.fromJson(Map<String, dynamic> json) {
    final itemCode = json['item_code'] as String? ?? '';
    return RoomItemModel(
      id: json['id'] as String,
      itemCode: itemCode,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      itemType: json['item_type'] as String? ?? '',
      rarity: json['rarity'] as String? ?? 'common',
      price: _intFrom(json['price']),
      assetKey: json['asset_key'] as String? ?? itemCode,
      assetPath: json['asset_path'] as String? ?? '',
      defaultPositionX: _doubleFrom(json['default_position_x'], fallback: 0.5),
      defaultPositionY: _doubleFrom(json['default_position_y'], fallback: 0.7),
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  static int _intFrom(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleFrom(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class UserRoomLayoutModel extends UserRoomLayout {
  const UserRoomLayoutModel({
    required super.id,
    required super.item,
    required super.positionX,
    required super.positionY,
  });

  factory UserRoomLayoutModel.fromJson({
    required Map<String, dynamic> json,
    required RoomItem item,
  }) {
    return UserRoomLayoutModel(
      id: json['id'] as String? ?? 'default:${item.id}',
      item: item,
      positionX: _doubleFrom(json['position_x'], fallback: item.defaultPositionX),
      positionY: _doubleFrom(json['position_y'], fallback: item.defaultPositionY),
    );
  }

  static double _doubleFrom(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
