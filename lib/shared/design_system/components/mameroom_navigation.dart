import 'package:flutter/material.dart';

import '../tokens/mameroom_colors.dart';

class MameroomBottomNavigationItem {
  const MameroomBottomNavigationItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

class MameroomBottomNavigation extends StatelessWidget {
  const MameroomBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<MameroomBottomNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: MameroomColors.surface,
      indicatorColor: MameroomColors.primaryMist,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(
                item.selectedIcon ?? item.icon,
                color: MameroomColors.primary,
              ),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
