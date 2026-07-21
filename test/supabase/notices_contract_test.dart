import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File('supabase/notices_v1.sql').readAsStringSync();

  test('limits users to currently published notices', () {
    expect(sql, contains('is_published'));
    expect(sql, contains('published_at<=now()'));
    expect(sql, contains('starts_at<=now()'));
    expect(sql, contains('ends_at>now()'));
  });

  test('blocks client writes and supports pinned latest ordering index', () {
    expect(sql, contains('revoke all on public.notices from anon,authenticated'));
    expect(sql, contains('grant select on public.notices to authenticated'));
    expect(sql, contains('is_pinned desc,published_at desc,created_at desc'));
  });
}
