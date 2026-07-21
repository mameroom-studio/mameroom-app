import 'package:ai_memory_coach/features/home/presentation/pages/privacy_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('privacy policy renders all sections and release placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));

    expect(find.text('Mameroom 개인정보처리방침'), findsOneWidget);
    expect(find.textContaining('버전 1.0'), findsOneWidget);
    expect(find.textContaining('공고일 2026.07.21'), findsOneWidget);
    expect(find.textContaining('mameroom.studio@gmail.com'), findsWidgets);
    expect(find.textContaining('[OpenAI 이전 국가 및 계약 정보]'), findsWidgets);
    expect(find.text('1. 총칙'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('17. 시행일').last,
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('17. 시행일'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'privacy policy has no overflow on small screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(home: PrivacyPolicyPage()),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
