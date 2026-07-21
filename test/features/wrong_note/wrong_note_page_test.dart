import 'package:ai_memory_coach/features/wrong_note/data/repositories/wrong_note_repositories.dart';
import 'package:ai_memory_coach/features/wrong_note/presentation/pages/wrong_note_page.dart';
import 'package:ai_memory_coach/features/wrong_note/presentation/providers/wrong_note_providers.dart';
import 'package:ai_memory_coach/features/wrong_note/domain/repositories/wrong_note_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpPage(
  WidgetTester tester, {
  WrongNoteRepository repository = const MockWrongNoteRepository(),
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [wrongNoteRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: WrongNotePage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows summary, list, filter and sort', (tester) async {
    await pumpPage(tester);
    expect(find.text('오답노트'), findsOneWidget);
    expect(find.text('전체 오답'), findsOneWidget);
    expect(find.text('복습하기'), findsWidgets);
    await tester.tap(find.widgetWithText(FilterChip, '반복 오답'));
    await tester.pump();
    expect(find.text('오답 3회'), findsWidgets);
    await tester.tap(find.text('최근 틀린 순'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('기억률 낮은 순').last);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty state', (tester) async {
    await pumpPage(tester, repository: const ProductionWrongNoteRepository());
    expect(find.text('아직 오답이 없어요!'), findsOneWidget);
    expect(find.text('공부 시작하기'), findsOneWidget);
  });

  testWidgets('shows safe error state', (tester) async {
    await pumpPage(
      tester,
      repository: const MockWrongNoteRepository(shouldFail: true),
    );
    expect(find.text('오답노트를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.textContaining('fixture failure'), findsNothing);
  });

  testWidgets('has no overflow at target mobile sizes', (tester) async {
    for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
      await pumpPage(tester, size: size);
      expect(tester.takeException(), isNull);
    }
  });
}
