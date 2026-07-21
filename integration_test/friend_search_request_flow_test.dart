import 'package:ai_memory_coach/features/friends/presentation/pages/friend_search_page.dart';
import 'package:ai_memory_coach/shared/design_system/mameroom_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('searches, requests, accepts and exposes friend room action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(extensions: const [MameroomTheme.light]),
          home: const FriendSearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('friend-search-field')),
      'YUI204',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('\uCE5C\uAD6C \uC694\uCCAD'), findsOneWidget);

    await tester.tap(find.text('\uCE5C\uAD6C \uC694\uCCAD'));
    await tester.pumpAndSettle();
    expect(find.text('\uC694\uCCAD \uBCF4\uB0C4'), findsOneWidget);

    await tester.tap(find.byTooltip('\uBC1B\uC740 \uC694\uCCAD'));
    await tester.pumpAndSettle();
    expect(find.text('\uBBFC\uD638'), findsOneWidget);
    await tester.tap(find.text('\uC694\uCCAD \uC218\uB77D'));
    await tester.pumpAndSettle();
  });
}
