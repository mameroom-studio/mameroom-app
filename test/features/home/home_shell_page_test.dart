import 'package:ai_memory_coach/features/home/presentation/pages/home_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home shell shows fixed four-tab navigation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeShellPage(selectedIndex: 0, child: SizedBox.shrink()),
      ),
    );

    expect(find.text('\u{D648}'), findsOneWidget);
    expect(find.text('\u{ACF5}\u{BD80}'), findsOneWidget);
    expect(find.text('\u{CE5C}\u{AD6C}'), findsOneWidget);
    expect(find.text('\u{B0B4} \u{C815}\u{BCF4}'), findsOneWidget);
  });
}
