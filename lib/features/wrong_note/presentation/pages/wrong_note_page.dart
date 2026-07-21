import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../review/presentation/pages/review_page.dart';
import '../../domain/entities/wrong_note.dart';
import '../providers/wrong_note_providers.dart';

class WrongNotePage extends ConsumerStatefulWidget {
  const WrongNotePage({super.key});
  static const routePath = '/wrong-notes';
  @override
  ConsumerState<WrongNotePage> createState() => _WrongNotePageState();
}

class _WrongNotePageState extends ConsumerState<WrongNotePage> {
  WrongNoteFilter filter = WrongNoteFilter.all;
  WrongNoteSort sort = WrongNoteSort.recent;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wrongNotesProvider);
    return MameroomShell(
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Column(
          children: [
            _Header(onSearch: (value) => setState(() => query = value)),
            Expanded(
              child: state.when(
                loading: () =>
                    const Center(child: MameroomLoadingListSkeleton()),
                error: (_, _) => _Message(
                  icon: Icons.error_outline_rounded,
                  title: '오답노트를 불러오지 못했습니다.',
                  description: '잠시 후 다시 시도해주세요.',
                  action: '다시 시도',
                  onPressed: () => ref.invalidate(wrongNotesProvider),
                ),
                data: _content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(List<WrongNote> all) {
    if (all.isEmpty) {
      return _Message(
        icon: Icons.assignment_turned_in_outlined,
        title: '아직 오답이 없어요!',
        description: '문제를 틀리거나 PASS하면 오답노트에서 다시 확인할 수 있습니다.',
        action: '공부 시작하기',
        onPressed: () => Navigator.of(context).maybePop(),
      );
    }
    var items = all.where(_matches).toList();
    items.sort(_compare);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    MameroomSpacing.md,
                    MameroomSpacing.xs,
                    MameroomSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(child: _Summary(items: all)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(MameroomSpacing.md),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: WrongNoteFilter.values
                                .map(
                                  (value) => Padding(
                                    padding: const EdgeInsets.only(
                                      right: MameroomSpacing.xs,
                                    ),
                                    child: MameroomFilterChip(
                                      label: _filterLabel(value),
                                      selected: filter == value,
                                      onSelected: (_) =>
                                          setState(() => filter = value),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: MameroomSpacing.sm),
                        DropdownButtonFormField<WrongNoteSort>(
                          initialValue: sort,
                          decoration: const InputDecoration(labelText: '정렬'),
                          items: WrongNoteSort.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(_sortLabel(value)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => sort = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      icon: Icons.filter_alt_off,
                      title: '조건에 맞는 오답이 없어요.',
                      description: '다른 필터나 검색어를 선택해보세요.',
                      action: '필터 초기화',
                      onPressed: () => setState(() {
                        filter = WrongNoteFilter.all;
                        query = '';
                      }),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      MameroomSpacing.md,
                      0,
                      MameroomSpacing.md,
                      MameroomSpacing.lg,
                    ),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: MameroomSpacing.sm),
                      itemBuilder: (_, index) =>
                          _WrongNoteCard(note: items[index]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _matches(WrongNote note) {
    final textMatch =
        query.trim().isEmpty ||
        note.questionText.toLowerCase().contains(query.trim().toLowerCase()) ||
        note.materialName.toLowerCase().contains(query.trim().toLowerCase());
    final today = DateUtils.isSameDay(note.lastWrongAt, DateTime.now());
    final filterMatch = switch (filter) {
      WrongNoteFilter.all => true,
      WrongNoteFilter.today => today,
      WrongNoteFilter.repeated => note.wrongCount >= 3,
      WrongNoteFilter.passed => note.status == WrongNoteStatus.passed,
      WrongNoteFilter.bookmarked => note.isBookmarked,
      WrongNoteFilter.lowMemory => note.memoryRate <= .3,
    };
    return textMatch && filterMatch;
  }

  int _compare(WrongNote a, WrongNote b) => switch (sort) {
    WrongNoteSort.recent => b.lastWrongAt.compareTo(a.lastWrongAt),
    WrongNoteSort.wrongCount => b.wrongCount.compareTo(a.wrongCount),
    WrongNoteSort.lowMemory => a.memoryRate.compareTo(b.memoryRate),
    WrongNoteSort.nextReview => (a.nextReviewAt ?? DateTime(9999)).compareTo(
      b.nextReviewAt ?? DateTime(9999),
    ),
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch});
  final ValueChanged<String> onSearch;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(MameroomSpacing.sm),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Text(
            '오답노트',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          onPressed: () async {
            final value = await showSearch<String?>(
              context: context,
              delegate: _WrongNoteSearch(),
            );
            if (value != null) onSearch(value);
          },
          icon: const Icon(Icons.search_rounded),
          tooltip: '검색',
        ),
        const SizedBox(width: MameroomSpacing.xxs),
      ],
    ),
  );
}

class _WrongNoteSearch extends SearchDelegate<String?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );
  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) =>
      const Center(child: Text('문제 또는 자료명을 검색하세요.'));
}

class _Summary extends StatelessWidget {
  const _Summary({required this.items});
  final List<WrongNote> items;
  @override
  Widget build(BuildContext context) => MameroomCard(
    child: Wrap(
      spacing: MameroomSpacing.lg,
      runSpacing: MameroomSpacing.sm,
      children: [
        _metric('전체 오답', items.length),
        _metric('반복 오답', items.where((e) => e.wrongCount >= 3).length),
        _metric(
          '오늘 추가',
          items
              .where((e) => DateUtils.isSameDay(e.lastWrongAt, DateTime.now()))
              .length,
        ),
        _metric('복습 필요', items.where((e) => e.memoryRate <= .3).length),
      ],
    ),
  );
  Widget _metric(String label, int value) => SizedBox(
    width: 120,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Text('$value', style: MameroomTypography.titleLarge),
      ],
    ),
  );
}

