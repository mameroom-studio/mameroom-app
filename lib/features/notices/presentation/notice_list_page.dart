import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/states/mameroom_empty_state.dart';
import '../../../core/presentation/states/mameroom_error_state.dart';
import '../../../core/presentation/states/mameroom_loading_state.dart';
import '../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../domain/notice.dart';
import 'notice_detail_page.dart';
import 'notice_providers.dart';

class NoticeListPage extends ConsumerWidget {
  const NoticeListPage({super.key});
  static const routePath = '/settings/notices';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noticesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: state.when(
            loading: () => const Center(
              child: MameroomLoadingState(
                title: '공지사항을 불러오고 있어요',
                description: '잠시만 기다려 주세요.',
              ),
            ),
            error: (_, _) => MameroomErrorState.network(
              onRetry: () => ref.invalidate(noticesProvider),
            ),
            data: (notices) => RefreshIndicator(
              onRefresh: () => ref.refresh(noticesProvider.future),
              child: notices.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      children: const [
                        SizedBox(
                          height: 360,
                          child: MameroomEmptyState(
                            title: '등록된 공지사항이 없습니다.',
                            description: '새로운 소식이 등록되면 알려드릴게요.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: notices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _NoticeCard(
                        notice: notices[index],
                        onTap: () => context.push(
                          NoticeDetailPage.pathFor(notices[index].id),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onTap});
  final Notice notice;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeBadge(notice.typeLabel),
                      if (notice.isPinned) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.push_pin_rounded,
                          size: 17,
                          color: context.mameroom.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    notice.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(_date(notice.publishedAt)),
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.mameroom.primaryMist,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

String _date(DateTime value) =>
    '${value.year}.${value.month.toString().padLeft(2, '0')}.'
    '${value.day.toString().padLeft(2, '0')}';
