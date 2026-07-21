const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'test/features/library/library_page_test.dart');
const content = String.raw`import 'package:ai_memory_coach/features/library/domain/entities/study_material.dart';
import 'package:ai_memory_coach/features/library/presentation/pages/library_page.dart';
import 'package:ai_memory_coach/features/library/presentation/providers/library_mock_providers.dart';
import 'package:ai_memory_coach/features/upload/presentation/pages/upload_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Study dashboard keeps one upload entry and opens method sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: LibraryPage.routePath,
      routes: [
        GoRoute(
          path: LibraryPage.routePath,
          builder: (context, state) => const Scaffold(body: LibraryPage()),
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
            return const LibraryDashboard(
              todayReviewCount: 17,
              totalMemoryPercent: 84,
              recentRecords: [],
              materials: [
                StudyMaterial(
                  id: 'material-1',
                  title:
                      '\u{C0DD}\u{BA85}\u{ACFC}\u{D559} \u{C815}\u{B9AC}.pdf',
                  sectionCount: 0,
                  progressPercent: 75,
                  memoryPercent: 84,
                  nextReviewLabel: 'Ready',
                  totalQuestionCount: 120,
                  completedQuestionCount: 90,
                  dueReviewCount: 17,
                  recentStudyLabel: '2\u{C2DC}\u{AC04} \u{C804}',
                  status: 'completed',
                ),
              ],
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

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

    expect(
      find.text('\u{C5C5}\u{B85C}\u{B4DC} \u{BC29}\u{C2DD} \u{C120}\u{D0DD}'),
      findsOneWidget,
    );
    expect(find.text('PDF \u{C5C5}\u{B85C}\u{B4DC}'), findsOneWidget);
    expect(find.text('Word \u{C5C5}\u{B85C}\u{B4DC}'), findsOneWidget);
    expect(
      find.text('PowerPoint \u{C5C5}\u{B85C}\u{B4DC}'),
      findsOneWidget,
    );
    expect(
      find.text('\u{C774}\u{BBF8}\u{C9C0} \u{C5C5}\u{B85C}\u{B4DC}'),
      findsOneWidget,
    );
    expect(
      find.text('\u{C0AC}\u{C9C4} \u{CD2C}\u{C601}'),
      findsOneWidget,
    );
    expect(
      find.text('\u{D14D}\u{C2A4}\u{D2B8} \u{BD99}\u{C5EC}\u{B123}\u{AE30}'),
      findsOneWidget,
    );

    await tester.tap(find.text('PDF \u{C5C5}\u{B85C}\u{B4DC}'));
    await tester.pumpAndSettle();

    expect(find.text('upload-page-placeholder'), findsOneWidget);
  });
}
`;
fs.writeFileSync(file, content);
