import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../../gamification/domain/entities/room_item.dart';
import '../../../gamification/presentation/pages/room_page.dart';
import '../../../gamification/presentation/pages/shop_page.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../quiz/presentation/pages/quiz_page.dart';
import '../../../review/presentation/pages/review_page.dart';
import '../../../streak/presentation/providers/streak_providers.dart';
import '../../../upload/presentation/pages/upload_page.dart';
import '../../domain/entities/study_material.dart';
import '../providers/library_mock_providers.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  static const routePath = '/library';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthFormState>(authControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.infoMessage;
      if (message == null || message == previous?.errorMessage || message == previous?.infoMessage) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      ref.read(authControllerProvider.notifier).clearMessages();
    });

    final dashboardState = ref.watch(libraryDashboardProvider);
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final authState = ref.watch(authControllerProvider);
    final wallet = ref.watch(coinWalletProvider);
    final streak = ref.watch(streakProvider);
    final roomState = ref.watch(myRoomControllerProvider);

    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LibraryError(message: error.toString()),
        data: (dashboard) {
          final walletBalance = wallet.maybeWhen(data: (value) => value.balance, orElse: () => 0);
          final todayEarned = wallet.maybeWhen(data: (value) => value.todayEarned, orElse: () => 0);
          final currentStreak = streak.maybeWhen(data: (value) => value.currentStreak, orElse: () => 0);
          final maxStreak = streak.maybeWhen(data: (value) => value.maxStreak, orElse: () => 0);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _HomeHeader(
                email: currentUser?.email,
                isLoading: authState.isLoading,
                onSignOut: () async {
                  try {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go(LoginPage.routePath);
                    }
                  } catch (_) {
                    // Error state is exposed by authControllerProvider.
                  }
                },
              ),
              const SizedBox(height: 20),
              _HeroRoomCard(
                memoryPercent: dashboard.totalMemoryPercent,
                reviewCount: dashboard.todayReviewCount,
                currentStreak: currentStreak,
              ),
              const SizedBox(height: 16),
              _HomeRoomPreview(
                roomState: roomState,
                walletBalance: walletBalance,
                currentStreak: currentStreak,
                onShop: () => context.push(ShopPage.routePath),
                onRoom: () => context.push(RoomPage.routePath),
              ),
              const SizedBox(height: 16),
              _MetricsGrid(
                todayReviewCount: dashboard.todayReviewCount,
                totalMemoryPercent: dashboard.totalMemoryPercent,
                walletBalance: walletBalance,
                todayEarned: todayEarned,
                currentStreak: currentStreak,
                maxStreak: maxStreak,
              ),
              const SizedBox(height: 18),
              _PrimaryActions(
                onReview: () => context.push(ReviewPage.routePath),
                onRoom: () => context.push(RoomPage.routePath),
                onUpload: () => context.push(UploadPage.routePath),
              ),
              const SizedBox(height: 26),
              _SectionHeader(title: '공부 자료', trailing: '${dashboard.materials.length}'),
              const SizedBox(height: 12),
              if (dashboard.materials.isEmpty)
                _EmptyMaterials(onUpload: () => context.push(UploadPage.routePath))
              else
                ...dashboard.materials.map((material) => _MaterialCard(material: material)),
              const SizedBox(height: 24),
              const _SectionHeader(title: '최근 학습 기록'),
              const SizedBox(height: 12),
              if (dashboard.recentRecords.isEmpty)
                const _EmptyRecentRecords()
              else
                ...dashboard.recentRecords.map(_RecentRecordTile.new),
            ],
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.email, required this.isLoading, required this.onSignOut});

  final String? email;
  final bool isLoading;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        const PixelSeed(size: 42),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MAMEROOM', style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 1.1)),
              Text(email ?? '오늘의 기억을 심어볼까요?', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.muted)),
            ],
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : onSignOut,
          child: isLoading
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('로그아웃'),
        ),
      ],
    );
  }
}

