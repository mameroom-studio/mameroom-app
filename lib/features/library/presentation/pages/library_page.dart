import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/states/mameroom_states.dart';
import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../quiz/presentation/pages/quiz_page.dart';
import '../../../review/presentation/pages/review_page.dart';
import '../../../wrong_note/presentation/pages/wrong_note_page.dart';
import '../../../notifications/presentation/widgets/mameroom_notification_icon.dart';
import '../../../upload/presentation/pages/upload_page.dart';
import '../../domain/entities/study_material.dart';
import '../../domain/entities/material_list_query.dart';
import '../widgets/material_search_sort.dart';
import '../providers/library_mock_providers.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  static const routePath = '/library';

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final Set<String> _hiddenMaterialIds = <String>{};
  final Set<String> _deletingMaterialIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  MaterialListQuery _materialQuery = const MaterialListQuery();
  bool _searchActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(libraryDashboardProvider);
    final colors = context.mameroom;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.paper, colors.primaryMist.withValues(alpha: 0.14)],
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: dashboardState.when(
          loading: () => Center(child: MameroomLoadingState.studyMaterials()),
          error: (error, _) => MameroomErrorState.network(
            onRetry: () => ref.invalidate(libraryDashboardProvider),
          ),
          data: (dashboard) => _StudyDashboard(
            dashboard: dashboard,
            hiddenMaterialIds: _hiddenMaterialIds,
            deletingMaterialIds: _deletingMaterialIds,
            onUpload: () => _showUploadMethodSheet(context),
            onReview: () => context.push(ReviewPage.routePath),
            onWrongNote: () => context.push(WrongNotePage.routePath),
            searchActive: _searchActive,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            materialQuery: _materialQuery,
            onSearch: _activateSearch,
            onSearchChanged: (value) => setState(() {
              _materialQuery = _materialQuery.copyWith(searchQuery: value);
            }),
            onSearchClear: _clearSearch,
            onSearchExit: _exitSearch,
            onSort: _showSortSheet,
            onDeleteMaterial: _confirmAndDeleteMaterial,
            onOpenMaterial: (material) {
              if (material.canStartQuiz) {
                context.push('${QuizPage.routePath}?materialId=${material.id}');
              } else {
                _showComingSoon(context, _statusLabel(material.status));
              }
            },
            onContinue: () {
              final playable = _firstPlayableMaterial(dashboard.materials);
              if (playable == null) {
                _showComingSoon(context, _continueStudy);
                return;
              }
              context.push('${QuizPage.routePath}?materialId=${playable.id}');
            },
          ),
        ),
      ),
    );
  }

  void _activateSearch() {
    setState(() => _searchActive = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _materialQuery = _materialQuery.copyWith(searchQuery: ''));
    _searchFocusNode.requestFocus();
  }

  void _exitSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchActive = false;
      _materialQuery = _materialQuery.copyWith(searchQuery: '');
    });
  }

  Future<void> _showSortSheet() async {
    final selected = await showMaterialSortSheet(
      context: context,
      current: _materialQuery.sortOption,
    );
    if (selected == null || !mounted) return;
    setState(
      () => _materialQuery = _materialQuery.copyWith(sortOption: selected),
    );
  }

  Future<void> _confirmAndDeleteMaterial(StudyMaterial material) async {
    if (_deletingMaterialIds.contains(material.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.mameroom;
        return AlertDialog(
          title: const Text(_deleteDialogTitle),
          content: const Text(_deleteDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: MameroomColors.white,
              ),
              child: const Text(_delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingMaterialIds.add(material.id));
    try {
      await ref.read(deleteStudyMaterialProvider)(material);
      if (!mounted) return;
      setState(() => _hiddenMaterialIds.add(material.id));
      ref.invalidate(libraryDashboardProvider);
      _showSnack(_deleteSuccess);
    } catch (error, stackTrace) {
      debugPrint('Failed to delete study material: $error\n$stackTrace');
      if (!mounted) return;
      _showSnack(_deleteFailure);
    } finally {
      if (mounted) {
        setState(() => _deletingMaterialIds.remove(material.id));
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  StudyMaterial? _firstPlayableMaterial(List<StudyMaterial> materials) {
    for (final material in materials) {
      if (material.canStartQuiz) return material;
    }
    return null;
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label $_comingSoon')));
  }

  Future<void> _showUploadMethodSheet(BuildContext context) async {
    final mode = await showModalBottomSheet<MaterialInputMode>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.mameroom.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MameroomRadius.card + 2),
        ),
      ),
      builder: (sheetContext) => _UploadMethodSheet(
        onSelected: (value) => Navigator.of(sheetContext).pop(value),
      ),
    );
    if (mode == null || !context.mounted) return;
    await context.push('${UploadPage.routePath}?source=${mode.value}');
  }
}

class _StudyDashboard extends StatelessWidget {
  const _StudyDashboard({
    required this.dashboard,
    required this.hiddenMaterialIds,
    required this.deletingMaterialIds,
    required this.onUpload,
    required this.onReview,
    required this.onWrongNote,
    required this.onContinue,
    required this.searchActive,
    required this.searchController,
    required this.searchFocusNode,
    required this.materialQuery,
    required this.onSearch,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onSearchExit,
    required this.onSort,
    required this.onDeleteMaterial,
    required this.onOpenMaterial,
  });

  final LibraryDashboard dashboard;
  final Set<String> hiddenMaterialIds;
  final Set<String> deletingMaterialIds;
  final VoidCallback onUpload;
  final VoidCallback onReview;
  final VoidCallback onWrongNote;
  final VoidCallback onContinue;
  final bool searchActive;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final MaterialListQuery materialQuery;
  final VoidCallback onSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onSearchExit;
  final VoidCallback onSort;
  final ValueChanged<StudyMaterial> onDeleteMaterial;
  final ValueChanged<StudyMaterial> onOpenMaterial;

  @override
  Widget build(BuildContext context) {
    final allMaterials = dashboard.materials
        .where((material) => !hiddenMaterialIds.contains(material.id))
        .toList(growable: false);
    final materials = materialQuery.apply(allMaterials);
    final hasMaterials = allMaterials.isNotEmpty;
    final lowQuestion = materials.any(_hasLowQuestionQuota);
    final reviewCount = hasMaterials
        ? math.max(17, dashboard.todayReviewCount)
        : 0;
    final goalTotal = hasMaterials ? math.max(20, reviewCount + 3) : 20;
    final remaining = math.max(0, goalTotal - reviewCount);
    final memoryPercent = hasMaterials
        ? math.max(
            1,
            dashboard.totalMemoryPercent == 0
                ? 84
                : dashboard.totalMemoryPercent,
          )
        : 0;
    final progress = goalTotal == 0
        ? 0.0
        : (reviewCount / goalTotal).clamp(0.0, 1.0).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _StudyMetrics.from(constraints);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.sidePadding,
                metrics.topPadding,
                metrics.sidePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: metrics.headerHeight,
                    child: searchActive
                        ? MaterialSearchBar(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            onChanged: onSearchChanged,
                            onExit: onSearchExit,
                            onClear: onSearchClear,
                          )
                        : _StudyHeader(
                            dense: metrics.dense,
                            sortOption: materialQuery.sortOption,
                            onSearch: onSearch,
                            onSort: onSort,
                          ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      key: const ValueKey('study-scroll'),
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizedBox(height: metrics.gap),
                        ),
                        SliverToBoxAdapter(
                          child: _QuickActions(
                            dense: metrics.dense,
                            onUpload: onUpload,
                            onReview: onReview,
                            onWrongNote: onWrongNote,
                            onContinue: onContinue,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: metrics.largeGap),
                        ),
                        if (lowQuestion)
                          SliverToBoxAdapter(
                            child: _LowQuestionBanner(dense: metrics.dense),
                          ),
                        if (lowQuestion)
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.gap),
                          ),
                        if (hasMaterials)
                          SliverToBoxAdapter(
                            child: _TodaySummaryCard(
                              reviewCount: reviewCount,
                              remainingCount: remaining,
                              memoryPercent: memoryPercent,
                              progress: progress,
                              latestMaterial: allMaterials.first,
                              dense: metrics.dense,
                              onStart: onReview,
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: metrics.largeGap,
                                bottom: metrics.bottomSpace,
                              ),
                              child: MameroomEmptyState.studyMaterials(
                                onUpload: onUpload,
                                size: metrics.dense
                                    ? MameroomStateSize.compact
                                    : MameroomStateSize.medium,
                              ),
                            ),
                          ),
                        if (hasMaterials) ...[
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.largeGap),
                          ),
                          SliverToBoxAdapter(
                            child: _SectionTitle(
                              title: _myMaterials,
                              dense: metrics.dense,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.gap),
                          ),
                          if (materials.isEmpty)
                            const SliverToBoxAdapter(
                              child: _SearchEmptyState(),
                            ),
                          SliverList.separated(
                            itemCount: materials.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: metrics.gap),
                            itemBuilder: (context, index) {
                              final material = materials[index];
                              return _MaterialCard(
                                key: ValueKey('material-card-${material.id}'),
                                material: material,
                                dense: metrics.dense,
                                isDeleting: deletingMaterialIds.contains(
                                  material.id,
                                ),
                                onTap: () => onOpenMaterial(material),
                                onDelete: () => onDeleteMaterial(material),
                              );
                            },
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.largeGap),
                          ),
                          SliverToBoxAdapter(
                            child: _QuotaBanner(dense: metrics.dense),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.bottomSpace),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _hasLowQuestionQuota(StudyMaterial material) {
    if (material.status == 'insufficient_questions') return true;
    return material.totalQuestionCount > 0 && material.totalQuestionCount < 50;
  }
}

