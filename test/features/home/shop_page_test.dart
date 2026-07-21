import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_memory_coach/features/gamification/domain/entities/room_item.dart';
import 'package:ai_memory_coach/features/gamification/presentation/pages/shop_page.dart';
import 'package:ai_memory_coach/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRoomController extends MyRoomController {
  _FakeRoomController(super.ref) {
    state = AsyncData(_roomState);
  }

  @override
  Future<void> load() async {
    state = AsyncData(_roomState);
  }

  @override
  Future<void> purchase(RoomItem item) async {
    state = AsyncData(
      MyRoomState(
        walletBalance: _roomState.walletBalance - item.price,
        shopItems: _roomState.shopItems,
        ownedItemIds: {..._roomState.ownedItemIds, item.id},
        layouts: _roomState.layouts,
      ),
    );
  }
}

const _bed = RoomItem(
  id: 'bed',
  itemCode: 'purple_bed',
  name: '\uD3EC\uADFC\uD55C \uCE68\uB300',
  description:
      '\uD3EC\uADFC\uD55C \uBCF4\uB77C\uC0C9 \uCE68\uB300\uC608\uC694.',
  itemType: 'bed',
  rarity: 'epic',
  price: 1200,
  assetKey: 'bed',
  assetPath: 'bed.png',
  defaultPositionX: 0.5,
  defaultPositionY: 0.6,
  isActive: true,
);

const _desk = RoomItem(
  id: 'desk',
  itemCode: 'wood_desk',
  name: '\uC6B0\uB4DC \uCC45\uC0C1',
  description:
      '\uACF5\uBD80\uD558\uAE30 \uC88B\uC740 \uCC45\uC0C1\uC774\uC5D0\uC694.',
  itemType: 'desk',
  rarity: 'rare',
  price: 1000,
  assetKey: 'desk',
  assetPath: 'desk.png',
  defaultPositionX: 0.25,
  defaultPositionY: 0.7,
  isActive: true,
);

const _plant = RoomItem(
  id: 'plant',
  itemCode: 'plant_pot',
  name: '\uBAAC\uC2A4\uD14C\uB77C \uD654\uBD84',
  description:
      '\uC2F1\uADF8\uB7EC\uC6B4 \uC0DD\uAE30\uB97C \uC8FC\uB294 \uC7A5\uC2DD\uC774\uC5D0\uC694.',
  itemType: 'plant',
  rarity: 'common',
  price: 800,
  assetKey: 'plant',
  assetPath: 'plant.png',
  defaultPositionX: 0.7,
  defaultPositionY: 0.68,
  isActive: true,
);

final _roomState = MyRoomState(
  walletBalance: 12450,
  shopItems: const [_bed, _desk, _plant],
  ownedItemIds: const {'desk'},
  layouts: const [],
);

Widget _wrap({GlobalKey? captureKey}) {
  return RepaintBoundary(
    key: captureKey,
    child: ProviderScope(
      overrides: [
        myRoomControllerProvider.overrideWith(
          (ref) => _FakeRoomController(ref),
        ),
      ],
      child: const MaterialApp(home: ShopPage()),
    ),
  );
}

Future<void> _writeScreenshot(WidgetTester tester, GlobalKey key) async {
  const path = String.fromEnvironment('SHOP_SCREENSHOT_PATH');
  if (path.isEmpty) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await tester.runAsync(() async {
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('game shop renders coin hero, featured item, and product grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final captureKey = GlobalKey();
    await tester.pumpWidget(_wrap(captureKey: captureKey));
    await tester.pumpAndSettle();

    expect(find.text('\uC0C1\uC810'), findsWidgets);
    expect(find.text('M-Coin'), findsOneWidget);
    expect(find.text('12,450'), findsWidgets);
    expect(find.text('\uC774\uBC88 \uC8FC \uD68D\uB4DD +520'), findsOneWidget);
    expect(
      find.text('\uC624\uB298 \uACF5\uBD80\uD558\uBA74 +40 Coin'),
      findsOneWidget,
    );
    expect(find.text('HOT'), findsOneWidget);
    expect(find.text('\uD3EC\uADFC\uD55C \uCE68\uB300'), findsWidgets);
    expect(find.text('1,200 M-Coin'), findsWidgets);
    expect(find.textContaining('\uBCF5\uC2B5'), findsWidgets);
    expect(find.text('\uC778\uAE30 \uC0C1\uD488'), findsOneWidget);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.text('Shop Categories'), findsNothing);
    expect(find.text('Rarity System'), findsNothing);

    await _writeScreenshot(tester, captureKey);
  });

  testWidgets('item detail bottom sheet renders M-Coin purchase controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('\uD3EC\uADFC\uD55C \uCE68\uB300').first);
    await tester.pumpAndSettle();

    expect(find.text('\uAD6C\uB9E4'), findsWidgets);
    expect(find.text('1,200 M-Coin'), findsWidgets);
    expect(find.text('Room Preview \uC900\uBE44 \uC911'), findsOneWidget);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
  });

  testWidgets(
    'purchase decreases M-Coin, updates inventory, and links room editor',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('\uAD6C\uB9E4').first);
      await tester.pumpAndSettle();

      expect(find.text('11,250'), findsWidgets);
      expect(find.textContaining('\uAD6C\uB9E4 \uC644\uB8CC!'), findsOneWidget);
      expect(
        find.text('\uBC29 \uAFB8\uBBF8\uB7EC \uAC00\uAE30'),
        findsOneWidget,
      );
      expect(find.text('\uBCF4\uC720\uC911'), findsWidgets);
    },
  );

  testWidgets('empty category renders cute empty state', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('\uD328\uD0A4\uC9C0'));
    await tester.pumpAndSettle();

    expect(find.text('\uCD94\uCC9C \uD328\uD0A4\uC9C0'), findsOneWidget);
    expect(find.text('Starter Pack'), findsOneWidget);
  });
}
