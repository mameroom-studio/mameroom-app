import 'package:ai_memory_coach/features/library/domain/entities/study_material.dart';
import 'package:ai_memory_coach/features/library/presentation/pages/library_page.dart';
import 'package:ai_memory_coach/features/library/presentation/providers/library_mock_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dashboard = LibraryDashboard(
    todayReviewCount: 0,
    totalMemoryPercent: 70,
    materials: [
      _material('old', '영어 단어장', DateTime.utc(2026, 1), DateTime.utc(2026, 6)),
      _material('new', '미적분 공식 정리', DateTime.utc(2026, 7), null),
    ],
    recentRecords: const [],
  );

  testWidgets('searches title in place, clears, and shows distinct no result', (
    tester,
  ) async {
    await _pump(tester, dashboard);
    await tester.tap(find.byTooltip('검색'));
    await tester.pump();

    expect(find.byKey(const ValueKey('material-search-field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('material-search-field')),
      '미적분',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('material-card-new')), findsOneWidget);
    expect(find.byKey(const ValueKey('material-card-old')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('material-search-field')),
      '찾을 수 없는 자료',
    );
    await tester.pump();
    expect(find.text('찾는 자료가 없어요.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('material-search-clear')));
    await tester.pump();
    expect(find.byKey(const ValueKey('material-card-new')), findsOneWidget);
    expect(find.byKey(const ValueKey('material-card-old')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sort sheet cancels or applies while preserving search query', (
    tester,
  ) async {
    await _pump(tester, dashboard);
    await tester.tap(find.byKey(const ValueKey('material-sort-button')));
    await tester.pumpAndSettle();
    expect(find.text('정렬하기'), findsOneWidget);
    expect(
      tester
          .widget<RadioListTile<dynamic>>(
            find.byKey(const ValueKey('material-sort-newest')),
          )
          .value,
      isNotNull,
    );
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('material-sort-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이름순'));
    await tester.tap(find.byKey(const ValueKey('material-sort-apply')));
    await tester.pumpAndSettle();

    final english = tester.getTopLeft(find.text('영어 단어장').last).dy;
    final math = tester.getTopLeft(find.text('미적분 공식 정리').last).dy;
    expect(math, lessThan(english));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits small screen and 1.5 text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, dashboard, textScale: 1.5);
    await tester.tap(find.byTooltip('검색'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  LibraryDashboard dashboard, {
  double textScale = 1,
}) {
  return tester
      .pumpWidget(
        ProviderScope(
          overrides: [
            libraryDashboardProvider.overrideWith((_) async => dashboard),
          ],
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const MaterialApp(home: Scaffold(body: LibraryPage())),
          ),
        ),
      )
      .then((_) => tester.pumpAndSettle());
}

StudyMaterial _material(
  String id,
  String title,
  DateTime uploadedAt,
  DateTime? lastStudiedAt,
) {
  return StudyMaterial(
    id: id,
    title: title,
    sectionCount: 0,
    progressPercent: 30,
    memoryPercent: 70,
    nextReviewLabel: 'Ready',
    totalQuestionCount: 50,
    status: 'completed',
    uploadedAt: uploadedAt,
    lastStudiedAt: lastStudiedAt,
  );
}
