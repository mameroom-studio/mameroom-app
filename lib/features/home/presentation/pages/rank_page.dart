import 'package:flutter/material.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';

class RankPage extends StatelessWidget {
  const RankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MameroomShell(
      showSparkles: false,
      child: ListView(
        children: const [
          _RankHeader(),
          SizedBox(height: 18),
          _RankPlaceholderCard(title: '친구 랭킹', subtitle: '친구 기능 연동 후 표시됩니다.', icon: Icons.group_outlined),
          SizedBox(height: 12),
          _RankPlaceholderCard(title: '학교 랭킹', subtitle: '소속 학교 설정 후 표시됩니다.', icon: Icons.school_outlined),
          SizedBox(height: 12),
          _RankPlaceholderCard(title: '전체 랭킹', subtitle: '정식 랭킹 정책 확정 후 표시됩니다.', icon: Icons.public_outlined),
        ],
      ),
    );
  }
}

class _RankHeader extends StatelessWidget {
  const _RankHeader();

  @override
  Widget build(BuildContext context) {
    return Text('Rank', style: Theme.of(context).textTheme.headlineMedium);
  }
}

class _RankPlaceholderCard extends StatelessWidget {
  const _RankPlaceholderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
