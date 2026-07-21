import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/supabase/supabase_client_provider.dart';
import '../data/notice_repository.dart';
import '../domain/notice.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase client is not initialized.');
  return SupabaseNoticeRepository(client);
});
final noticesProvider = FutureProvider<List<Notice>>(
  (ref) => ref.watch(noticeRepositoryProvider).loadNotices(),
);
final noticeProvider = FutureProvider.family<Notice?, String>(
  (ref, id) => ref.watch(noticeRepositoryProvider).loadNotice(id),
);
