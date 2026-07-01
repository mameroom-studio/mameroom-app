import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/colors/app_colors.dart';
import '../../../../shared/design_system/spacing/app_spacing.dart';
import '../../domain/entities/study_material.dart';
import '../providers/library_mock_providers.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../upload/presentation/pages/upload_page.dart';
import '../../../review/presentation/pages/review_page.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../../gamification/presentation/pages/room_page.dart';
import '../../../streak/presentation/providers/streak_providers.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  static const routePath = '/library';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthFormState>(authControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.infoMessage;
      if (message == null || message == previous?.errorMessage ||
          message == previous?.infoMessage) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      ref.read(authControllerProvider.notifier).clearMessages();
    });

    final dashboard = ref.watch(libraryDashboardProvider);
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final isAuthLoading = ref.watch(authControllerProvider).isLoading;
    final wallet = ref.watch(coinWalletProvider);
    final streak = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          TextButton(
            onPressed: isAuthLoading
                ? null
                : () async {
                    try {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go(LoginPage.routePath);
                      }
                    } catch (_) {
                      // Error state is exposed by authControllerProvider.
                    }
                  },
            child: isAuthLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _Header(email: currentUser?.email),
            const SizedBox(height: AppSpacing.lg),
            _SummaryRow(
              todayReviewCount: dashboard.todayReviewCount,
              totalMemoryPercent: dashboard.totalMemoryPercent,
            ),
            const SizedBox(height: AppSpacing.sm),
            wallet.when(
              loading: () => const _CoinSummary(balance: '-', todayEarned: '-'),
              error: (error, stackTrace) => const _CoinSummary(balance: '0', todayEarned: '0'),
              data: (value) => _CoinSummary(
                balance: '${value.balance}',
                todayEarned: '+${value.todayEarned}',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            streak.when(
              loading: () => const _StreakSummary(current: '-', max: '-'),
              error: (error, stackTrace) => const _StreakSummary(current: '0', max: '0'),
              data: (value) => _StreakSummary(
                current: '${value.currentStreak}',
                max: '${value.maxStreak}',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(ReviewPage.routePath),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Review today'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(RoomPage.routePath),
                    icon: const Icon(Icons.meeting_room),
                    label: const Text('My Room'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context.push(UploadPage.routePath),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload file'),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              title: 'Study materials',
              trailing: '${dashboard.materials.length}',
            ),
            const SizedBox(height: AppSpacing.sm),
            if (dashboard.materials.isEmpty)
              const _EmptyMaterials()
            else
              ...dashboard.materials.map(_MaterialTile.new),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeader(title: 'Recent study'),
            const SizedBox(height: AppSpacing.sm),
            if (dashboard.recentRecords.isEmpty)
              const _EmptyRecentRecords()
            else
              ...dashboard.recentRecords.map(_RecentRecordTile.new),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to study',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          email ?? 'Signed in',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.todayReviewCount,
    required this.totalMemoryPercent,
  });

  final int todayReviewCount;
  final int totalMemoryPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Reviews today',
            value: '$todayReviewCount',
            icon: Icons.event_available,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricTile(
            label: 'Total memory',
            value: '$totalMemoryPercent%',
            icon: Icons.psychology_alt,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinSummary extends StatelessWidget {
  const _CoinSummary({required this.balance, required this.todayEarned});

  final String balance;
  final String todayEarned;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'M-Coin balance',
            value: balance,
            icon: Icons.toll,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricTile(
            label: 'Earned today',
            value: todayEarned,
            icon: Icons.add_circle_outline,
          ),
        ),
      ],
    );
  }
}

class _StreakSummary extends StatelessWidget {
  const _StreakSummary({required this.current, required this.max});

  final String current;
  final String max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Streak',
            value: '$current days',
            icon: Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricTile(
            label: 'Max streak',
            value: '$max days',
            icon: Icons.workspace_premium,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
      ],
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile(this.material);

  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      material.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${material.sectionCount} sections 쨌 next review ${material.nextReviewLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(value: material.progressPercent / 100),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress ${material.progressPercent}%'),
                  Text('Memory ${material.memoryPercent}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRecordTile extends StatelessWidget {
  const _RecentRecordTile(this.record);

  final RecentStudyRecord record;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.check)),
      title: Text(record.title),
      subtitle: Text(record.subtitle),
      trailing: Text(record.scoreLabel),
    );
  }
}

class _EmptyMaterials extends StatelessWidget {
  const _EmptyMaterials();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 40),
            SizedBox(height: AppSpacing.sm),
            Text('No study materials yet.'),
            SizedBox(height: AppSpacing.xs),
            Text('Upload a file to create your first quiz.'),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecentRecords extends StatelessWidget {
  const _EmptyRecentRecords();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text('No recent study records yet.'),
    );
  }
}