import 'package:ai_memory_coach/features/settings/presentation/open_source_license_page.dart';
import 'package:ai_memory_coach/features/settings/presentation/version_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('shows runtime package version and build', (tester) async {
    final info = PackageInfo(
      appName: 'Mameroom',
      packageName: 'com.example.mameroom',
      version: '1.2.3',
      buildNumber: '42',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [packageInfoProvider.overrideWith((_) async => info)],
        child: const MaterialApp(home: VersionInfoPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('버전 1.2.3'), findsOneWidget);
    expect(find.text('빌드 42'), findsOneWidget);
  });

  testWidgets('opens Flutter LicensePage', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OpenSourceLicensePage()));
    await tester.tap(find.byKey(const ValueKey('show-licenses')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
