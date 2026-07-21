import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_memory_coach/core/presentation/modals/mameroom_modals.dart';
import 'package:ai_memory_coach/shared/design_system/theme/mameroom_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captures all modal variants when requested', (tester) async {
    const path = String.fromEnvironment('MODAL_SCREENSHOT_PATH');
    if (path.isEmpty) {
      return;
    }

    tester.view.physicalSize = const Size(1800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(_Gallery(captureKey: key));
    await tester.pumpAndSettle();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await tester.runAsync(() async {
      final target = File(path);
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.captureKey});

  final GlobalKey captureKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        extensions: const [MameroomTheme.light],
      ),
      home: Scaffold(
        backgroundColor: MameroomTheme.light.cloud,
        body: RepaintBoundary(
          key: captureKey,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              children: const [
                _Shot(
                  title: '\uC54C\uB9BC',
                  message:
                      '\uC791\uC5C5\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.',
                  variant: MameroomModalVariant.info,
                ),
                _Shot(
                  title: '\uC644\uB8CC!',
                  message:
                      '\uBB38\uC81C \uC0DD\uC131\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.',
                  variant: MameroomModalVariant.success,
                ),
                _Shot(
                  title: '\uC8FC\uC758',
                  message:
                      '\uC815\uB9D0\uB85C \uC774 \uC791\uC5C5\uC744 \uC9C4\uD589\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
                  variant: MameroomModalVariant.warning,
                  secondary: '\uCDE8\uC18C',
                ),
                _Shot(
                  title: '\uC624\uB958',
                  message:
                      '\uB124\uD2B8\uC6CC\uD06C \uC5F0\uACB0\uC744 \uD655\uC778\uD558\uACE0 \uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.',
                  variant: MameroomModalVariant.error,
                ),
                _Shot(
                  title: '\uD655\uC778',
                  message:
                      '\uC815\uB9D0\uB85C \uC0AD\uC81C\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?\n\uC774 \uC791\uC5C5\uC740 \uB418\uB3CC\uB9B4 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.',
                  variant: MameroomModalVariant.confirm,
                  secondary: '\uCDE8\uC18C',
                  destructive: '\uC0AD\uC81C',
                  primary: null,
                ),
                _Shot(
                  title: 'Lv.20 \uB2EC\uC131!',
                  message:
                      '\uBCF4\uC0C1\uC774 \uC9C0\uAE09\uB418\uC5C8\uC2B5\uB2C8\uB2E4.',
                  variant: MameroomModalVariant.levelUp,
                ),
                _Shot(
                  title: '\uBCF4\uC0C1 \uD68D\uB4DD!',
                  message:
                      '\uB2E4\uC74C \uBCF4\uC0C1\uC744 \uD68D\uB4DD\uD588\uC2B5\uB2C8\uB2E4.',
                  variant: MameroomModalVariant.reward,
                ),
                _Shot(
                  title:
                      '\uAE30\uC5B5\uC528\uC557\uC774 \uC131\uC7A5\uD588\uC5B4\uC694!',
                  message:
                      '\uC0C8\uB85C\uC6B4 \uBAA8\uC2B5\uC73C\uB85C \uC790\uB790\uC2B5\uB2C8\uB2E4.',
                  variant: MameroomModalVariant.seedGrowth,
                ),
                _Shot(
                  title: '\uAD6C\uB9E4 \uC644\uB8CC!',
                  message:
                      '\uC544\uC774\uD15C\uC774 \uB0B4 \uBC29\uC73C\uB85C \uC9C0\uAE09\uB418\uC5C8\uC2B5\uB2C8\uB2E4.',
                  variant: MameroomModalVariant.purchase,
                ),
                _Shot(
                  title: '\uAE30\uBCF8 \uC758\uC790',
                  message:
                      '\uD574\uB2F9 \uC544\uC774\uD15C\uC744\n\uAD6C\uB9E4\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
                  variant: MameroomModalVariant.purchase,
                  secondary: '\uCDE8\uC18C',
                  primary: '\uAD6C\uB9E4\uD558\uAE30',
                ),
                _Shot(
                  title: '\uB85C\uADF8\uC544\uC6C3',
                  message:
                      '\uC815\uB9D0\uB85C \uB85C\uADF8\uC544\uC6C3 \uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
                  variant: MameroomModalVariant.confirm,
                  secondary: '\uCDE8\uC18C',
                  destructive: '\uB85C\uADF8\uC544\uC6C3',
                  primary: null,
                ),
                _Shot(
                  title: '\uC5C5\uB85C\uB4DC \uC644\uB8CC',
                  message:
                      '\uC790\uB8CC \uC5C5\uB85C\uB4DC\uAC00 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.',
                  variant: MameroomModalVariant.success,
                ),
                _Shot(
                  title: '\uBB38\uC81C \uC0DD\uC131 \uC911',
                  message:
                      'AI\uAC00 \uBB38\uC81C\uB97C \uC0DD\uC131\uD558\uACE0 \uC788\uC5B4\uC694.',
                  variant: MameroomModalVariant.loading,
                  customContent: MameroomModalProgress(
                    value: 0.75,
                    label: '75%',
                  ),
                  primary: '\uCDE8\uC18C',
                ),
                _Shot(
                  title: '\uC544\uC9C1 \uC790\uB8CC\uAC00 \uC5C6\uC5B4\uC694',
                  message:
                      '\uC0C8 \uC790\uB8CC\uB97C \uC5C5\uB85C\uB4DC\uD558\uC5EC\n\uD559\uC2B5\uC744 \uC2DC\uC791\uD574\uBCF4\uC138\uC694.',
                  variant: MameroomModalVariant.empty,
                  primary: '\uC790\uB8CC \uC5C5\uB85C\uB4DC',
                ),
                _Shot(
                  title: '\uC5F0\uACB0\uC774 \uBD88\uC548\uC815\uD574\uC694',
                  message:
                      '\uC778\uD130\uB137 \uC5F0\uACB0\uC744 \uD655\uC778\uD558\uACE0\n\uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.',
                  variant: MameroomModalVariant.networkError,
                  primary: '\uB2E4\uC2DC \uC2DC\uB3C4',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Shot extends StatelessWidget {
  const _Shot({
    required this.title,
    required this.message,
    required this.variant,
    this.primary = '\uD655\uC778',
    this.secondary,
    this.destructive,
    this.customContent,
  });

  final String title;
  final String message;
  final MameroomModalVariant variant;
  final String? primary;
  final String? secondary;
  final String? destructive;
  final Widget? customContent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 330,
      child: MameroomModal(
        title: title,
        message: message,
        variant: variant,
        customContent: customContent,
        primaryButtonText: primary,
        secondaryButtonText: secondary,
        destructiveButtonText: destructive,
        onPrimary: () {},
        onSecondary: () {},
        onDestructive: () {},
      ),
    );
  }
}
