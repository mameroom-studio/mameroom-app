import 'package:ai_memory_coach/features/friends/presentation/pages/friend_search_page.dart';
import 'package:ai_memory_coach/shared/design_system/mameroom_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => ProviderScope(
    child: MaterialApp(
      theme: ThemeData(extensions: const [MameroomTheme.light]),
      home: const FriendSearchPage(),
    ),
  );

  testWidgets('shows initial search, filters and coming soon state', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('friend-search-field')), findsOneWidget);
    expect(find.text('\uCD94\uCC9C \uCE5C\uAD6C'), findsOneWidget);
    expect(find.text('\uD559\uAD50 \u00B7 COMING SOON'), findsOneWidget);
  });

  testWidgets('validates a one-character query', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('friend-search-field')), 'a');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('validation')), findsOneWidget);
  });

  testWidgets('shows results and changes request state', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('friend-search-field')),
      'YUI204',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('results')), findsOneWidget);
    expect(find.text('\uCE5C\uAD6C \uC694\uCCAD'), findsOneWidget);
    await tester.tap(find.text('\uCE5C\uAD6C \uC694\uCCAD'));
    await tester.pumpAndSettle();
    expect(find.text('\uC694\uCCAD \uBCF4\uB0C4'), findsOneWidget);
  });

  testWidgets('does not overflow with long text and 1.3 scale', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: app(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
