import 'package:ai_memory_coach/features/notices/data/notice_repository.dart';
import 'package:ai_memory_coach/features/notices/domain/notice.dart';
import 'package:ai_memory_coach/features/notices/presentation/notice_detail_page.dart';
import 'package:ai_memory_coach/features/notices/presentation/notice_list_page.dart';
import 'package:ai_memory_coach/features/notices/presentation/notice_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoticeRepo implements NoticeRepository {
  _NoticeRepo(this.items, {this.failure = false});
  final List<Notice> items;
  final bool failure;
  @override
  Future<List<Notice>> loadNotices() async {
    if (failure) throw Exception('network');
    return items;
  }

  @override
  Future<Notice?> loadNotice(String id) async {
    if (failure) throw Exception('network');
    return items.where((item) => item.id == id).firstOrNull;
  }
}

Notice _notice({
  String id = 'notice-1',
  String title = '마메룸 베타 서비스 안내',
  String content = '긴 공지 본문입니다.\n두 번째 줄입니다.',
}) => Notice(
  id: id,
  title: title,
  content: content,
  type: 'IMPORTANT',
  isPinned: true,
  publishedAt: DateTime.utc(2026, 7, 19),
);

Widget _app(Widget child, NoticeRepository repository) => ProviderScope(
  overrides: [noticeRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(home: child),
);

void main() {
  testWidgets('renders notice empty state', (tester) async {
    await tester.pumpWidget(_app(const NoticeListPage(), _NoticeRepo([])));
    await tester.pumpAndSettle();
    expect(find.text('등록된 공지사항이 없습니다.'), findsOneWidget);
  });

  testWidgets('renders pinned notice with long title safely', (tester) async {
    final longTitle = '긴 제목 ' * 30;
    await tester.pumpWidget(
      _app(const NoticeListPage(), _NoticeRepo([_notice(title: longTitle)])),
    );
    await tester.pumpAndSettle();
    expect(find.text(longTitle), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders plain-text notice detail', (tester) async {
    final notice = _notice();
    await tester.pumpWidget(
      _app(const NoticeDetailPage(noticeId: 'notice-1'), _NoticeRepo([notice])),
    );
    await tester.pumpAndSettle();
    expect(find.text(notice.title), findsOneWidget);
    expect(find.text(notice.content), findsOneWidget);
  });

  test('repository propagates network failures', () async {
    final repository = _NoticeRepo([], failure: true);
    await expectLater(repository.loadNotices(), throwsException);
  });
}