class _StudyMetrics {
  const _StudyMetrics({
    required this.dense,
    required this.sidePadding,
    required this.topPadding,
    required this.headerHeight,
    required this.gap,
    required this.largeGap,
    required this.bottomSpace,
  });

  final bool dense;
  final double sidePadding;
  final double topPadding;
  final double headerHeight;
  final double gap;
  final double largeGap;
  final double bottomSpace;

  static _StudyMetrics from(BoxConstraints constraints) {
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 390.0;
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : 760.0;
    final dense = width < 380 || height < 720;
    return _StudyMetrics(
      dense: dense,
      sidePadding: width < 380 ? 14 : 20,
      topPadding: dense ? 8 : 12,
      headerHeight: dense ? 42 : 50,
      gap: dense ? 8 : 10,
      largeGap: dense ? 12 : 14,
      bottomSpace: dense ? 18 : 24,
    );
  }
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.dense,
    required this.sortOption,
    required this.onSearch,
    required this.onSort,
  });

  final bool dense;
  final MaterialSortOption sortOption;
  final VoidCallback onSearch;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Expanded(
          child: Text(
            _study,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.ink,
              fontSize: dense ? 26 : 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _HeaderButton(
          tooltip: _search,
          icon: Icons.search_rounded,
          onTap: onSearch,
        ),
        SizedBox(width: dense ? 8 : 10),
        Semantics(
          button: true,
          label: '\uC790\uB8CC \uC815\uB82C, \uD604\uC7AC ',
          child: _HeaderButton(
            key: const ValueKey('material-sort-button'),
            tooltip: '\uC815\uB82C',
            icon: Icons.tune_rounded,
            onTap: onSort,
          ),
        ),
        SizedBox(width: dense ? 8 : 10),
        MameroomNotificationIcon(
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const MameroomStateView(
      variant: MameroomStateVariant.search,
      title: '\uCC3E\uB294 \uC790\uB8CC\uAC00 \uC5C6\uC5B4\uC694.',
      description:
          '\uB2E4\uB978 \uAC80\uC0C9\uC5B4\uB97C \uC785\uB825\uD574\uBCF4\uC138\uC694.',
      pixelIcon: MameroomStatePixelIcon.search,
      size: MameroomStateSize.compact,
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.dense,
    required this.onUpload,
    required this.onReview,
    required this.onWrongNote,
    required this.onContinue,
  });

  final bool dense;
  final VoidCallback onUpload;
  final VoidCallback onReview;
  final VoidCallback onWrongNote;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final scaledLabelHeight = MediaQuery.textScalerOf(context).scale(10);
    return SizedBox(
      height: (dense ? 76 : 84) + (scaledLabelHeight > 13 ? 14 : 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickCard(
              icon: Icons.upload_file_rounded,
              label: _newUpload,
              dense: dense,
              onTap: onUpload,
            ),
          ),
          SizedBox(width: dense ? 7 : 8),
          Expanded(
            child: _QuickCard(
              icon: Icons.menu_book_rounded,
              label: _review,
              dense: dense,
              onTap: onReview,
            ),
          ),
          SizedBox(width: dense ? 7 : 8),
          Expanded(
            child: _QuickCard(
              icon: Icons.assignment_late_outlined,
              label: _wrongNote,
              dense: dense,
              onTap: onWrongNote,
            ),
          ),
          SizedBox(width: dense ? 7 : 8),
          Expanded(
            child: _QuickCard(
              icon: Icons.edit_rounded,
              label: _continueStudy,
              dense: dense,
              onTap: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.reviewCount,
    required this.remainingCount,
    required this.memoryPercent,
    required this.progress,
    required this.latestMaterial,
    required this.dense,
    required this.onStart,
  });

  final int reviewCount;
  final int remainingCount;
  final int memoryPercent;
  final double progress;
  final StudyMaterial latestMaterial;
  final bool dense;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _BoardCard(
      padding: EdgeInsets.all(dense ? 14 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _todaySummary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontSize: dense ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: dense ? 10 : 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: _reviewQuestions,
                  value: reviewCount.toString(),
                  suffix: _countUnit,
                  dense: dense,
                ),
              ),
              _DividerLine(dense: dense),
              Expanded(
                child: _Metric(
                  label: _remainingQuestions,
                  value: remainingCount.toString(),
                  suffix: _countUnit,
                  dense: dense,
                ),
              ),
              _DividerLine(dense: dense),
              Expanded(
                child: _MemoryMetric(
                  memoryPercent: memoryPercent,
                  dense: dense,
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 10 : 12),
          Text(
            _recentMaterial,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                color: colors.ink,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  latestMaterial.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${latestMaterial.memoryPercent}%  \u{00B7}  ${latestMaterial.recentStudyLabel}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 8 : 10),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(MameroomRadius.pill),
                  backgroundColor: colors.primaryMist.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 8 : 10),
          SizedBox(
            height: dense ? 42 : 46,
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _startStudy,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MameroomColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: MameroomSpacing.xs),
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

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    super.key,
    required this.material,
    required this.dense,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  final StudyMaterial material;
  final bool dense;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final statusColor = _statusColor(colors, material.status);
    return _BoardCard(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 14,
        vertical: dense ? 10 : 12,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(MameroomRadius.large),
        onTap: onTap,
        child: Row(
          children: [
            _FileBadge(color: statusColor, dense: dense),
            SizedBox(width: dense ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          material.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      _StatusBadge(
                        label: _statusLabel(material.status),
                        color: statusColor,
                        dense: dense,
                      ),
                    ],
                  ),
                  SizedBox(height: dense ? 4 : 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      _TinyInfo(
                        label: _questionCount(material.totalQuestionCount),
                      ),
                      _TinyInfo(label: '${material.memoryPercent}%'),
                      _TinyInfo(label: material.recentStudyLabel),
                    ],
                  ),
                  SizedBox(height: dense ? 6 : 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (material.progressPercent / 100)
                              .clamp(0.0, 1.0)
                              .toDouble(),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(
                            MameroomRadius.pill,
                          ),
                          backgroundColor: colors.primaryMist.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${material.progressPercent}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _MaterialMoreButton(
              material: material,
              dense: dense,
              isDeleting: isDeleting,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

enum _MaterialMenuAction { delete }

class _MaterialMoreButton extends StatelessWidget {
  const _MaterialMoreButton({
    required this.material,
    required this.dense,
    required this.isDeleting,
    required this.onDelete,
  });

  final StudyMaterial material;
  final bool dense;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Semantics(
      label: '${material.title} $_materialMoreMenu',
      button: true,
      child: SizedBox.square(
        dimension: 44,
        child: isDeleting
            ? Center(
                child: SizedBox.square(
                  dimension: dense ? 18 : 20,
                  child: const CircularProgressIndicator(strokeWidth: 2.2),
                ),
              )
            : PopupMenuButton<_MaterialMenuAction>(
                tooltip: _materialMoreMenu,
                enabled: !isDeleting,
                icon: Icon(Icons.more_vert_rounded, color: colors.muted),
                onSelected: (action) {
                  switch (action) {
                    case _MaterialMenuAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<_MaterialMenuAction>(
                      value: _MaterialMenuAction.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded),
                          SizedBox(width: 8),
                          Text(_delete),
                        ],
                      ),
                    ),
                  ];
                },
              ),
      ),
    );
  }
}

class _QuotaBanner extends StatelessWidget {
  const _QuotaBanner({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: EdgeInsets.all(dense ? 12 : 14),
      decoration: BoxDecoration(
        color: colors.primaryMist.withValues(alpha: 0.58),
        border: Border.all(color: colors.primaryPale),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _quotaText,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              minimumSize: Size(dense ? 86 : 96, dense ? 34 : 38),
              padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MameroomRadius.medium),
              ),
            ),
            child: Text(_chargeQuestions),
          ),
        ],
      ),
    );
  }
}