class _WrongNoteCard extends StatelessWidget {
  const _WrongNoteCard({required this.note});
  final WrongNote note;
  @override
  Widget build(BuildContext context) => MameroomCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                note.questionText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              note.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: MameroomColors.primary,
            ),
          ],
        ),
        const SizedBox(height: MameroomSpacing.xs),
        Text(note.materialName, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: MameroomSpacing.sm),
        Wrap(
          spacing: MameroomSpacing.xs,
          runSpacing: MameroomSpacing.xs,
          children: [
            MameroomStatusBadge(
              label: _statusLabel(note.status),
              variant: note.status == WrongNoteStatus.repeated
                  ? MameroomBadgeVariant.error
                  : MameroomBadgeVariant.warning,
            ),
            MameroomStatusBadge(label: '오답 ${note.wrongCount}회'),
            MameroomStatusBadge(
              label: '기억률 ${(note.memoryRate * 100).round()}%',
              variant: note.memoryRate <= .3
                  ? MameroomBadgeVariant.error
                  : MameroomBadgeVariant.info,
            ),
          ],
        ),
        const SizedBox(height: MameroomSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonal(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReviewPage())),
            child: const Text('복습하기'),
          ),
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onPressed,
  });
  final IconData icon;
  final String title, description, action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(MameroomSpacing.lg),
      child: MameroomCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: MameroomIconSizes.xl,
              color: MameroomColors.primary,
            ),
            const SizedBox(height: MameroomSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: MameroomSpacing.xs),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: MameroomSpacing.md),
            FilledButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    ),
  );
}

String _filterLabel(WrongNoteFilter value) => switch (value) {
  WrongNoteFilter.all => '전체',
  WrongNoteFilter.today => '오늘 틀림',
  WrongNoteFilter.repeated => '반복 오답',
  WrongNoteFilter.passed => 'PASS',
  WrongNoteFilter.bookmarked => '북마크',
  WrongNoteFilter.lowMemory => '기억률 낮음',
};
String _sortLabel(WrongNoteSort value) => switch (value) {
  WrongNoteSort.recent => '최근 틀린 순',
  WrongNoteSort.wrongCount => '오답 횟수 순',
  WrongNoteSort.lowMemory => '기억률 낮은 순',
  WrongNoteSort.nextReview => '복습 예정일 순',
};
String _statusLabel(WrongNoteStatus value) => switch (value) {
  WrongNoteStatus.wrong => '오답',
  WrongNoteStatus.repeated => '반복 오답',
  WrongNoteStatus.passed => 'PASS',
  WrongNoteStatus.reviewed => '복습 완료',
};
