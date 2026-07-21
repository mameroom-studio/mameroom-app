import 'package:ai_memory_coach/features/library/domain/entities/study_material.dart';
import 'package:ai_memory_coach/features/library/presentation/pages/library_page.dart';
import 'package:ai_memory_coach/features/library/presentation/providers/library_mock_providers.dart';
import 'package:ai_memory_coach/features/quiz/presentation/pages/quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Study search result opens the existing study route', (tester) async {
    final dashboard = LibraryDashboard(
      todayReviewCount: 0,
      totalMemoryPercent: 0,
      materials: [
        StudyMaterial(
          id: 'material-1',
          title: '수학 공식',
          sectionCount: 0,
          progressPercent: 0,
          memoryPercent: 0,
          nextReviewLabel: 'Ready',
          status: 'completed',
          uploadedAt: DateTime.utc(2026, 7, 1),
        ),
      ],
      recentRecords: const [],
    );
    final router = GoRouter(
      initialLocation: LibraryPage.routePath,
      routes: [
        GoRoute(
          path: LibraryPage.routePath,
          builder: (_, _) => const LibraryPage(),
        ),
        GoRoute(
          path: QuizPage.routePath,
          builder: (_, state) => Text(
            'study:${state.uri.queryParameters['materialId']}',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryDashboardProvider.overrideWith((_) async => dashboard),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('검색'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('material-search-field')),
      '수학',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('material-card-material-1')));
    await tester.pumpAndSettle();

    expect(find.text('study:material-1'), findsOneWidget);
  });
}
