import 'dart:async';

import 'package:ai_memory_coach/features/home/presentation/pages/learning_report_page.dart';
import 'package:ai_memory_coach/features/library/domain/entities/study_material.dart';
import 'package:ai_memory_coach/features/library/presentation/providers/library_mock_providers.dart';
import 'package:ai_memory_coach/features/streak/domain/entities/streak_state.dart';
import 'package:ai_memory_coach/features/streak/presentation/providers/streak_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _material = StudyMaterial(
  id: 'm1',
  title: '\uBCF4\uD5D8\uACC4\uB9AC \uAC1C\uB150 \uD14C\uC2A4\uD2B8.pdf',
  sectionCount: 0,
  progressPercent: 70,
  memoryPercent: 72,
  nextReviewLabel: 'Ready',
  totalQuestionCount: 120,
  completedQuestionCount: 86,
  dueReviewCount: 17,
  status: 'completed',
);

Widget _reportApp({
  LibraryDashboard? dashboard,
  bool loading = false,
  bool error = false,
}) {
  return ProviderScope(
    overrides: [
      libraryDashboardProvider.overrideWith((ref) async {
        if (loading) {
          return await Completer<LibraryDashboard>().future;
        }
        if (error) {
          throw StateError('report failed');
        }
        return dashboard ??
            const LibraryDashboard(
              todayReviewCount: 17,
              totalMemoryPercent: 84,
              materials: [_material],
              recentRecords: [
                RecentStudyRecord(
                  title:
                      '\uBCF4\uD5D8\uACC4\uB9AC \uAC1C\uB150 \uD14C\uC2A4\uD2B8.pdf',
                  subtitle: '\uCD5C\uADFC \uD559\uC2B5 \uC5B4\uC81C',
                  scoreLabel: '84%',
                ),
              ],
            );
      }),
      streakProvider.overrideWith((ref) async {
        return const StreakState(
          currentStreak: 7,
          maxStreak: 11,
          milestoneReward: 0,
          walletBalance: 0,
        );
      }),
    ],
    child: const MaterialApp(home: LearningReportPage()),
  );
}

void main() {
  testWidgets(
    'learning report renders mock dashboard values without raw interpolation',
    (tester) async {
      await tester.pumpWidget(_reportApp());
      await tester.pumpAndSettle();

      expect(find.text('\uB0B4 \uD559\uC2B5'), findsOneWidget);
      expect(find.text('\uC624\uB298 \uC694\uC57D'), findsOneWidget);
      expect(find.text('238\uBD84'), findsOneWidget);
      expect(find.text('312\uBB38\uC81C'), findsOneWidget);
      expect(find.text('96\uBB38\uC81C'), findsOneWidget);
      expect(find.text('84%'), findsWidgets);
      expect(find.text('+40'), findsOneWidget);
      expect(find.textContaining(r'${'), findsNothing);
    },
  );

  testWidgets('learning report changes period with animated content', (
    tester,
  ) async {
    await tester.pumpWidget(_reportApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('\uC624\uB298'));
    await tester.pumpAndSettle();
    expect(find.text('42\uBD84'), findsOneWidget);
    expect(find.text('68\uBB38\uC81C'), findsOneWidget);

    await tester.tap(find.text('\uC6D4\uAC04'));
    await tester.pumpAndSettle();
    expect(find.text('940\uBD84'), findsOneWidget);

    await tester.tap(find.text('\uC804\uCCB4'));
    await tester.pumpAndSettle();
    expect(find.text('3260\uBD84'), findsOneWidget);
  });

  testWidgets('learning report shows empty state with no data', (tester) async {
    await tester.pumpWidget(
      _reportApp(
        dashboard: const LibraryDashboard(
          todayReviewCount: 0,
          totalMemoryPercent: 0,
          materials: [],
          recentRecords: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        '\uCCAB \uD559\uC2B5\uC744 \uC2DC\uC791\uD558\uBA74 \uD1B5\uACC4\uAC00 \uC0DD\uC131\uB429\uB2C8\uB2E4.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(r'${'), findsNothing);
  });

  testWidgets('learning report shows loading and error states', (tester) async {
    await tester.pumpWidget(_reportApp(loading: true));
    await tester.pump();
    expect(
      find.text('\uD559\uC2B5 \uB9AC\uD3EC\uD2B8 \uB85C\uB529'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(_reportApp(error: true));
    await tester.pumpAndSettle();
    expect(
      find.text('\uC5F0\uACB0\uC774 \uBD88\uC548\uC815\uD574\uC694'),
      findsOneWidget,
    );
  });

  for (final size in <Size>[Size(360, 800), Size(390, 844), Size(412, 915)]) {
    testWidgets(
      'learning report has no overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_reportApp());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ListView), findsOneWidget);
        expect(find.textContaining(r'${'), findsNothing);
      },
    );
  }
}
