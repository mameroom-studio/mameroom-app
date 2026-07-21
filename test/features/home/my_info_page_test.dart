import 'package:ai_memory_coach/features/achievements/presentation/pages/achievement_page.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/home_shell_page.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/my_info_page.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/terms_of_service_page.dart';
import 'package:ai_memory_coach/features/settings/presentation/version_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

Widget _wrap(Widget child) => ProviderScope(
  overrides: [
    packageInfoProvider.overrideWith(
      (_) async => PackageInfo(
        appName: 'Mameroom',
        packageName: 'com.mameroom.app',
        version: '1.0.0',
        buildNumber: '1',
      ),
    ),
  ],
  child: MaterialApp(home: child),
);

Future<void> _pumpAt(
  WidgetTester tester,
  Size size, {
  Widget child = const MyInfoPage(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_wrap(child));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('my page renders primary account sections', (tester) async {
    await _pumpAt(tester, const Size(390, 844));
    expect(find.text('\uB0B4 \uC815\uBCF4'), findsOneWidget);
    expect(find.text('M-Coin'), findsOneWidget);
    expect(find.text('\uC774\uC6A9 \uD604\uD669'), findsOneWidget);
    expect(find.text('320\uBB38\uC81C'), findsOneWidget);
  });

  testWidgets('settings exposes service and information entries', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    final licenses = find.text('오픈소스 라이선스');
    await tester.scrollUntilVisible(
      licenses,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('서비스'), findsOneWidget);
    expect(find.text('공지사항'), findsOneWidget);
    expect(find.text('문의하기'), findsOneWidget);
    expect(find.text('약관 및 정보'), findsOneWidget);
    expect(find.text('이용약관'), findsOneWidget);
    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(licenses, findsOneWidget);
    expect(find.text('버전 정보'), findsNothing);
    expect(find.text('Mameroom v1.0.0 (1)'), findsOneWidget);
  });
  testWidgets('low question warning is displayed', (tester) async {
    await _pumpAt(
      tester,
      const Size(390, 844),
      child: const MyInfoPage(initialRemainingQuestions: 0),
    );
    expect(find.text('0\uBB38\uC81C'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('settings rows remain available', (tester) async {
    await _pumpAt(tester, const Size(390, 844));
    final settings = find.text('\uC124\uC815');
    await tester.scrollUntilVisible(
      settings,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('\uC54C\uB9BC'), findsWidgets);
    expect(find.text('\uC0AC\uC6B4\uB4DC'), findsOneWidget);
    expect(find.text('\uB85C\uADF8\uC544\uC6C3'), findsOneWidget);
  });

  testWidgets('terms row opens terms page', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const MyInfoPage()),
        GoRoute(
          path: TermsOfServicePage.routePath,
          builder: (_, _) => const TermsOfServicePage(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    final terms = find.text('\uC774\uC6A9\uC57D\uAD00');
    await tester.scrollUntilVisible(
      terms,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(terms);
    await tester.pumpAndSettle();
    await tester.tap(terms);
    await tester.pumpAndSettle();
    expect(find.byType(TermsOfServicePage), findsOneWidget);
  });

  testWidgets('logout dialog opens', (tester) async {
    await _pumpAt(tester, const Size(390, 844));
    final logout = find.text('\uB85C\uADF8\uC544\uC6C3');
    await tester.scrollUntilVisible(
      logout,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('\uB85C\uADF8\uC544\uC6C3'), findsWidgets);
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('my page has no overflow at $size', (tester) async {
      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('footer menu expands without overflow at 1.3 text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _wrap(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MyInfoPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final footer = find.text('Mameroom v1.0.0 (1)');
    await tester.scrollUntilVisible(
      footer,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(footer, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('bottom navigation keeps my tab label', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeShellPage(selectedIndex: 3, child: MyInfoPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('\uB0B4 \uC815\uBCF4'), findsWidgets);
  });

  testWidgets('achievement entry opens the achievement route', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const MyInfoPage()),
        GoRoute(
          path: AchievementPage.routePath,
          builder: (_, _) => const AchievementPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const ValueKey('my-achievement-entry'));
    await tester.scrollUntilVisible(
      entry,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    tester.widget<InkWell>(entry).onTap!();
    await tester.pumpAndSettle();

    expect(find.byType(AchievementPage), findsOneWidget);
  });
}
