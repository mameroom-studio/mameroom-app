import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/states/mameroom_empty_state.dart';
import '../../../../core/presentation/states/mameroom_error_state.dart';
import '../../../../core/presentation/states/mameroom_loading_state.dart';
import '../../../../core/presentation/states/mameroom_state_view.dart';
import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../library/domain/entities/study_material.dart';
import '../../../library/presentation/providers/library_mock_providers.dart';
import '../../../streak/presentation/providers/streak_providers.dart';

enum LearningReportPeriod {
  today('\uC624\uB298'),
  weekly('\uC8FC\uAC04'),
  monthly('\uC6D4\uAC04'),
  all('\uC804\uCCB4');

  const LearningReportPeriod(this.label);

  final String label;
}

class LearningReportPage extends ConsumerStatefulWidget {
  const LearningReportPage({super.key});

  static const routePath = '/learning-report';

  @override
  ConsumerState<LearningReportPage> createState() => _LearningReportPageState();
}

class _LearningReportPageState extends ConsumerState<LearningReportPage> {
  LearningReportPeriod _period = LearningReportPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(libraryDashboardProvider);
    final streakState = ref.watch(streakProvider);
    final colors = context.mameroom;

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: const Text('\uB0B4 \uD559\uC2B5'),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: colors.paper,
      ),
      body: dashboardState.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: MameroomLoadingState(
            title: '\uD559\uC2B5 \uB9AC\uD3EC\uD2B8 \uB85C\uB529',
            description:
                '\uB0B4 \uD559\uC2B5 \uAE30\uB85D\uC744 \uC815\uB9AC\uD558\uACE0 \uC788\uC5B4\uC694.',
            size: MameroomStateSize.full,
          ),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: MameroomErrorState.network(
            onRetry: () {
              ref.invalidate(libraryDashboardProvider);
              ref.invalidate(streakProvider);
            },
          ),
        ),
        data: (dashboard) {
          final streak = streakState.asData?.value;
          final report = _LearningReportData.from(
            dashboard,
            streak?.currentStreak ?? 0,
            _period,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _PeriodSelector(
                selected: _period,
                onChanged: (period) => setState(() => _period = period),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: report.hasRealData
                    ? _ReportContent(key: ValueKey(_period), report: report)
                    : const _NoLearningData(key: ValueKey('empty-report')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({super.key, required this.report});

  final _LearningReportData report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TodaySummaryCard(report: report),
        const SizedBox(height: 12),
        _HeatmapCard(report: report),
        const SizedBox(height: 12),
        _ChartsCard(report: report),
        const SizedBox(height: 12),
        _MemoryReportCard(report: report),
        const SizedBox(height: 12),
        _AiLearningAnalysisCard(report: report),
      ],
    );
  }
}

class _NoLearningData extends StatelessWidget {
  const _NoLearningData({super.key});

  @override
  Widget build(BuildContext context) {
    return const MameroomEmptyState(
      title:
          '\uCCAB \uD559\uC2B5\uC744 \uC2DC\uC791\uD558\uBA74 \uD1B5\uACC4\uAC00 \uC0DD\uC131\uB429\uB2C8\uB2E4.',
      description:
          '\uBB38\uC81C\uB97C \uD480\uACE0 \uBCF5\uC2B5\uD558\uBA74 \uAE30\uC5B5\uB960, \uD480\uC774\uB7C9, \uD559\uC2B5 \uB9AC\uB4EC\uC744 \uD55C\uB208\uC5D0 \uBCFC \uC218 \uC788\uC5B4\uC694.',
      icon: MameroomStatePixelIcon.book,
      size: MameroomStateSize.full,
    );
  }
}

class _LearningReportData {
  const _LearningReportData({
    required this.period,
    required this.metric,
    required this.hasRealData,
    required this.memoryRate,
    required this.currentStreak,
    required this.totalQuestions,
    required this.completedQuestions,
    required this.materials,
    required this.heatmapValues,
  });

  final LearningReportPeriod period;
  final _PeriodMetric metric;
  final bool hasRealData;
  final int memoryRate;
  final int currentStreak;
  final int totalQuestions;
  final int completedQuestions;
  final List<StudyMaterial> materials;
  final List<int> heatmapValues;

  int get remainingQuestions => math.max(
    metric.scheduledReviewQuestions,
    totalQuestions - completedQuestions,
  );

  double get completionRatio {
    if (totalQuestions <= 0) return 0.72;
    return (completedQuestions / totalQuestions).clamp(0.0, 1.0).toDouble();
  }