class _LowQuestionBanner extends StatelessWidget {
  const _LowQuestionBanner({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 14,
        vertical: dense ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E3),
        border: Border.all(color: const Color(0xFFFFB45F)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE78722)),
          const SizedBox(width: MameroomSpacing.xs),
          Expanded(
            child: Text(
              _lowQuestionText,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF7A3F00),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE78722),
              side: const BorderSide(color: Color(0xFFFFB45F)),
              padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10),
              minimumSize: Size(0, dense ? 32 : 36),
            ),
            child: Text(_chargeQuestions),
          ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.dense,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Material(
      color: colors.paper,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: dense ? 3 : 5, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colors.primary, size: dense ? 30 : 34),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.ink,
                  fontSize: dense ? 10 : 11,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadMethodSheet extends StatelessWidget {
  const _UploadMethodSheet({required this.onSelected});

  final ValueChanged<MaterialInputMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          MameroomSpacing.md,
          MameroomSpacing.xxs,
          MameroomSpacing.md,
          MameroomSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '등록 방식을 선택해 주세요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.mameroom.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MameroomSpacing.sm),
            _UploadMethodTile(
              mode: MaterialInputMode.manual,
              icon: Icons.edit_note_rounded,
              description: '학습할 내용을 직접 입력해 문제를 만들어요',
              onTap: onSelected,
            ),
            _UploadMethodTile(
              mode: MaterialInputMode.txt,
              icon: Icons.description_outlined,
              description: 'TXT 파일에서 학습 내용을 가져와요',
              onTap: onSelected,
            ),
            _UploadMethodTile(
              mode: MaterialInputMode.pdf,
              icon: Icons.picture_as_pdf_outlined,
              description: '텍스트로 작성된 PDF에서 내용을 가져와요',
              onTap: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadMethodTile extends StatelessWidget {
  const _UploadMethodTile({
    required this.mode,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  final MaterialInputMode mode;
  final IconData icon;
  final String description;
  final ValueChanged<MaterialInputMode> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${mode.label}, $description',
      child: Padding(
        padding: const EdgeInsets.only(bottom: MameroomSpacing.xs),
        child: MameroomInteractiveCard(
          onTap: () => onTap(mode),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(icon, color: context.mameroom.primary, size: 28),
              ),
              const SizedBox(width: MameroomSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.mameroom.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MameroomSpacing.xxs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.mameroom.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyInfo extends StatelessWidget {
  const _TinyInfo({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.mameroom.muted,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.suffix,
    required this.dense,
  });

  final String label;
  final String value;
  final String suffix;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        RichText(
          maxLines: 1,
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colors.ink,
              fontSize: dense ? 25 : 31,
              fontWeight: FontWeight.w900,
            ),
            children: [
              TextSpan(text: value),
              TextSpan(
                text: suffix,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
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
  const _MemoryMetric({required this.memoryPercent, required this.dense});

  final int memoryPercent;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final active = ((memoryPercent.clamp(0, 100) / 100) * 5).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _memoryRate,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '$memoryPercent%',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colors.primary,
            fontSize: dense ? 25 : 31,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var index = 0; index < 5; index++)
              Container(
                width: dense ? 10 : 14,
                height: 5,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: index < active
                      ? colors.primary
                      : colors.primaryMist.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(MameroomRadius.pill),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.dense});

  final String title;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: context.mameroom.ink,
        fontSize: dense ? 16 : 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: context.mameroom.ink, size: 24),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: dense ? 42 : 48,
      margin: EdgeInsets.symmetric(horizontal: dense ? 8 : 10),
      color: context.mameroom.line,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.dense,
  });

  final String label;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 8,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(MameroomRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: dense ? 9 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FileBadge extends StatelessWidget {
  const _FileBadge({required this.color, required this.dense});

  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dense ? 38 : 42,
      height: dense ? 38 : 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MameroomRadius.medium),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(
        Icons.picture_as_pdf_rounded,
        color: color,
        size: dense ? 22 : 25,
      ),
    );
  }
}

String _questionCount(int count) => '$_question $count$_countUnit';

String _statusLabel(String status) {
  return switch (status) {
    'uploading' => _waiting,
    'parsing' || 'generating' => _generating,
    'completed' => _generated,
    'learning' => _learning,
    'done' => _done,
    'insufficient_questions' => _lowQuestions,
    'failed' => _failed,
    _ => _analyzed,
  };
}

Color _statusColor(MameroomTheme colors, String status) {
  return switch (status) {
    'completed' || 'done' => colors.seedGreen,
    'generating' || 'learning' => colors.primary,
    'insufficient_questions' || 'failed' => colors.blossom,
    'parsing' => colors.primarySoft,
    _ => colors.muted,
  };
}

const _study = '\u{ACF5}\u{BD80}';
const _search = '\u{AC80}\u{C0C9}';
const _newUpload = '\u{C0C8} \u{C790}\u{B8CC}\n\u{C5C5}\u{B85C}\u{B4DC}';
const _review = '\u{BCF5}\u{C2B5}\u{D558}\u{AE30}';
const _wrongNote = '\u{C624}\u{B2F5}\u{B178}\u{D2B8}';
const _continueStudy =
    '\u{CD5C}\u{ADFC} \u{BB38}\u{C81C}\n\u{C774}\u{C5B4}\u{D480}\u{AE30}';
const _todaySummary =
    '\u{C624}\u{B298}\u{C758} \u{D559}\u{C2B5} \u{C694}\u{C57D}';
const _reviewQuestions = '\u{BCF5}\u{C2B5}\u{D560} \u{BB38}\u{C81C}';
const _remainingQuestions = '\u{B0A8}\u{C740} \u{BB38}\u{C81C}';
const _memoryRate = '\u{AE30}\u{C5B5}\u{B960}';
const _recentMaterial = '\u{CD5C}\u{ADFC} \u{D559}\u{C2B5} \u{C790}\u{B8CC}';
const _startStudy = '\u{ACF5}\u{BD80} \u{C2DC}\u{C791}\u{D558}\u{AE30}';
const _myMaterials = '\u{B0B4} \u{D559}\u{C2B5} \u{C790}\u{B8CC}';
const _quotaText =
    '\u{BB38}\u{C81C} \u{C0DD}\u{C131} \u{AC00}\u{B2A5} \u{00B7} \u{B0A8}\u{C740} \u{C0DD}\u{C131}\u{B7C9} 30\u{AC1C}';
const _chargeQuestions = '\u{BB38}\u{C81C} \u{CDA9}\u{C804}\u{D558}\u{AE30}';
const _materialMoreMenu = '\u{C790}\u{B8CC} \u{B354}\u{BCF4}\u{AE30}';
const _delete = '\u{C0AD}\u{C81C}';
const _cancel = '\u{CDE8}\u{C18C}';
const _deleteDialogTitle =
    '\u{D559}\u{C2B5} \u{C790}\u{B8CC}\u{B97C} \u{C0AD}\u{C81C}\u{D560}\u{AE4C}\u{C694}?';
const _deleteDialogBody = '이 학습 자료와 생성된 문제가 모두 삭제됩니다. 삭제하시겠습니까?';
const _deleteSuccess = '학습 자료가 삭제되었습니다.';
const _deleteFailure = '학습 자료를 삭제하지 못했습니다.';
const _lowQuestionText = '\u{C794}\u{C5EC} \u{BB38}\u{C81C} \u{BD80}\u{C871}';
const _question = '\u{BB38}\u{C81C}';
const _countUnit = '\u{AC1C}';
const _analyzed = '\u{BD84}\u{C11D} \u{C644}\u{B8CC}';
const _generating = '\u{BB38}\u{C81C} \u{C0DD}\u{C131}\u{C911}';
const _generated = '\u{BB38}\u{C81C} \u{C0DD}\u{C131} \u{C644}\u{B8CC}';
const _learning = '\u{D559}\u{C2B5} \u{C911}';
const _done = '\u{C644}\u{B8CC}';
const _lowQuestions = '\u{C794}\u{C5EC} \u{BB38}\u{C81C} \u{BD80}\u{C871}';
const _waiting = '\u{C0DD}\u{C131} \u{B300}\u{AE30}';
const _failed = '\u{BD84}\u{C11D} \u{C2E4}\u{D328}';
const _comingSoon =
    '\u{AE30}\u{B2A5}\u{C740} \u{C900}\u{BE44} \u{C911}\u{C785}\u{B2C8}\u{B2E4}.';
