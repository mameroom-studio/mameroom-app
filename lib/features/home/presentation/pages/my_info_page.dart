import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../coins/presentation/providers/coin_providers.dart';

class MyInfoPage extends ConsumerWidget {
  const MyInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final wallet = ref.watch(coinWalletProvider).asData?.value;
    final authState = ref.watch(authControllerProvider);

    return MameroomShell(
      showSparkles: false,
      child: ListView(
        children: [
          Text('My Info', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          _InfoCard(
            children: [
              _InfoRow(label: '닉네임', value: user?.email?.split('@').first ?? '마메러'),
              _InfoRow(label: '소속', value: '미설정'),
              const _InfoRow(label: '현재 플랜', value: 'FREE'),
              const _InfoRow(label: '잔여 문제 수', value: '30'),
              _InfoRow(label: 'M-Coin', value: '${wallet?.balance ?? 0}'),
              const _InfoRow(label: 'Diamond', value: '0'),
            ],
          ),
          const SizedBox(height: 14),
          const _InfoCard(
            children: [
              _InfoRow(label: '프로모션 코드', value: '준비 중'),
              _InfoRow(label: '사운드 설정', value: '켜짐'),
            ],
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: authState.isLoading
                ? null
                : () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go(LoginPage.routePath);
                    }
                  },
            icon: authState.isLoading
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.logout_rounded),
            label: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

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
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