  StudyMaterial? get weakestMaterial {
    final candidates = materials.where((m) => m.memoryPercent > 0).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.memoryPercent.compareTo(b.memoryPercent));
    return candidates.first;
  }

  StudyMaterial? get bestMaterial {
    final candidates = materials.where((m) => m.memoryPercent > 0).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.memoryPercent.compareTo(a.memoryPercent));
    return candidates.first;
  }

  String get weakestTitle =>
      weakestMaterial?.title ?? '\uBCF4\uD5D8\uACC4\uB9AC \uAC1C\uB150';

  String get bestTitle =>
      bestMaterial?.title ?? 'IFRS17 \uD575\uC2EC \uAC1C\uB150';

  List<String> get chartLabels {
    return switch (period) {
      LearningReportPeriod.today => const ['9', '11', '13', '15', '17', '19'],
      LearningReportPeriod.weekly => const [
        '\uC6D4',
        '\uD654',
        '\uC218',
        '\uBAA9',
        '\uAE08',
        '\uD1A0',
        '\uC77C',
      ],
      LearningReportPeriod.monthly => const [
        '1\uC8FC',
        '2\uC8FC',
        '3\uC8FC',
        '4\uC8FC',
      ],
      LearningReportPeriod.all => const [
        '1\uC6D4',
        '2\uC6D4',
        '3\uC6D4',
        '4\uC6D4',
        '5\uC6D4',
        '6\uC6D4',
      ],
    };
  }

  static _LearningReportData from(
    LibraryDashboard dashboard,
    int currentStreak,
    LearningReportPeriod period,
  ) {
    final totalQuestions = dashboard.materials.fold<int>(
      0,
      (sum, material) => sum + material.totalQuestionCount,
    );
    final completedQuestions = dashboard.materials.fold<int>(
      0,
      (sum, material) => sum + material.completedQuestionCount,
    );
    final hasRealData =
        dashboard.materials.isNotEmpty ||
        dashboard.todayReviewCount > 0 ||
        dashboard.recentRecords.isNotEmpty ||
        dashboard.totalMemoryPercent > 0;
    final metric = _MockLearningReport.metricFor(period);
    final memoryRate = dashboard.totalMemoryPercent > 0
        ? dashboard.totalMemoryPercent
        : metric.memoryRate;
    final safeStreak = currentStreak > 0 ? currentStreak : metric.currentStreak;
    return _LearningReportData(
      period: period,
      metric: metric,
      hasRealData: hasRealData,
      memoryRate: memoryRate,
      currentStreak: safeStreak,
      totalQuestions: totalQuestions == 0
          ? metric.totalQuestions
          : totalQuestions,
      completedQuestions: completedQuestions == 0
          ? metric.completedQuestions
          : completedQuestions,
      materials: dashboard.materials,
      heatmapValues: hasRealData
          ? _MockLearningReport.heatmap
          : List<int>.filled(28, 0),
    );
  }
}

class _PeriodMetric {
  const _PeriodMetric({
    required this.studyMinutes,
    required this.solvedQuestions,
    required this.reviewCompleted,
    required this.memoryRate,
    required this.accuracyRate,
    required this.memoryDelta,
    required this.scheduledReviewQuestions,
    required this.currentStreak,
    required this.todayCoin,
    required this.studyTimeBars,
    required this.questionBars,
    required this.totalQuestions,
    required this.completedQuestions,
  });

  final int studyMinutes;
  final int solvedQuestions;
  final int reviewCompleted;
  final int memoryRate;
  final int accuracyRate;
  final int memoryDelta;
  final int scheduledReviewQuestions;
  final int currentStreak;
  final int todayCoin;
  final List<int> studyTimeBars;
  final List<int> questionBars;
  final int totalQuestions;
  final int completedQuestions;
}

class _MockLearningReport {
  static const heatmap = <int>[
    0,
    1,
    2,
    3,
    2,
    0,
    4,
    1,
    2,
    2,
    4,
    3,
    1,
    0,
    0,
    1,
    3,
    4,
    2,
    2,
    1,
    2,
    3,
    4,
    4,
    3,
    2,
    1,
  ];