class _HeroRoomCard extends StatelessWidget {
  const _HeroRoomCard({required this.memoryPercent, required this.reviewCount, required this.currentStreak});

  final int memoryPercent;
  final int reviewCount;
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: colors.primary.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('학습 준비 완료', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('오늘 복습 $reviewCount개 · 기억률 $memoryPercent% · $currentStreak일 연속', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (memoryPercent / 100).clamp(0, 1),
                    minHeight: 10,
                    color: memoryPercent >= 80 ? colors.sun : colors.primary,
                    backgroundColor: colors.primaryMist.withValues(alpha: 0.56),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(width: 104, child: PixelRoomScene(showFurniture: false, streak: currentStreak > 0 ? currentStreak : null)),
        ],
      ),
    );
  }
}

class _HomeRoomPreview extends StatelessWidget {
  const _HomeRoomPreview({
    required this.roomState,
    required this.walletBalance,
    required this.currentStreak,
    required this.onShop,
    required this.onRoom,
  });

  final AsyncValue<MyRoomState> roomState;
  final int walletBalance;
  final int currentStreak;
  final VoidCallback onShop;
  final VoidCallback onRoom;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final room = roomState.asData?.value;
    final placedItems = room?.layouts.map((layout) => layout.item).toList(growable: false) ?? const <RoomItem>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('My Memory Room', style: Theme.of(context).textTheme.titleLarge)),
              Chip(label: Text('$walletBalance M-Coin')),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 72,
                    child: DecoratedBox(decoration: BoxDecoration(color: colors.primaryMist.withValues(alpha: 0.24))),
                  ),
                  const Positioned(left: 18, bottom: 22, child: PixelSeed(size: 42)),
                  const Positioned(left: 110, bottom: 24, child: PixelCharacter(size: 58)),
                  Positioned(right: 14, top: 12, child: Text('Streak $currentStreak일')),
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (final item in placedItems.take(4))
                          Tooltip(
                            message: item.name,
                            child: Icon(_homeRoomIconFor(item.itemType), color: colors.primary, size: 24),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShop,
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('상점 가기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRoom,
                  icon: const Icon(Icons.meeting_room_outlined),
                  label: const Text('내 방 보기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _homeRoomIconFor(String type) {
  return switch (type) {
    'desk' => Icons.table_bar_outlined,
    'chair' => Icons.chair_outlined,
    'plant' => Icons.local_florist_outlined,
    'lamp' => Icons.light_outlined,
    'rug' => Icons.crop_landscape_outlined,
    'clock' => Icons.schedule_outlined,
    _ => Icons.widgets_outlined,
  };
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.todayReviewCount,
    required this.totalMemoryPercent,
    required this.walletBalance,
    required this.todayEarned,
    required this.currentStreak,
    required this.maxStreak,
  });

  final int todayReviewCount;
  final int totalMemoryPercent;
  final int walletBalance;
  final int todayEarned;
  final int currentStreak;
  final int maxStreak;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(Icons.event_available_outlined, '$todayReviewCount', '오늘 복습'),
      _MetricData(Icons.spa_outlined, '$totalMemoryPercent%', '총 기억률'),
      _MetricData(Icons.monetization_on_outlined, '$walletBalance', 'M-Coin'),
      _MetricData(Icons.add_circle_outline, '+$todayEarned', '오늘 획득'),
      _MetricData(Icons.local_fire_department_outlined, '$currentStreak일', 'Streak'),
      _MetricData(Icons.workspace_premium_outlined, '$maxStreak일', '최대 Streak'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 126,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _MetricTile(data: items[index]),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, color: colors.primary, size: 25),
          const SizedBox(height: 12),
          Text(data.value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(data.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.muted)),
        ],
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.onReview, required this.onRoom, required this.onUpload});

  final VoidCallback onReview;
  final VoidCallback onRoom;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _HomeButton(label: '오늘 복습', icon: Icons.event_available_outlined, onPressed: onReview, filled: true)),
            const SizedBox(width: 10),
            Expanded(child: _HomeButton(label: 'My Room', icon: Icons.meeting_room_outlined, onPressed: onRoom)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onUpload,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: colors.line),
            ),
            icon: Icon(Icons.upload_file_outlined, color: colors.primary),
            label: const Text('공부 파일 업로드'),
          ),
        ),
      ],
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({required this.label, required this.icon, required this.onPressed, this.filled = false});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: shape),
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: shape),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        if (trailing != null) Text(trailing!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted)),
      ],
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.material});

  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final learnedText = material.totalQuestionCount == 0
        ? '문제 생성 대기 중'
        : '${material.completedQuestionCount}/${material.totalQuestionCount}문제 학습';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: colors.primaryMist.withValues(alpha: 0.36), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.description_outlined, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(material.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(learnedText, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(material.seedEmoji, style: const TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 18),
          _DashboardProgressLine(
            label: '학습률',
            valueLabel: '${material.progressPercent}%',
            value: material.progressPercent / 100,
            color: colors.primary,
          ),
          const SizedBox(height: 12),
          _DashboardProgressLine(
            label: '기억률',
            valueLabel: '${material.memoryPercent}%',
            value: material.memoryPercent / 100,
            color: material.memoryPercent >= 80 ? colors.sun : colors.seedGreen,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DashboardInfoChip(icon: Icons.event_available_outlined, label: '복습 예정 ${material.dueReviewCount}개'),
              _DashboardInfoChip(icon: Icons.spa_outlined, label: '${material.seedEmoji} ${material.seedLabel}'),
              _DashboardInfoChip(icon: Icons.schedule_outlined, label: '최근 학습 ${material.recentStudyLabel}'),
              _DashboardInfoChip(icon: Icons.local_fire_department_outlined, label: '${material.currentStreak}일 연속'),
            ],
          ),
          if (material.canStartQuiz) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('${QuizPage.routePath}?materialId=${material.id}'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('퀴즈 시작'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardProgressLine extends StatelessWidget {
  const _DashboardProgressLine({required this.label, required this.valueLabel, required this.value, required this.color});

  final String label;
  final String valueLabel;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final normalized = value.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.ink)),
            const Spacer(),
            Text(valueLabel, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.ink)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 9,
            color: color,
            backgroundColor: colors.primaryMist.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _DashboardInfoChip extends StatelessWidget {
  const _DashboardInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryMist.withValues(alpha: 0.22),
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.ink)),
        ],
      ),
    );
  }
}

class _RecentRecordTile extends StatelessWidget {
  const _RecentRecordTile(this.record);

  final RecentStudyRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.paper, border: Border.all(color: colors.line), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: colors.seedGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title, style: Theme.of(context).textTheme.titleSmall),
                Text(record.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.muted)),
              ],
            ),
          ),
          Text(record.scoreLabel, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _EmptyMaterials extends StatelessWidget {
  const _EmptyMaterials({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colors.paper, border: Border.all(color: colors.line), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const PixelSeed(size: 62),
          const SizedBox(height: 14),
          Text('아직 공부 자료가 없어요', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('파일을 넣으면 AI가 퀴즈와 복습 일정을 만들어줘요.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          _HomeButton(label: '파일 업로드', icon: Icons.upload_file_outlined, onPressed: onUpload, filled: true),
        ],
      ),
    );
  }
}

class _EmptyRecentRecords extends StatelessWidget {
  const _EmptyRecentRecords();

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.paper, border: Border.all(color: colors.line), borderRadius: BorderRadius.circular(18)),
      child: Text('최근 학습 기록이 아직 없어요.', style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: context.mameroom.paper, border: Border.all(color: context.mameroom.line), borderRadius: BorderRadius.circular(24)),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
}
