import 'package:ai_memory_coach/features/study/presentation/widgets/study_flow_components.dart';
import 'package:ai_memory_coach/shared/design_system/theme/mameroom_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(390, 844)}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: MameroomTheme.light.primary),
      extensions: const [MameroomTheme.light],
    ),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: SafeArea(child: child)),
    ),
  );
}

void main() {
  testWidgets('question screen renders with M-Coin only and selects answer', (
    tester,
  ) async {
    var selected = '';
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                QuizProgressHeader(
                  current: 3,
                  total: 10,
                  coinBalance: 250,
                  onExit: () {},
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        QuestionCard(
                          questionText:
                              '\uB300\uD55C\uBBFC\uAD6D\uC758 \uCCAB \uBC88\uC9F8 \uB300\uD1B5\uB839\uC740 \uB204\uAD6C\uC77C\uAE4C\uC694?',
                          categoryLabel: '\uC5ED\uC0AC',
                          difficultyLabel: '\uBCF4\uD1B5',
                          questionTypeLabel: '\uAC1D\uAD00\uC2DD',
                          sourceLabel:
                              '\uBCF4\uD5D8\uACC4\uB9AC \uAC1C\uB150 \uD14C\uC2A4\uD2B8_12.pdf',
                          child: const PixelQuizIllustration(compact: true),
                        ),
                        AnswerOptionCard(
                          index: 1,
                          label: '\uC774\uC2B9\uB9CC',
                          selected: selected == '\uC774\uC2B9\uB9CC',
                          enabled: true,
                          onTap: () =>
                              setState(() => selected = '\uC774\uC2B9\uB9CC'),
                        ),
                      ],
                    ),
                  ),
                ),
                BottomQuizActionBar(
                  canSubmit: selected.isNotEmpty,
                  isSaving: false,
                  bookmarked: false,
                  canUseHint: true,
                  onHint: () {},
                  onPass: () {},
                  onBookmark: () {},
                  onSubmit: () {},
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text('3 / 10'), findsOneWidget);
    expect(
      find.text(
        '\uB300\uD55C\uBBFC\uAD6D\uC758 \uCCAB \uBC88\uC9F8 \uB300\uD1B5\uB839\uC740 \uB204\uAD6C\uC77C\uAE4C\uC694?',
      ),
      findsOneWidget,
    );
    expect(find.text('PASS'), findsOneWidget);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);

    await tester.tap(find.text('\uC774\uC2B9\uB9CC'));
    await tester.pump();
    expect(selected, '\uC774\uC2B9\uB9CC');
  });

  testWidgets('submit is disabled until answer exists', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BottomQuizActionBar(
          canSubmit: false,
          isSaving: false,
          bookmarked: false,
          onHint: () {},
          onPass: () {},
          onBookmark: () {},
          onSubmit: () {},
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '\uC81C\uCD9C\uD558\uAE30'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('bookmark uses snackbar instead of modal', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(BookmarkSavedSnack()),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    expect(
      find.text(
        '\uBD81\uB9C8\uD06C\uC5D0 \uC800\uC7A5\uD588\uC5B4\uC694. \uB098\uC911\uC5D0 \uB2E4\uC2DC \uD655\uC778\uD560 \uC218 \uC788\uC5B4\uC694.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('feedback, memory growth, combo, and result states render', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 520,
                child: FeedbackResultCard(
                  kind: FeedbackKind.correct,
                  answer: '\uC774\uC2B9\uB9CC',
                  message:
                      '\uAE30\uC5B5\uC528\uC557\uC774 \uC131\uC7A5\uD558\uACE0 \uC788\uC5B4\uC694.',
                  rewardText: '+10 M-Coin',
                  onNext: () {},
                ),
              ),
              SizedBox(
                height: 420,
                child: MemoryGrowthPanel(
                  beforeLevel: 2,
                  afterLevel: 3,
                  progress: 0.65,
                  onConfirm: () {},
                ),
              ),
              const ComboRewardCard(combo: 5, coin: 100),
              QuizResultSummaryCard(
                correct: 7,
                incorrect: 2,
                passed: 1,
                accuracy: 77,
                coin: 50,
                memoryBefore: 76,
                memoryAfter: 80,
                seedGrowth: 12,
                onHome: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('\uC815\uB2F5!'), findsOneWidget);
    expect(find.text('\uAE30\uC5B5\uC528\uC557 \uC131\uC7A5!'), findsOneWidget);
    expect(find.text('COMBO 5!'), findsOneWidget);
    expect(find.text('\uD034\uC988 \uC644\uB8CC!'), findsOneWidget);
    expect(find.text('\uD648\uC73C\uB85C \uAC00\uAE30'), findsOneWidget);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
  });

  testWidgets('quiz layout stays stable on target mobile sizes', (
    tester,
  ) async {
    for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              QuizProgressHeader(
                current: 1,
                total: 10,
                coinBalance: 250,
                onExit: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      QuestionCard(
                        questionText:
                            '\uBCF4\uD5D8\uACC4\uB9AC\uC5D0\uC11C \uC704\uD5D8\uB960\uC774 \uC758\uBBF8\uD558\uB294 \uAC83\uC740?',
                        categoryLabel: '\uBCF4\uD5D8',
                        difficultyLabel: '\uBCF4\uD1B5',
                        questionTypeLabel: '\uAC1D\uAD00\uC2DD',
                        child: const SizedBox.shrink(),
                      ),
                      for (final option in const ['A', 'B', 'C', 'D'])
                        AnswerOptionCard(
                          index: option.codeUnitAt(0) - 64,
                          label: option,
                          selected: false,
                          enabled: true,
                          onTap: () {},
                        ),
                    ],
                  ),
                ),
              ),
              BottomQuizActionBar(
                canSubmit: false,
                isSaving: false,
                bookmarked: false,
                onHint: () {},
                onPass: () {},
                onBookmark: () {},
                onSubmit: () {},
              ),
            ],
          ),
          size: size,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}
