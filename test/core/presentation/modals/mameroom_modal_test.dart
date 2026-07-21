import 'package:ai_memory_coach/core/presentation/modals/mameroom_modals.dart';
import 'package:ai_memory_coach/shared/design_system/theme/mameroom_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('info modal renders Korean copy and primary callback', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _Host(
        child: MameroomModal(
          title: _info,
          message: _infoMessage,
          variant: MameroomModalVariant.info,
          primaryButtonText: _ok,
          onPrimary: () => tapped = true,
        ),
      ),
    );

    expect(find.text(_info), findsOneWidget);
    expect(find.text(_infoMessage), findsOneWidget);
    await tester.tap(find.text(_ok));
    expect(tapped, isTrue);
  });

  testWidgets('success, warning, error, and confirm variants render', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Host(
        child: Column(
          children: [
            MameroomModalIcon(variant: MameroomModalVariant.success),
            MameroomModalIcon(variant: MameroomModalVariant.warning),
            MameroomModalIcon(variant: MameroomModalVariant.error),
            MameroomModalIcon(variant: MameroomModalVariant.confirm),
          ],
        ),
      ),
    );

    expect(find.byType(MameroomModalIcon), findsNWidgets(4));
  });

  testWidgets('secondary and destructive callbacks work', (tester) async {
    var cancelled = false;
    var deleted = false;
    await tester.pumpWidget(
      _Host(
        child: MameroomModal(
          title: _confirm,
          message: _deleteMessage,
          variant: MameroomModalVariant.confirm,
          secondaryButtonText: _cancel,
          destructiveButtonText: _delete,
          onSecondary: () => cancelled = true,
          onDestructive: () => deleted = true,
        ),
      ),
    );

    await tester.tap(find.text(_cancel));
    expect(cancelled, isTrue);
    await tester.tap(find.text(_delete));
    expect(deleted, isTrue);
  });

  testWidgets('service shows logout confirm and returns true', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _Host(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await MameroomPopupService.showLogoutConfirm(context);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(_logout), findsNWidgets(2));
    expect(find.text(_logoutMessage), findsOneWidget);
    await tester.tap(find.text(_logout).last);
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('purchase confirm and purchase complete render required copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(
        child: Builder(
          builder: (context) => Column(
            children: [
              FilledButton(
                onPressed: () => MameroomPopupService.showPurchaseConfirm(
                  context,
                  itemName: _chair,
                  itemDescription: _chairDescription,
                  price: 100,
                  balance: 320,
                ),
                child: const Text('confirm'),
              ),
              FilledButton(
                onPressed: () => MameroomPopupService.showPurchaseComplete(
                  context,
                  itemName: _chair,
                ),
                child: const Text('complete'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();
    expect(find.text(_chair), findsOneWidget);
    expect(find.text(_chairDescription), findsOneWidget);
    expect(find.text(_buy), findsOneWidget);
    await tester.tap(find.text(_cancel));
    await tester.pumpAndSettle();

    await tester.tap(find.text('complete'));
    await tester.pumpAndSettle();
    expect(find.text(_purchaseComplete), findsOneWidget);
    expect(find.text(_purchaseCompleteMessage), findsOneWidget);
  });

  testWidgets('reward and generating modals render', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: Column(
          children: [
            MameroomModal(
              title: _reward,
              message: _rewardMessage,
              variant: MameroomModalVariant.reward,
              primaryButtonText: _ok,
            ),
            MameroomModalProgress(value: 0.75, label: '75%'),
          ],
        ),
      ),
    );

    expect(find.text(_reward), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('modal stays within 390x844 without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const _Host(
        child: MameroomModal(
          title: _generating,
          message: _generatingMessage,
          variant: MameroomModalVariant.loading,
          customContent: MameroomModalProgress(value: 0.75, label: '75%'),
          secondaryButtonText: _cancel,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(_generating), findsOneWidget);
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        extensions: const [MameroomTheme.light],
      ),
      home: Scaffold(body: Center(child: child)),
    );
  }
}

const _info = '\uC54C\uB9BC';
const _infoMessage =
    '\uC791\uC5C5\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.';
const _ok = '\uD655\uC778';
const _confirm = '\uD655\uC778';
const _deleteMessage =
    '\uC815\uB9D0\uB85C \uC0AD\uC81C\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?';
const _cancel = '\uCDE8\uC18C';
const _delete = '\uC0AD\uC81C';
const _logout = '\uB85C\uADF8\uC544\uC6C3';
const _logoutMessage =
    '\uC815\uB9D0\uB85C \uB85C\uADF8\uC544\uC6C3 \uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?';
const _chair = '\uAE30\uBCF8 \uC758\uC790';
const _chairDescription = '\uC791\uC740 \uACF5\uBD80 \uC758\uC790';
const _buy = '\uAD6C\uB9E4\uD558\uAE30';
const _purchaseComplete = '\uAD6C\uB9E4 \uC644\uB8CC!';
const _purchaseCompleteMessage =
    '\uC544\uC774\uD15C\uC774 \uB0B4 \uBC29\uC73C\uB85C \uC9C0\uAE09\uB418\uC5C8\uC2B5\uB2C8\uB2E4.';
const _reward = '\uBCF4\uC0C1 \uD68D\uB4DD!';
const _rewardMessage =
    '\uB2E4\uC74C \uBCF4\uC0C1\uC744 \uD68D\uB4DD\uD588\uC2B5\uB2C8\uB2E4.';
const _generating = '\uBB38\uC81C \uC0DD\uC131 \uC911';
const _generatingMessage =
    'AI\uAC00 \uBB38\uC81C\uB97C \uC0DD\uC131\uD558\uACE0 \uC788\uC5B4\uC694.';
