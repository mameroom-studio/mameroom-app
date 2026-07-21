import 'dart:async';

import 'package:ai_memory_coach/features/home/presentation/pages/home_shell_page.dart';
import 'package:ai_memory_coach/features/library/domain/entities/study_material.dart';
import 'package:ai_memory_coach/features/library/presentation/pages/library_page.dart';
import 'package:ai_memory_coach/features/library/presentation/providers/library_mock_providers.dart';
import 'package:ai_memory_coach/features/notifications/presentation/widgets/mameroom_notification_badge.dart';
import 'package:ai_memory_coach/features/upload/presentation/pages/upload_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> _pumpLibrary(
  WidgetTester tester, {
  required List<StudyMaterial> materials,
  Future<void> Function(StudyMaterial material)? onDelete,
  Size size = const Size(390, 844),
  bool withShell = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: withShell
        ? HomeShellPage.studyRoutePath
        : LibraryPage.routePath,
    routes: [
      GoRoute(
        path: withShell ? HomeShellPage.studyRoutePath : LibraryPage.routePath,
        builder: (context, state) => withShell
            ? const HomeShellPage(selectedIndex: 1, child: LibraryPage())
            : const Scaffold(body: LibraryPage()),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const Scaffold(body: Text('notification-page')),
      ),
      GoRoute(
        path: '/achievements',
        builder: (_, _) => const Scaffold(body: Text('achievement-page')),
      ),
      GoRoute(
        path: UploadPage.routePath,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('upload-page-placeholder')),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        libraryDashboardProvider.overrideWith((ref) async {
          return LibraryDashboard(
            todayReviewCount: materials.isEmpty ? 0 : 17,
            totalMemoryPercent: materials.isEmpty ? 0 : 84,
            recentRecords: const [],
            materials: materials,
          );
        }),
        deleteStudyMaterialProvider.overrideWithValue(
          onDelete ?? (material) async {},
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  await tester.pumpAndSettle();
  return router;
}

StudyMaterial _material({
  String id = 'material-1',
  String title = '\u{C0DD}\u{BA85}\u{ACFC}\u{D559} \u{C815}\u{B9AC}.pdf',
  String status = 'completed',
}) {
  return StudyMaterial(
    id: id,
    title: title,
    sectionCount: 0,
    progressPercent: status == 'completed' ? 75 : 35,
    memoryPercent: 84,
    nextReviewLabel: 'Ready',
    totalQuestionCount: 120,
    completedQuestionCount: 90,
    dueReviewCount: 17,
    recentStudyLabel: '2\u{C2DC}\u{AC04} \u{C804}',
    status: status,
  );
}

void main() {
  testWidgets('Study dashboard keeps one upload entry and opens method sheet', (
    tester,
  ) async {
    await _pumpLibrary(tester, materials: [_material()]);

    expect(find.text('\u{ACF5}\u{BD80}'), findsOneWidget);
    expect(
      find.text('\u{C0C8} \u{C790}\u{B8CC}\n\u{C5C5}\u{B85C}\u{B4DC}'),
      findsOneWidget,
    );
    expect(
      find.text('\u{C790}\u{B8CC} \u{C5C5}\u{B85C}\u{B4DC}'),
      findsNothing,
    );
    expect(
      find.text('\u{C624}\u{B298}\u{C758} \u{D559}\u{C2B5} \u{C694}\u{C57D}'),
      findsOneWidget,
    );
    expect(
      find.text('\u{B0B4} \u{D559}\u{C2B5} \u{C790}\u{B8CC}'),
      findsOneWidget,
    );
    expect(
      find.text('\u{BB38}\u{C81C} \u{CDA9}\u{C804}\u{D558}\u{AE30}'),
      findsOneWidget,
    );

    await tester.tap(
      find.text('\u{C0C8} \u{C790}\u{B8CC}\n\u{C5C5}\u{B85C}\u{B4DC}'),
    );
    await tester.pumpAndSettle();

    expect(find.text('등록 방식을 선택해 주세요'), findsOneWidget);
    expect(find.text('직접 생성'), findsOneWidget);
    expect(find.text('텍스트 불러오기'), findsOneWidget);
    expect(find.text('PDF 불러오기'), findsOneWidget);
    expect(find.textContaining('Word'), findsNothing);
    expect(find.textContaining('PowerPoint'), findsNothing);
    expect(find.textContaining('카메라'), findsNothing);

    await tester.tap(find.text('PDF 불러오기'));
    await tester.pumpAndSettle();

    expect(find.text('upload-page-placeholder'), findsOneWidget);
  });

  testWidgets(
    'material card more menu shows delete dialog and cancel keeps item',
    (tester) async {
      final material = _material();
      await _pumpLibrary(tester, materials: [material]);

      await tester.tap(
        find.byTooltip('\u{C790}\u{B8CC} \u{B354}\u{BCF4}\u{AE30}'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u{C0AD}\u{C81C}'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '\u{D559}\u{C2B5} \u{C790}\u{B8CC}\u{B97C} \u{C0AD}\u{C81C}\u{D560}\u{AE4C}\u{C694}?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('\u{CDE8}\u{C18C}'));
      await tester.pumpAndSettle();

      expect(find.text(material.title), findsWidgets);
    },
  );

  testWidgets('delete success removes card and shows empty state for last item', (
    tester,
  ) async {
    final material = _material();
    var calls = 0;
    await _pumpLibrary(
      tester,
      materials: [material],
      onDelete: (_) async => calls++,
    );

    await tester.tap(
      find.byTooltip('\u{C790}\u{B8CC} \u{B354}\u{BCF4}\u{AE30}'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u{C0AD}\u{C81C}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u{C0AD}\u{C81C}').last);
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text(material.title), findsNothing);
    expect(
      find.text(
        '\u{CCAB} \u{C790}\u{B8CC}\u{B97C} \u{C5C5}\u{B85C}\u{B4DC}\u{D558}\u{ACE0} \u{AE30}\u{C5B5}\u{C528}\u{C557}\u{C744} \u{D0A4}\u{C6CC}\u{BCF4}\u{C138}\u{C694}.',
      ),
      findsOneWidget,
    );
    expect(find.text('학습 자료가 삭제되었습니다.'), findsOneWidget);
  });

  testWidgets('delete failure keeps card and shows friendly message', (
    tester,
  ) async {
    final material = _material();
    await _pumpLibrary(
      tester,
      materials: [material],
      onDelete: (_) async => throw Exception('rls denied'),
    );

    await tester.tap(
      find.byTooltip('\u{C790}\u{B8CC} \u{B354}\u{BCF4}\u{AE30}'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u{C0AD}\u{C81C}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u{C0AD}\u{C81C}').last);
    await tester.pumpAndSettle();

    expect(find.text(material.title), findsWidgets);
    expect(find.text('학습 자료를 삭제하지 못했습니다.'), findsOneWidget);
  });

  testWidgets('failed material can be deleted', (tester) async {
    var calls = 0;
    await _pumpLibrary(
      tester,
      materials: [_material(status: 'failed')],
      onDelete: (_) async => calls++,
    );

    await tester.tap(
      find.byTooltip('\u{C790}\u{B8CC} \u{B354}\u{BCF4}\u{AE30}'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u{C0AD}\u{C81C}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u{C0AD}\u{C81C}').last);
    await tester.pumpAndSettle();

    expect(calls, 1);
  });

  testWidgets('delete in progress prevents duplicate request', (tester) async {
    final completer = Completer<void>();
    var calls = 0;
    await _pumpLibrary(
      tester,
      materials: [_material()],
      onDelete: (_) {
        calls++;
        return completer.future;
      },
    );

    await tester.tap(
      find.byTooltip('\u{C790}\u{B8CC} \u{B354}\u{BCF4}\u{AE30}'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u{C0AD}\u{C81C}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u{C0AD}\u{C81C}').last);
    await tester.pump();

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('long material name does not overflow on target sizes', (
    tester,
  ) async {
    const longTitle =
        '\u{BCF4}\u{D5D8}\u{ACC4}\u{B9AC} \u{AC1C}\u{B150} \u{D14C}\u{C2A4}\u{D2B8}_12_\u{C544}\u{C8FC}_\u{AE34}_\u{D30C}\u{C77C}\u{BA85}_\u{C624}\u{BC84}\u{D50C}\u{B85C}\u{C6B0}_\u{AC80}\u{C99D}.pdf';
    for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
      await _pumpLibrary(
        tester,
        size: size,
        materials: [_material(title: longTitle)],
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byTooltip('\u{C790}\u{B8CC} \u{B354}\u{BCF4}\u{AE30}'),
        findsOneWidget,
      );
    }
  });
  testWidgets('Study notification opens notifications and back restores tab', (
    tester,
  ) async {
    await _pumpLibrary(tester, materials: [_material()], withShell: true);

    final badge = tester.widget<MameroomNotificationBadge>(
      find.byType(MameroomNotificationBadge),
    );
    expect(badge.count, greaterThan(0));
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();

    expect(find.text('notification-page'), findsOneWidget);
    expect(find.text('achievement-page'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('notification-page'), findsNothing);
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
}
