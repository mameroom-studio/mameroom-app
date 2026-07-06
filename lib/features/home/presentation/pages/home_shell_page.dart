import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  static const rankRoutePath = '/rank';
  static const myInfoRoutePath = '/my-info';

  static const destinations = [
    _HomeDestination(label: '홈', icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, routePath: homeRoutePath),
    _HomeDestination(label: '공부', icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book_rounded, routePath: studyRoutePath),
    _HomeDestination(label: '랭크', icon: Icons.emoji_events_outlined, selectedIcon: Icons.emoji_events_rounded, routePath: rankRoutePath),
    _HomeDestination(label: '내 정보', icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, routePath: myInfoRoutePath),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(destinations[index].routePath),
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
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
