import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/states/mameroom_error_state.dart';
import '../../../core/presentation/states/mameroom_loading_state.dart';
import 'notice_providers.dart';

class NoticeDetailPage extends ConsumerWidget {
  const NoticeDetailPage({super.key, required this.noticeId});
  static const routePath = '/settings/notices/:noticeId';
  static String pathFor(String id) => '/settings/notices/$id';
  final String noticeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noticeProvider(noticeId));
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: state.when(
            loading: () => const MameroomLoadingState(
              title: '공지사항을 불러오고 있어요',
              description: '잠시만 기다려 주세요.',
            ),
            error: (_, _) => MameroomErrorState.network(
              onRetry: () => ref.invalidate(noticeProvider(noticeId)),
            ),
            data: (notice) {
              if (notice == null) {
                return const MameroomErrorState(
                  title: '공지사항을 찾을 수 없습니다.',
                  description: '게시가 종료되었거나 삭제된 공지입니다.',
                  primaryButtonText: null,
                );
              }
              return SelectionArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      notice.typeLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      notice.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${notice.publishedAt.year}.'
                      '${notice.publishedAt.month.toString().padLeft(2, '0')}.'
                      '${notice.publishedAt.day.toString().padLeft(2, '0')}',
                    ),
                    const Divider(height: 40),
                    Text(
                      notice.content,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.7),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
