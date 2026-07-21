import 'package:ai_memory_coach/features/review/presentation/pages/review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _k(List<int> c) => String.fromCharCodes(c);

final _todayReview = _k([50724, 45720, 51032, 32, 48373, 49845]);
final _startReview = _k([48373, 49845, 32, 49884, 51089, 54616, 44592]);
final _emptyDone = _k([
  50724,
  45720,
  32,
  48373,
  49845,
  51008,
  32,
  45149,
  45228,
  50612,
  50836,
  33,
]);
final _submit = _k([51228, 52636, 54616, 44592]);
final _memoryRate = _k([44592, 50613, 47456]);
final _exitTitle = _k([
  48373,
  49845,
  51012,
  32,
  51333,
  47308,
  54624,
  44620,
  50836,
  63,
]);
final _reviewDone = _k([48373, 49845, 32, 50756, 47308]);

Future<void> _pumpReview(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool empty = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF705CFF),
        ),
        home: ReviewPage(useMockReview: true, mockEmpty: empty),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('review home renders without diamond', (tester) async {
    await _pumpReview(tester);

    expect(find.text(_todayReview), findsWidgets);
    expect(find.text(_startReview), findsOneWidget);
    expect(find.textContaining('Diamond'), findsNothing);
    expect(find.textContaining('Diamond'), findsNothing);
  });

  testWidgets('empty review state renders', (tester) async {
    await _pumpReview(tester, empty: true);

    expect(find.text(_emptyDone), findsOneWidget);
  });

  testWidgets('option select enables submit and shows feedback', (
    tester,
  ) async {
    await _pumpReview(tester);
    await tester.tap(find.text(_startReview));
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(FilledButton, _submit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.text('현재 기억률'));
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text(_memoryRate), findsWidgets);
  });

  testWidgets('bookmark and exit modal work', (tester) async {
    await _pumpReview(tester);
    await tester.tap(find.text(_startReview));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
    await tester.pump();
    expect(find.text('Bookmarked'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text(_exitTitle), findsOneWidget);
  });

  testWidgets('pass flow reaches complete state', (tester) async {
    await _pumpReview(tester);
    await tester.tap(find.text(_startReview));
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pumpAndSettle();
    }

    expect(find.text(_reviewDone), findsWidgets);
    expect(find.textContaining('Diamond'), findsNothing);
  });

  testWidgets('review page has no overflow on target mobile sizes', (
    tester,
  ) async {
    for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
      await _pumpReview(tester, size: size);
      expect(tester.takeException(), isNull);
    }
  });
}
