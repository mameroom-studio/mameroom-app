import 'package:ai_memory_coach/app/theme.dart';
import 'package:ai_memory_coach/shared/design_system/mameroom_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _k(List<int> codes) => String.fromCharCodes(codes);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  test('design tokens expose board palette and grid', () {
    expect(MameroomColors.primary, const Color(0xFF7861FF));
    expect(MameroomColors.success, const Color(0xFF7ED957));
    expect(MameroomSpacing.md, 16);
    expect(MameroomRadius.card, 20);
    expect(MameroomTypography.button.fontSize, 16);
  });

  testWidgets('buttons render default disabled loading and Korean text', (
    tester,
  ) async {
    var tapped = 0;
    final korean = _k([54869, 51064]);
    await _pump(
      tester,
      Column(
        children: [
          MameroomPrimaryButton(label: korean, onPressed: () => tapped++),
          const SizedBox(height: 8),
          const MameroomSecondaryButton(label: 'Secondary', onPressed: null),
          const SizedBox(height: 8),
          MameroomPrimaryButton(
            label: 'Loading',
            isLoading: true,
            onPressed: () {},
          ),
        ],
      ),
    );
    expect(find.text(korean), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text(korean));
    expect(tapped, 1);
  });

  testWidgets(
    'inputs cards badges chips and progress render without overflow',
    (tester) async {
      final controller = TextEditingController(text: _k([47560, 47700, 47352]));
      final searchController = TextEditingController();
      addTearDown(controller.dispose);
      addTearDown(searchController.dispose);
      await _pump(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(MameroomSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MameroomTextField(
                controller: controller,
                label: 'Label',
                hintText: 'Hint',
                prefixIcon: Icons.search_rounded,
              ),
              const SizedBox(height: 12),
              MameroomSearchField(
                controller: searchController,
                hintText: 'Search',
              ),
              const SizedBox(height: 12),
              const MameroomCard(child: Text('Card')),
              const SizedBox(height: 12),
              const MameroomElevatedCard(child: Text('Elevated')),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                children: [
                  MameroomStatusBadge(
                    label: 'ACTIVE',
                    variant: MameroomBadgeVariant.active,
                  ),
                  MameroomLevelBadge(level: 20),
                ],
              ),
              const SizedBox(height: 12),
              MameroomCategoryChip(
                label: 'Chip',
                selected: true,
                onSelected: (_) {},
              ),
              const SizedBox(height: 12),
              const MameroomProgressBar(value: 0.72, label: 'Progress'),
              const SizedBox(height: 12),
              const MameroomSeedGrowthBar(value: 0.48),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(_k([47560, 47700, 47352])), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
    },
  );

  testWidgets('navigation toast banner loading controls and rating render', (
    tester,
  ) async {
    await _pump(
      tester,
      Builder(
        builder: (context) {
          return Column(
            children: [
              MameroomBottomNavigation(
                currentIndex: 0,
                onTap: (_) {},
                items: const [
                  MameroomBottomNavigationItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  MameroomBottomNavigationItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Study',
                  ),
                ],
              ),
              const MameroomBanner(
                message: 'Banner',
                variant: MameroomFeedbackVariant.info,
              ),
              const MameroomLoadingDots(),
              const MameroomSkeleton(width: 160),
              const MameroomSeedPulse(),
              MameroomDropdown<String>(
                value: 'a',
                items: const {'a': 'A', 'b': 'B'},
                onChanged: (_) {},
              ),
              MameroomSwitch(value: true, onChanged: (_) {}),
              MameroomCheckbox(value: true, onChanged: (_) {}),
              MameroomChipGroup<String>(
                items: const {'a': 'A', 'b': 'B'},
                selected: 'a',
                onSelected: (_) {},
              ),
              const MameroomStarRating(value: 4),
              const MameroomStatBar(label: 'Stat', value: 0.7),
              MameroomTextActionButton(
                label: 'Toast',
                onPressed: () => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(MameroomToast(message: 'Toast')),
              ),
            ],
          );
        },
      ),
    );
    expect(find.text('Banner'), findsOneWidget);
    await tester.tap(find.text('Toast'));
    await tester.pump();
    expect(find.text('Toast'), findsWidgets);
  });

  testWidgets('design system sample fits target mobile sizes', (tester) async {
    for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
      await _pump(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              MameroomPrimaryButton(label: 'Button', onPressed: null),
              SizedBox(height: 12),
              MameroomCard(child: Text('Responsive card')),
              SizedBox(height: 12),
              MameroomProgressBar(value: 0.5),
            ],
          ),
        ),
        size: size,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
