import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/notice.dart';

abstract interface class NoticeRepository {
  Future<List<Notice>> loadNotices();
  Future<Notice?> loadNotice(String id);
}

class SupabaseNoticeRepository implements NoticeRepository {
  const SupabaseNoticeRepository(this._client);
  final SupabaseClient _client;
  static const _columns = 'id,title,content,notice_type,is_pinned,published_at';

  @override
  Future<List<Notice>> loadNotices() async {
    final rows = await _client
        .from('notices')
        .select(_columns)
        .order('is_pinned', ascending: false)
        .order('published_at', ascending: false)
        .order('created_at', ascending: false);
    return rows.map((row) => Notice.fromJson(row)).toList(growable: false);
  }

  @override
  Future<Notice?> loadNotice(String id) async {
    final row = await _client
        .from('notices')
        .select(_columns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Notice.fromJson(row);
  }
}