  static _PeriodMetric metricFor(LearningReportPeriod period) {
    return switch (period) {
      LearningReportPeriod.today => const _PeriodMetric(
        studyMinutes: 42,
        solvedQuestions: 68,
        reviewCompleted: 21,
        memoryRate: 84,
        accuracyRate: 86,
        memoryDelta: 5,
        scheduledReviewQuestions: 17,
        currentStreak: 7,
        todayCoin: 40,
        studyTimeBars: [4, 7, 0, 12, 8, 11],
        questionBars: [8, 12, 0, 18, 14, 16],
        totalQuestions: 120,
        completedQuestions: 86,
      ),
      LearningReportPeriod.weekly => const _PeriodMetric(
        studyMinutes: 238,
        solvedQuestions: 312,
        reviewCompleted: 96,
        memoryRate: 84,
        accuracyRate: 88,
        memoryDelta: 5,
        scheduledReviewQuestions: 24,
        currentStreak: 7,
        todayCoin: 40,
        studyTimeBars: [28, 36, 21, 42, 38, 31, 42],
        questionBars: [44, 51, 36, 58, 49, 38, 68],
        totalQuestions: 420,
        completedQuestions: 312,
      ),
      LearningReportPeriod.monthly => const _PeriodMetric(
        studyMinutes: 940,
        solvedQuestions: 1248,
        reviewCompleted: 382,
        memoryRate: 86,
        accuracyRate: 89,
        memoryDelta: 8,
        scheduledReviewQuestions: 52,
        currentStreak: 24,
        todayCoin: 40,
        studyTimeBars: [188, 226, 244, 282],
        questionBars: [268, 304, 322, 354],
        totalQuestions: 1600,
        completedQuestions: 1248,
      ),
      LearningReportPeriod.all => const _PeriodMetric(
        studyMinutes: 3260,
        solvedQuestions: 4320,
        reviewCompleted: 1412,
        memoryRate: 87,
        accuracyRate: 90,
        memoryDelta: 12,
        scheduledReviewQuestions: 73,
        currentStreak: 24,
        todayCoin: 40,
        studyTimeBars: [420, 510, 486, 598, 604, 642],
        questionBars: [580, 690, 644, 782, 794, 830],
        totalQuestions: 5200,
        completedQuestions: 4320,
      ),
    };
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final LearningReportPeriod selected;
  final ValueChanged<LearningReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<LearningReportPeriod>(
      segments: [
        for (final period in LearningReportPeriod.values)
          ButtonSegment(value: period, label: Text(period.label)),
      ],
      selected: {selected},
      onSelectionChanged: (value) => onChanged(value.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.report});

  final _LearningReportData report;

  @override
  Widget build(BuildContext context) {
    final metric = report.metric;
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: '\uC624\uB298 \uC694\uC57D',
            icon: Icons.today_rounded,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.35,
            children: [
              _SummaryTile(
                label: '\uD559\uC2B5 \uC2DC\uAC04',
                value: '${metric.studyMinutes}\uBD84',
              ),
              _SummaryTile(
                label: '\uD480\uC774 \uBB38\uC81C',
                value: '${metric.solvedQuestions}\uBB38\uC81C',
              ),
              _SummaryTile(
                label: '\uBCF5\uC2B5 \uC644\uB8CC',
                value: '${metric.reviewCompleted}\uBB38\uC81C',
              ),
              _SummaryTile(
                label: '\uAE30\uC5B5\uB960',
                value: '${report.memoryRate}%',
              ),
              _SummaryTile(
                label: '\uC5F0\uC18D \uD559\uC2B5',
                value: '${report.currentStreak}\uC77C',
              ),
              _SummaryTile(
                label: '\uC624\uB298 \uD68D\uB4DD M-Coin',
                value: '+${metric.todayCoin}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.report});

  final _LearningReportData report;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: '\uD559\uC2B5 \uD788\uD2B8\uB9F5',
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in report.heatmapValues) _HeatCell(level: value),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '\uC801\uC74C',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              for (var level = 0; level <= 4; level++) ...[
                _HeatCell(level: level, size: 13),
                const SizedBox(width: 4),
              ],
              Text(
                '\uB9CE\uC74C',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartsCard extends StatelessWidget {
  const _ChartsCard({required this.report});

  final _LearningReportData report;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        children: [
          _BarChartSection(
            title: '\uD559\uC2B5 \uC2DC\uAC04',
            unit: '\uBD84',
            values: report.metric.studyTimeBars,
            labels: report.chartLabels,
            emptyMessage:
                '\uD559\uC2B5 \uB370\uC774\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
            icon: Icons.timer_rounded,
          ),
          const SizedBox(height: 18),
          _BarChartSection(
            title: '\uBB38\uC81C \uD480\uC774\uB7C9',
            unit: '\uBB38\uC81C',
            values: report.metric.questionBars,
            labels: report.chartLabels,
            emptyMessage:
                '\uBB38\uC81C \uD480\uC774 \uAE30\uB85D\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
            icon: Icons.quiz_rounded,
          ),
        ],
      ),
    );
  }
}

class _MemoryReportCard extends StatelessWidget {
  const _MemoryReportCard({required this.report});

  final _LearningReportData report;

  @override
  Widget build(BuildContext context) {
    final delta = report.metric.memoryDelta;
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: '\uAE30\uC5B5 \uB9AC\uD3EC\uD2B8',
            icon: Icons.psychology_rounded,
          ),
          const SizedBox(height: 12),
          _MemoryRateHeader(
            rate: report.memoryRate,
            ratio: report.completionRatio,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: '\uC774\uC804 \uAE30\uAC04 \uB300\uBE44',
            value: _signedPercent(delta),
            valueColor: delta >= 0
                ? const Color(0xFF6FBD83)
                : const Color(0xFFFF6B6B),
          ),
          _InfoRow(
            label: '\uBCF5\uC2B5 \uC131\uACF5\uB960',
            value: '${report.metric.accuracyRate}%',
          ),
          _InfoRow(
            label: '\uC608\uC815 \uBCF5\uC2B5 \uBB38\uC81C',
            value: '${report.remainingQuestions}\uBB38\uC81C',
          ),
          _InfoRow(
            label: '\uAC00\uC7A5 \uC57D\uD55C \uC790\uB8CC',
            value: report.weakestTitle,
          ),
          _InfoRow(
            label: '\uAC00\uC7A5 \uC798 \uAE30\uC5B5\uD558\uB294 \uC790\uB8CC',
            value: report.bestTitle,
          ),
        ],
      ),
    );
  }
}

