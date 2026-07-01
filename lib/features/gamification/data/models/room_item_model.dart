import '../../domain/entities/room_item.dart';

class RoomItemModel extends RoomItem {
  const RoomItemModel({
    required super.id,
    required super.itemCode,
    required super.name,
    required super.itemType,
    required super.price,
    required super.assetPath,
    required super.isActive,
  });

  factory RoomItemModel.fromJson(Map<String, dynamic> json) {
    return RoomItemModel(
      id: json['id'] as String,
      itemCode: json['item_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      itemType: json['item_type'] as String? ?? '',
      price: _intFrom(json['price']),
      assetPath: json['asset_path'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  static int _intFrom(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
      id: json['id'] as String,
      item: item,
      positionX: _doubleFrom(json['position_x']),
      positionY: _doubleFrom(json['position_y']),
    );
  }

  static double _doubleFrom(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.5;
  }
}