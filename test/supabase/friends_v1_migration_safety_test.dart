import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('friends migration is guarded and additive', () {
    final sql = File(
      'supabase/migrations/202607200001_friends_v1_additive.sql',
    ).readAsStringSync();
    final normalized = sql.toLowerCase();

    expect(normalized, contains("to_regclass('public.profiles')"));
    expect(normalized, contains('friends_v1_incompatible_profiles'));
    expect(normalized, contains('create table if not exists'));
    expect(normalized, contains('enable row level security'));
    expect(normalized, contains('security definer'));
    expect(normalized, contains('set search_path = public, pg_temp'));
    expect(normalized, contains('auth.uid()'));
    expect(normalized, contains('grant execute'));
    expect(normalized, contains('revoke all'));
    expect(normalized, isNot(contains('create or replace function')));
    expect(normalized, isNot(contains('drop table')));
    expect(normalized, isNot(contains('drop column')));
    expect(normalized, isNot(contains('disable row level security')));
    expect(normalized, isNot(contains('truncate ')));
  });

  test('preflight is read-only and covers production contracts', () {
    final sql = File('supabase/friends_v1_preflight.sql').readAsStringSync();
    final normalized = sql.toLowerCase();

    for (final contract in const [
      'profiles_primary_key',
      'profiles_auth_fk',
      'function_contract',
      'function_privilege',
      'rls',
      'policy',
      'trigger',
    ]) {
      expect(normalized, contains(contract));
    }
    expect(normalized, isNot(contains('create table')));
    expect(normalized, isNot(contains('alter table')));
    expect(normalized, isNot(contains('drop table')));
    expect(normalized, isNot(contains('grant execute')));
    expect(normalized, isNot(contains('revoke all')));
  });
}
