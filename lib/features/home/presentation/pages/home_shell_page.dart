import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/mameroom_design_system.dart';

import 'home_page.dart';
import 'my_info_page.dart';
import 'rank_page.dart';
import '../../../library/presentation/pages/library_page.dart';

class HomeShellPage extends StatelessWidget {
  const HomeShellPage({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  final int selectedIndex;
  final Widget child;

  static const homeRoutePath = '/home';
  static const studyRoutePath = '/study';
  static const rankRoutePath = '/friends';
  static const myInfoRoutePath = '/my-info';

  static const destinations = [
    _HomeDestination(
      label: '\u{D648}',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      routePath: homeRoutePath,
    ),
    _HomeDestination(
      label: '\u{ACF5}\u{BD80}',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      routePath: studyRoutePath,
    ),
    _HomeDestination(
      label: '\u{CE5C}\u{AD6C}',
      icon: Icons.group_outlined,
      selectedIcon: Icons.group_rounded,
      routePath: rankRoutePath,
    ),
    _HomeDestination(
      label: '\u{B0B4} \u{C815}\u{BCF4}',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      routePath: myInfoRoutePath,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: MameroomBottomNavigation(
        currentIndex: selectedIndex,
        onTap: (index) => context.go(destinations[index].routePath),
        items: [
          for (final destination in destinations)
            MameroomBottomNavigationItem(
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _HomeDestination {
  const _HomeDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.routePath,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String routePath;
}

class HomeTabRoute extends StatelessWidget {
  const HomeTabRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShellPage(selectedIndex: 0, child: HomePage());
  }
}

class StudyTabRoute extends StatelessWidget {
  const StudyTabRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShellPage(selectedIndex: 1, child: LibraryPage());
  }
}

class RankTabRoute extends StatelessWidget {
  const RankTabRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShellPage(selectedIndex: 2, child: RankPage());
  }
}

class MyInfoTabRoute extends StatelessWidget {
  const MyInfoTabRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShellPage(selectedIndex: 3, child: MyInfoPage());
  }
}
