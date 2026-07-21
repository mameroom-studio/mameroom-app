import 'package:ai_memory_coach/core/presentation/states/mameroom_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {Size size = const Size(390, 844)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: SafeArea(child: child)),
    ),
  );
}

void main() {
  testWidgets('renders no study materials empty state and primary action', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _app(MameroomEmptyState.studyMaterials(onUpload: () => tapped = true)),
    );

    expect(
      find.text(
        '\uC544\uC9C1 \uD559\uC2B5 \uC790\uB8CC\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('\uC790\uB8CC \uC5C5\uB85C\uB4DC\uD558\uAE30'));
    expect(tapped, isTrue);
  });

  testWidgets('renders each empty preset', (tester) async {
    await tester.pumpWidget(_app(MameroomEmptyState.friends()));
    expect(find.textContaining('\uCE5C\uAD6C'), findsWidgets);

    await tester.pumpWidget(_app(MameroomEmptyState.room()));
    expect(find.text('\uBE48 \uBC29'), findsOneWidget);

    await tester.pumpWidget(_app(MameroomEmptyState.seeds()));
    expect(find.textContaining('\uAE30\uC5B5\uC528\uC557'), findsWidgets);

    await tester.pumpWidget(_app(MameroomEmptyState.notifications()));
    expect(find.textContaining('\uC54C\uB9BC'), findsWidgets);
  });

  testWidgets('renders loading skeleton and processing progress', (
    tester,
  ) async {
    await tester.pumpWidget(_app(MameroomLoadingState.studyMaterials()));
    expect(find.text('\uD559\uC2B5 \uC790\uB8CC \uB85C\uB529'), findsOneWidget);

    await tester.pumpWidget(
      _app(MameroomProcessingState.pdfUploading(progress: 0.45)),
    );
    expect(find.text('45%'), findsOneWidget);

    await tester.pumpWidget(
      _app(MameroomProcessingState.pdfAnalyzing(progress: 0.72)),
    );
    expect(find.text('72%'), findsOneWidget);

    await tester.pumpWidget(
      _app(MameroomProcessingState.quizGenerating(progress: 0.60)),
    );
    expect(find.text('60%'), findsOneWidget);
  });

  testWidgets('renders error state retry action', (tester) async {
    var retry = 0;
    await tester.pumpWidget(
      _app(MameroomErrorState.network(onRetry: () => retry++)),
    );

    expect(
      find.text('\uC5F0\uACB0\uC774 \uBD88\uC548\uC815\uD574\uC694'),
      findsOneWidget,
    );
    await tester.tap(find.text('\uB2E4\uC2DC \uC2DC\uB3C4'));
    expect(retry, 1);
  });

  testWidgets('renders success, offline, permission, and search states', (
    tester,
  ) async {
    await tester.pumpWidget(_app(MameroomSuccessState.uploadComplete()));
    expect(
      find.text('\uC790\uB8CC \uC5C5\uB85C\uB4DC \uC644\uB8CC!'),
      findsOneWidget,
    );

    await tester.pumpWidget(_app(const MameroomOfflineState()));
    expect(
      find.text(
        '\uC778\uD130\uB137 \uC5F0\uACB0\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(_app(MameroomPermissionState.camera()));
    expect(find.text('\uCE74\uBA54\uB77C \uAD8C\uD55C'), findsOneWidget);

    await tester.pumpWidget(
      _app(const MameroomSearchEmptyState(keyword: '\uBCF4\uD5D8')),
    );
    expect(find.text('\uD68C\uACC4'), findsOneWidget);
  });

  testWidgets('renders state banner and retry button', (tester) async {
    var retry = false;
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            const MameroomStateBanner(
              variant: MameroomStateBannerVariant.error,
              message:
                  '\uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4.',
            ),
            MameroomRetryButton(onPressed: () => retry = true),
          ],
        ),
      ),
    );

    expect(
      find.text('\uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4.'),
      findsOneWidget,
    );
    await tester.tap(find.text('\uB2E4\uC2DC \uC2DC\uB3C4'));
    expect(retry, isTrue);
  });

  testWidgets('fits compact state at 360x800 without overflow', (tester) async {
    await tester.pumpWidget(
      _app(
        MameroomStateView(
          variant: MameroomStateVariant.empty,
          title: '\uC791\uC740 \uD654\uBA74 \uD14C\uC2A4\uD2B8',
          description:
              '\uD14D\uC2A4\uD2B8\uAC00 \uB108\uBB34 \uAE38\uC5B4\uB3C4 \uC548\uC815\uC801\uC73C\uB85C \uC904\uBC14\uAFC8\uB418\uC5B4\uC57C \uD569\uB2C8\uB2E4.',
          primaryButtonText: '\uD655\uC778',
          size: MameroomStateSize.compact,
        ),
        size: const Size(360, 800),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
