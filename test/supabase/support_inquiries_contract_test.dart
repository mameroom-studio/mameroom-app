import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('support migration contains security and rate-limit contract', () {
    final sql = File(
      'supabase/migrations/202607200003_support_inquiries_v1_additive.sql',
    ).readAsStringSync();
    for (final token in <String>[
      'enable row level security',
      'create_support_inquiry',
      'RATE_LIMITED',
      'DAILY_LIMIT_EXCEEDED',
      'DUPLICATE_INQUIRY',
      'auth.uid()',
      'revoke all',
      'to authenticated',
      'answer_support_inquiry',
      'to service_role',
      'references auth.users(id)',
      'if p_related_material_id is not null',
      'set search_path = pg_catalog, public, pg_temp',
    ]) {
      expect(sql.toLowerCase(), contains(token.toLowerCase()), reason: token);
    }
    expect(sql, isNot(contains('service_role key')));
    expect(sql, isNot(contains('references public.profiles')));
    expect(sql, isNot(contains('from public.profiles')));
    expect(sql, isNot(contains('references public.study_materials')));
  });
}