class _AiLearningAnalysisCard extends StatelessWidget {
  const _AiLearningAnalysisCard({required this.report});

  final _LearningReportData report;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final delta = report.metric.memoryDelta;
    final lead = delta >= 0
        ? '\uCD5C\uADFC \uAE30\uC5B5\uB960\uC774 $delta% \uC0C1\uC2B9\uD588\uC2B5\uB2C8\uB2E4.'
        : '\uCD5C\uADFC \uAE30\uC5B5\uB960\uC774 ${delta.abs()}% \uB0AE\uC544\uC84C\uC2B5\uB2C8\uB2E4.';
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'AI \uD559\uC2B5 \uBD84\uC11D',
            icon: Icons.smart_toy_rounded,
          ),
          const SizedBox(height: 10),
          Text(
            lead,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${report.weakestTitle}\uC758 \uBCF5\uC2B5 \uC608\uC815 \uBB38\uC81C\uAC00 \uB0A8\uC544 \uC788\uC5B4\uC694. \uC624\uB298\uC740 \uC544\uB798 \uC21C\uC11C\uB85C \uD559\uC2B5\uD558\uB294 \uAC83\uC744 \uCD94\uCC9C\uD569\uB2C8\uB2E4.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          const _RecommendationStep(
            index: 1,
            text: '\uBCF4\uD5D8\uACC4\uB9AC \uBCF5\uC2B5',
          ),
          const _RecommendationStep(index: 2, text: '\uC624\uB2F5\uB178\uD2B8'),
          const _RecommendationStep(
            index: 3,
            text: '\uCD5C\uADFC \uBB38\uC81C \uC774\uC5B4\uD480\uAE30',
          ),
        ],
      ),
    );
  }
}

class _RecommendationStep extends StatelessWidget {
  const _RecommendationStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: colors.primary,
            child: Text(
              index.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartSection extends StatelessWidget {
  const _BarChartSection({
    required this.title,
    required this.unit,
    required this.values,
    required this.labels,
    required this.emptyMessage,
    required this.icon,
  });

  final String title;
  final String unit;
  final List<int> values;
  final List<String> labels;
  final String emptyMessage;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(0, math.max);
    final colors = context.mameroom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, icon: icon),
        const SizedBox(height: 10),
        if (maxValue == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: colors.primaryMist.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        else
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: (values[i] / maxValue)
                                  .clamp(0.08, 1.0)
                                  .toDouble(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          i < labels.length ? labels[i] : '',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.muted,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (i != values.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          '\uB2E8\uC704: $unit',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MemoryRateHeader extends StatelessWidget {
  const _MemoryRateHeader({required this.rate, required this.ratio});

  final int rate;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryMist.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\uD604\uC7AC \uAE30\uC5B5\uB960',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$rate%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 112,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: colors.paper,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.level, this.size = 24});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final safeLevel = level.clamp(0, 4);
    final color = safeLevel == 0
        ? const Color(0xFFE8E6F4)
        : Color.lerp(
            colors.primaryMist,
            colors.primary,
            0.18 + (safeLevel * 0.18),
          )!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: colors.line),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryMist.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(18),
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

String _signedPercent(int value) {
  if (value == 0) return '0%';
  final arrow = value > 0 ? '\u25B2 +' : '\u25BC -';
  return '$arrow${value.abs()}%';
}
