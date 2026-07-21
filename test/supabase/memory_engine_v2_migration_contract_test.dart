import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    sql = File(
      'supabase/migrations/202607210001_memory_engine_v2_additive.sql',
    ).readAsStringSync().toLowerCase();
  });

  test('migration is additive and preserves legacy memory tables', () {
    expect(
      sql,
      contains('create table if not exists public.question_memory_states_v2'),
    );
    expect(
      sql,
      contains('create table if not exists public.memory_review_logs_v2'),
    );
    expect(sql, isNot(contains('drop table public.memory_states')));
    expect(sql, isNot(contains('truncate')));
    expect(sql, isNot(contains('delete from public.memory_states')));
  });

  test('direct client writes are revoked and service RPC is restricted', () {
    expect(
      sql,
      contains(
        'revoke insert, update, delete on public.question_memory_states_v2 from anon, authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.finalize_memory_submission_v2',
      ),
    );
    expect(sql, contains('to service_role'));
    expect(sql, contains("if auth.role() <> 'service_role'"));
  });

  test('due query is server-time, multiple-choice and deterministic', () {
    expect(sql, contains('qms.due_at<=transaction_timestamp()'));
    expect(sql, contains("q.type='multiple_choice'"));
    expect(sql, contains('order by qms.due_at,qms.stability,qms.question_id'));
  });

  test('idempotency and CAS constraints are present', () {
    expect(sql, contains('submission_id uuid not null unique'));
    expect(sql, contains('state_version bigint not null'));
    expect(sql, contains('state_version_conflict'));
    expect(sql, contains('for update'));
  });
}
