import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_memory_coach/core/presentation/states/mameroom_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captures Mameroom state gallery when requested', (tester) async {
    final outputPath = const String.fromEnvironment('STATE_SCREENSHOT_PATH');
    final boundaryKey = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(1600, 2400));
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(key: boundaryKey, child: const _StateGallery()),
      ),
    );
    await tester.pumpAndSettle();

    if (outputPath.isNotEmpty) {
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(outputPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    expect(find.text('No Study Materials'), findsOneWidget);
    expect(find.text('Search Empty'), findsOneWidget);
  });
}

class _StateGallery extends StatelessWidget {
  const _StateGallery();

  @override
  Widget build(BuildContext context) {
    final cards = <(String, Widget)>[
      (
        'No Study Materials',
        MameroomEmptyState.studyMaterials(size: MameroomStateSize.compact),
      ),
      (
        'No Friends',
        MameroomEmptyState.friends(size: MameroomStateSize.compact),
      ),
      ('Empty Room', MameroomEmptyState.room(size: MameroomStateSize.compact)),
      ('No Seeds', MameroomEmptyState.seeds(size: MameroomStateSize.compact)),
      (
        'No Notifications',
        MameroomEmptyState.notifications(size: MameroomStateSize.compact),
      ),
      ('Loading Skeleton', MameroomLoadingState.studyMaterials()),
      ('PDF Uploading', MameroomProcessingState.pdfUploading()),
      ('PDF Analyzing', MameroomProcessingState.pdfAnalyzing()),
      ('Quiz Generating', MameroomProcessingState.quizGenerating()),
      ('Network Error', MameroomErrorState.network()),
      ('Analysis Failed', MameroomErrorState.analysisFailed()),
      ('Upload Failed', MameroomErrorState.uploadFailed()),
      ('Server Maintenance', MameroomErrorState.maintenance()),
      ('Upload Complete', MameroomSuccessState.uploadComplete()),
      ('Offline', const MameroomOfflineState()),
      ('Permission', MameroomPermissionState.camera()),
      ('Search Empty', const MameroomSearchEmptyState(keyword: '\uBCF4\uD5D8')),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFFBFAFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: GridView.builder(
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 430,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final item = cards[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: Color(0xFF2A2554),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: item.$2),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
