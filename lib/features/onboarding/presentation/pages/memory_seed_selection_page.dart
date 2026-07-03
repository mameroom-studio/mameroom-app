import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import 'creating_room_page.dart';

class MemorySeedSelectionPage extends StatefulWidget {
  const MemorySeedSelectionPage({super.key});

  static const routePath = '/memory-seed';

  @override
  State<MemorySeedSelectionPage> createState() => _MemorySeedSelectionPageState();
}

class _MemorySeedSelectionPageState extends State<MemorySeedSelectionPage> {
  int _selectedIndex = 0;

  static const _seeds = [
    _SeedChoice('벚꽃', Icons.local_florist, Color(0xFFFB70A5)),
    _SeedChoice('바오밥', Icons.park, Color(0xFF5E9F57)),
    _SeedChoice('단풍', Icons.eco, Color(0xFFF26A3D)),
    _SeedChoice('은행', Icons.spa, Color(0xFFFFC857)),
    _SeedChoice('오로라', Icons.diamond_outlined, Color(0xFF7C5CFF)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return MameroomShell(
      showSparkles: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text(
            '내 기억씨앗을 선택해주세요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '어떤 나무로 성장할지 선택할 수 있어요!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              itemCount: _seeds.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.92,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final seed = _seeds[index];
                final isSelected = index == _selectedIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primaryMist.withValues(alpha: 0.34) : colors.paper,
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.line,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PixelSeedCardArt(color: seed.color, icon: seed.icon),
                              const SizedBox(height: 14),
                              Text(
                                seed.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Icon(Icons.check_circle, color: colors.primary),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          MameroomPrimaryButton(
            label: '선택하고 시작하기',
            onPressed: () => context.go(CreatingRoomPage.routePath),
          ),
        ],
      ),
    );
  }
}

class _SeedChoice {
  const _SeedChoice(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
