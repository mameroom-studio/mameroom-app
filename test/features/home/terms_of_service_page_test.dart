import 'package:ai_memory_coach/features/home/presentation/pages/terms_of_service_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(ThemeMode mode) {
  return MaterialApp(
    themeMode: mode,
    theme: ThemeData(useMaterial3: true),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    home: const TermsOfServicePage(),
  );
}

void main() {
  testWidgets('terms page renders service-ready content', (tester) async {
    await tester.pumpWidget(_wrap(ThemeMode.light));
    await tester.pumpAndSettle();

    expect(find.text('\uC774\uC6A9\uC57D\uAD00'), findsWidgets);
    expect(
      find.text('\uCD5C\uC885 \uC218\uC815\uC77C  2026.08.01'),
      findsOneWidget,
    );
    expect(
      find.text('\uC81C1\uC870 \uC11C\uBE44\uC2A4 \uC18C\uAC1C'),
      findsOneWidget,
    );
    expect(
      find.text('\uC81C5\uC870 AI \uC11C\uBE44\uC2A4 \uC774\uC6A9'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('\uC0AC\uC6A9\uC790 \uAD8C\uB9AC \uBCF4\uD638'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.text('\uC0AC\uC6A9\uC790 \uAD8C\uB9AC \uBCF4\uD638'),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  for (final size in <Size>[Size(360, 800), Size(390, 844), Size(412, 915)]) {
    testWidgets(
      'terms page has no overflow at \${size.width}x\${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(ThemeMode.light));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -900),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('terms page supports dark mode', (tester) async {
    await tester.pumpWidget(_wrap(ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(find.text('\uC774\uC6A9\uC57D\uAD00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
