import 'package:ai_memory_coach/features/upload/presentation/pages/upload_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({MaterialInputMode? mode}) => ProviderScope(
    child: MaterialApp(home: UploadPage(initialMode: mode)),
  );

  testWidgets('fallback chooser exposes only the three supported methods', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text('직접 생성'), findsOneWidget);
    expect(find.text('텍스트 불러오기'), findsOneWidget);
    expect(find.text('PDF 불러오기'), findsOneWidget);
    expect(find.textContaining('Word'), findsNothing);
    expect(find.textContaining('PowerPoint'), findsNothing);
    expect(find.textContaining('카메라'), findsNothing);
  });

  testWidgets('manual form explains why generation is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(app(mode: MaterialInputMode.manual));
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('generate-questions-button')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('manual form fits a narrow screen at enlarged text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: app(mode: MaterialInputMode.manual),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('직접 생성'), findsOneWidget);
  });
}
