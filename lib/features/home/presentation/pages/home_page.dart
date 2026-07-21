import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/assets/app_assets.dart';
import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../../core/presentation/modals/mameroom_modals.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../../gamification/presentation/pages/room_page.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../library/presentation/providers/library_mock_providers.dart';
import '../../../review/presentation/pages/review_page.dart';
import '../../../quiz/presentation/pages/quiz_page.dart';
import '../../../notifications/presentation/widgets/mameroom_notification_icon.dart';
import '../../../streak/presentation/providers/streak_providers.dart';
import 'learning_report_page.dart';
import '../../domain/entities/next_study_action.dart';
import '../providers/next_study_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(libraryDashboardProvider);
    final walletState = ref.watch(coinWalletProvider);
    final streakState = ref.watch(streakProvider);
    final roomState = ref.watch(myRoomControllerProvider);

    final dashboard = dashboardState.asData?.value;
    final wallet = walletState.asData?.value;
    final streak = streakState.asData?.value;
    final coinBalance = wallet?.balance ?? 0;
    final currentStreak = streak?.currentStreak ?? 0;
    final reviewCount = ref.watch(dueReviewCountProvider).value ?? 0;
    final isResolvingStudy = ref.watch(resolvingNextStudyProvider);
    final memoryPercent = dashboard?.totalMemoryPercent ?? 0;
    final roomItems = roomState.asData?.value.layouts.length ?? 0;
    final learningProgress = _learningProgress(memoryPercent, reviewCount);
    final colors = context.mameroom;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.paper, colors.primaryMist.withValues(alpha: 0.18)],
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _HomeMetrics.from(constraints);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.sidePadding,
                    metrics.topPadding,
                    metrics.sidePadding,
                    metrics.bottomPadding,
                  ),
                  child: SizedBox(
                    height: metrics.contentHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: metrics.headerHeight,
                          child: _Header(coinBalance: coinBalance),
                        ),
                        SizedBox(height: metrics.gap),
                        SizedBox(
                          height: metrics.profileHeight,
                          child: _ProfileArea(
                            currentStreak: currentStreak,
                            compact: metrics.compact,
                            onDecorate: () => context.push(RoomPage.routePath),
                          ),
                        ),
                        SizedBox(height: metrics.gap),
                        SizedBox(
                          height: metrics.roomHeight,
                          child: _RoomCanvas(itemCount: roomItems),
                        ),
                        SizedBox(height: metrics.gap),
                        SizedBox(
                          height: metrics.todayHeight,
                          child: _TodayStudyCard(
                            reviewCount: reviewCount,
                            memoryPercent: memoryPercent,
                            compact: metrics.compact,
                            isLoading: isResolvingStudy,
                            onStart: () => _startNextStudy(context, ref),
                          ),
                        ),
                        SizedBox(height: metrics.gap),
                        SizedBox(
                          height: metrics.weeklyHeight,
                          child: _MyLearningCard(
                            progress: learningProgress,
                            reviewCount: reviewCount,
                            memoryPercent: memoryPercent,
                            currentStreak: currentStreak,
                            compact: metrics.compact,
                            onTap: () =>
                                context.push(LearningReportPage.routePath),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _startNextStudy(BuildContext context, WidgetRef ref) async {
    if (ref.read(resolvingNextStudyProvider)) return;
    ref.read(resolvingNextStudyProvider.notifier).state = true;
    try {
      final action = await ref.read(nextStudyActionResolverProvider)();
      if (!context.mounted) return;
      switch (action) {
        case ResumeStudy(:final materialId):
          await context.push(QuizPage.location(materialId));
        case StartNewStudy(:final materialId):
          await context.push(
            QuizPage.location(materialId, unlearnedOnly: true),
          );
        case StartReview():
          await context.push(ReviewPage.routePath);
        case NoStudyAvailable():
          await MameroomPopupService.showInfo(
            context,
            title: '현재 진행할 학습이 모두 끝났어요!',
            message: '새로운 문제가 추가되거나 복습 시간이 되면 다시 시작할 수 있어요.',
          );
      }
    } catch (_) {
      if (context.mounted) {
        await MameroomPopupService.showInfo(
          context,
          title: '학습을 준비하지 못했어요',
          message: '잠시 후 다시 시도해 주세요.',
        );
      }
    } finally {
      ref.read(resolvingNextStudyProvider.notifier).state = false;
    }
  }

  double _learningProgress(int memoryPercent, int reviewCount) {
    final memoryWeight = memoryPercent / 100;
    final reviewWeight = reviewCount == 0 ? 0.35 : 0.75;
    return ((memoryWeight * 0.55) + (reviewWeight * 0.45))
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

class _HomeMetrics {
  const _HomeMetrics({
    required this.sidePadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.gap,
    required this.headerHeight,
    required this.profileHeight,
    required this.roomHeight,
    required this.todayHeight,
    required this.weeklyHeight,
    required this.contentHeight,
    required this.compact,
  });

  final double sidePadding;
  final double topPadding;
  final double bottomPadding;
  final double gap;
  final double headerHeight;
  final double profileHeight;
  final double roomHeight;
  final double todayHeight;
  final double weeklyHeight;
  final double contentHeight;
  final bool compact;

  static _HomeMetrics from(BoxConstraints constraints) {
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : 760.0;
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 390.0;
    final compact = height < 720 || width < 380;
    final sidePadding = width < 380 ? 12.0 : 16.0;
    final topPadding = compact ? 8.0 : 12.0;
    final bottomPadding = compact ? 8.0 : 10.0;
    final gap = compact ? 6.0 : 9.0;
    final contentHeight = math.max(0.0, height - topPadding - bottomPadding);
    final headerHeight = _clamp(contentHeight * 0.065, compact ? 36 : 42, 48);
    final profileHeight = _clamp(contentHeight * 0.14, compact ? 72 : 82, 96);
    final todayHeight = _clamp(contentHeight * 0.21, compact ? 156 : 144, 164);
    final weeklyHeight = _clamp(contentHeight * 0.08, compact ? 50 : 56, 66);
    final roomHeight = math.max(
      150.0,
      contentHeight -
          headerHeight -
          profileHeight -
          todayHeight -
          weeklyHeight -
          (gap * 4),
    );

    return _HomeMetrics(
      sidePadding: sidePadding,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      gap: gap,
      headerHeight: headerHeight,
      profileHeight: profileHeight,
      roomHeight: roomHeight,
      todayHeight: todayHeight,
      weeklyHeight: weeklyHeight,
      contentHeight: contentHeight,
      compact: compact,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.coinBalance});

  final int coinBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        const _PixelLogoMark(size: 30),
        const SizedBox(width: MameroomSpacing.xs),
        Expanded(
          child: Text(
            'MAMEROOM',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        _CurrencyPill(
          icon: Icons.monetization_on_rounded,
          label: _compactNumber(coinBalance),
          color: colors.sun,
        ),
        const SizedBox(width: MameroomSpacing.xs - 2),
        MameroomNotificationIcon(
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

class _ProfileArea extends StatelessWidget {
  const _ProfileArea({
    required this.currentStreak,
    required this.compact,
    required this.onDecorate,
  });

  final int currentStreak;
  final bool compact;
  final VoidCallback onDecorate;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final avatarSize = compact ? 64.0 : 78.0;
    return Row(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: colors.primaryMist.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: colors.line),
          ),
          child: Center(child: PixelCharacter(size: compact ? 45 : 54)),
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '\u{AE40}\u{C720}\u{C774}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: compact ? 24 : 28,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(width: MameroomSpacing.xs - 2),
                  Icon(Icons.edit_rounded, size: 17, color: colors.muted),
                  const SizedBox(width: MameroomSpacing.xs),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 10,
                      vertical: compact ? 3 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryMist,
                      borderRadius: BorderRadius.circular(MameroomRadius.pill),
                    ),
                    child: Text(
                      'Lv.18',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 5 : 8),
              Text(
                '\u{1F525}  \u{C5F0}\u{C18D} \u{D559}\u{C2B5} $currentStreak\u{C77C}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.ink.withValues(alpha: 0.72),
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        SizedBox(
          width: compact ? 66 : 76,
          height: compact ? 62 : 72,
          child: OutlinedButton(
            onPressed: onDecorate,
            style: OutlinedButton.styleFrom(
              backgroundColor: colors.paper,
              padding: EdgeInsets.zero,
              side: BorderSide(color: colors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction_rounded,
                  color: colors.ink,
                  size: compact ? 22 : 25,
                ),
                SizedBox(height: compact ? 3 : 5),
                Text(
                  '\u{AFB8}\u{BBF8}\u{AE30}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.ink,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomCanvas extends StatelessWidget {
  const _RoomCanvas({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return ClipRRect(
      borderRadius: BorderRadius.circular(MameroomRadius.small),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBD4),
          border: Border.all(color: const Color(0xFFD7B083)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scale = _clamp(
              math.min(width / 390, height / 320),
              0.58,
              1.08,
            );
            Widget box(double w, double h, Widget child) {
              return SizedBox(
                width: w * scale,
                height: h * scale,
                child: FittedBox(child: child),
              );
            }

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _RoomPainter(colors)),
                ),
                Positioned(
                  left: width * 0.06,
                  top: height * 0.49,
                  child: box(108, 78, const _BedShape()),
                ),
                Positioned(
                  left: width * 0.25,
                  top: height * 0.19,
                  child: box(94, 66, const _WindowShape()),
                ),
                Positioned(
                  right: width * 0.23,
                  top: height * 0.18,
                  child: box(100, 50, const _ShelfShape()),
                ),
                Positioned(
                  right: width * 0.08,
                  top: height * 0.44,
                  child: box(108, 74, const _DeskShape()),
                ),
                Positioned(
                  right: width * 0.07,
                  bottom: height * 0.10,
                  child: box(56, 88, const _BookcaseShape()),
                ),
                Positioned(
                  left: width * 0.07,
                  top: height * 0.27,
                  child: box(42, 42, const _PlantShape()),
                ),
                Positioned(
                  left: width * 0.06,
                  bottom: height * 0.12,
                  child: box(48, 48, const _PlantShape()),
                ),
                Positioned(
                  left: width * 0.5 - (42 * scale),
                  bottom: height * 0.14,
                  child: PixelCharacter(size: 70 * scale),
                ),
                Positioned(
                  left: width * 0.5 + (16 * scale),
                  top: height * 0.44,
                  child: box(58, 42, const _SpeechBubble()),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: itemCount > 0
                          ? colors.primary
                          : colors.line.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TodayStudyCard extends StatelessWidget {
  const _TodayStudyCard({
    required this.reviewCount,
    required this.memoryPercent,
    required this.compact,
    required this.isLoading,
    required this.onStart,
  });

  final int reviewCount;
  final int memoryPercent;
  final bool compact;
  final bool isLoading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _SoftCard(
      padding: const EdgeInsets.all(MameroomSpacing.sm),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u{C624}\u{B298}\u{C758} \u{D559}\u{C2B5}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MameroomSpacing.xxs),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _StudyMetric(
                    icon: Icons.menu_book_rounded,
                    label: '\u{BCF5}\u{C2B5}\u{D560} \u{BB38}\u{C81C}',
                    value: reviewCount.toString(),
                    suffix: ' / 20',
                    compact: compact,
                  ),
                ),
                Container(
                  width: 1,
                  height: double.infinity,
                  color: colors.line,
                ),
                Expanded(
                  child: _MemoryMetric(
                    memoryPercent: memoryPercent,
                    compact: compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MameroomSpacing.xxs),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed: isLoading ? null : onStart,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\u{ACF5}\u{BD80} \u{C2DC}\u{C791}\u{D558}\u{AE30}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MameroomColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: MameroomSpacing.sm - 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: MameroomColors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLearningCard extends StatelessWidget {
  const _MyLearningCard({
    required this.progress,
    required this.reviewCount,
    required this.memoryPercent,
    required this.currentStreak,
    required this.compact,
    required this.onTap,
  });

  final double progress;
  final int reviewCount;
  final int memoryPercent;
  final int currentStreak;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Semantics(
      button: true,
      label: '\uB0B4 \uD559\uC2B5 \uC790\uC138\uD788 \uBCF4\uAE30',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: _SoftCard(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 7 : 9,
          ),
          radius: 18,
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 40,
                height: compact ? 34 : 40,
                decoration: BoxDecoration(
                  color: colors.primaryMist,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: compact ? 22 : 26,
                  color: colors.primary,
                ),
              ),
              SizedBox(width: compact ? 9 : 12),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\uB0B4 \uD559\uC2B5',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '\uC624\uB298 $reviewCount\uBB38\uC81C ? $currentStreak\uC77C \uC5F0\uC18D',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.muted,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: compact ? 6 : 8,
                  borderRadius: BorderRadius.circular(MameroomRadius.pill),
                  backgroundColor: colors.primaryMist,
                ),
              ),
              SizedBox(width: compact ? 7 : 9),
              Text(
                '$memoryPercent%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyMetric extends StatelessWidget {
  const _StudyMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Container(
          width: compact ? 30 : 34,
          height: compact ? 30 : 34,
          decoration: BoxDecoration(
            color: colors.primaryMist,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colors.primary, size: compact ? 19 : 21),
        ),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.muted,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  maxLines: 1,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.ink,
                      fontSize: compact ? 22 : 26,
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      TextSpan(text: value),
                      TextSpan(
                        text: suffix,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemoryMetric extends StatelessWidget {
  const _MemoryMetric({required this.memoryPercent, required this.compact});

  final int memoryPercent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: EdgeInsets.only(left: compact ? 8 : 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u{AE30}\u{C5B5}\u{B960}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.muted,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '$memoryPercent%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colors.primary,
              fontSize: compact ? 24 : 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: MameroomSpacing.xs),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: MameroomSpacing.xxs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(MameroomSpacing.md),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PixelLogoMark extends StatelessWidget {
  const _PixelLogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        AppAssets.mameroomIcon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class _BedShape extends StatelessWidget {
  const _BedShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFFB77945),
        border: Border.all(color: const Color(0xFF7D4C24), width: 2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(8),
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFB8A7FF),
            borderRadius: BorderRadius.circular(MameroomRadius.small),
          ),
        ),
      ),
    );
  }
}

class _WindowShape extends StatelessWidget {
  const _WindowShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFFBFE8FF),
        border: Border.all(color: const Color(0xFF9B6B35), width: 3),
      ),
      child: const Icon(Icons.landscape_rounded, color: Color(0xFF6FBD83)),
    );
  }
}

class _ShelfShape extends StatelessWidget {
  const _ShelfShape();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 50,
      child: Stack(
        children: const [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 6,
            child: ColoredBox(color: Color(0xFF9A6333)),
          ),
          Positioned(
            left: 8,
            bottom: 6,
            width: 10,
            height: 34,
            child: ColoredBox(color: Color(0xFF6E73CF)),
          ),
          Positioned(
            left: 24,
            bottom: 6,
            width: 10,
            height: 28,
            child: ColoredBox(color: Color(0xFFB9783F)),
          ),
          Positioned(
            left: 46,
            bottom: 6,
            child: Icon(
              Icons.local_florist_rounded,
              color: Color(0xFF4FAD5E),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeskShape extends StatelessWidget {
  const _DeskShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFFC98D4D),
        border: Border.all(color: const Color(0xFF8B5628), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Align(
        alignment: Alignment.topCenter,
        child: Icon(
          Icons.desktop_windows_rounded,
          size: 34,
          color: Color(0xFF16115A),
        ),
      ),
    );
  }
}

class _BookcaseShape extends StatelessWidget {
  const _BookcaseShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFB77945),
        border: Border.all(color: const Color(0xFF7D4C24), width: 2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white70),
    );
  }
}

class _PlantShape extends StatelessWidget {
  const _PlantShape();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_florist_rounded,
          color: Color(0xFF4FAD5E),
          size: 34,
        ),
        Container(
          width: 24,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFB77945),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(58, 42),
      painter: _SpeechBubblePainter(context.mameroom),
      child: const SizedBox(
        width: 58,
        height: 42,
        child: Center(
          child: Icon(Icons.eco_rounded, color: Color(0xFF4FAD5E), size: 22),
        ),
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter(this.colors);

  final MameroomTheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = MameroomColors.white;
    final stroke = Paint()
      ..color = colors.muted.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(8, 2)
      ..lineTo(size.width - 8, 2)
      ..quadraticBezierTo(size.width - 2, 2, size.width - 2, 8)
      ..lineTo(size.width - 2, size.height - 16)
      ..quadraticBezierTo(
        size.width - 2,
        size.height - 10,
        size.width - 8,
        size.height - 10,
      )
      ..lineTo(size.width * 0.57, size.height - 10)
      ..lineTo(size.width * 0.48, size.height - 2)
      ..lineTo(size.width * 0.42, size.height - 10)
      ..lineTo(8, size.height - 10)
      ..quadraticBezierTo(2, size.height - 10, 2, size.height - 16)
      ..lineTo(2, 8)
      ..quadraticBezierTo(2, 2, 8, 2)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter(this.colors);

  final MameroomTheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()..color = const Color(0xFFFFECD8);
    final floorPaint = Paint()..color = const Color(0xFFEFC68F);
    final borderPaint = Paint()
      ..color = const Color(0xFFC79B6F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final wall = Path()
      ..moveTo(size.width * 0.08, size.height * 0.06)
      ..lineTo(size.width * 0.92, size.height * 0.06)
      ..lineTo(size.width * 0.98, size.height * 0.28)
      ..lineTo(size.width * 0.98, size.height * 0.64)
      ..lineTo(size.width * 0.02, size.height * 0.64)
      ..lineTo(size.width * 0.02, size.height * 0.28)
      ..close();
    canvas.drawPath(wall, wallPaint);
    canvas.drawPath(wall, borderPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.64, size.width, size.height * 0.36),
      floorPaint,
    );
    final linePaint = Paint()
      ..color = const Color(0xFFDDAE75)
      ..strokeWidth = 1;
    final step = math.max(12.0, size.height * 0.06);
    for (var y = size.height * 0.70; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.82),
        width: size.width * 0.42,
        height: size.height * 0.22,
      ),
      Paint()..color = const Color(0xFFFFF5E7),
    );
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

double _clamp(num value, double min, double max) =>
    value.clamp(min, max).toDouble();

String _compactNumber(int value) {
  if (value < 1000) return value.toString();
  final thousands = value / 1000;
  return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
}
