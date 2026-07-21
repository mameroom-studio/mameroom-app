import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File('supabase/promotion_code_v1.sql').readAsStringSync();

  test('locks master and never accepts a client reward value', () {
    expect(sql, contains('for update'));
    expect(sql, contains('v_promo.reward_value'));
    expect(sql, isNot(contains('p_reward_value')));
    expect(sql, isNot(contains('WELCOME2026')));
  });

  test('integrates MCOIN wallet, coin ledger, reward ledger atomically', () {
    expect(sql, contains('update user_wallets'));
    expect(sql, contains('insert into coin_transactions'));
    expect(sql, contains('insert into reward_transactions'));
    expect(sql, contains('insert into promotion_redemptions'));
    expect(sql, contains('exception when others'));
  });

  test('hashes attempts and forbids direct master access', () {
    expect(sql, contains("digest(v_code,'sha256')"));
    expect(sql, isNot(contains('normalized_code text')));
    expect(
      sql,
      contains(
        'revoke all on public.promotion_codes,public.promotion_redemptions',
      ),
    );
  });

  test('contains every stable result code', () {
    for (final code in [
      'SUCCESS',
      'INVALID_CODE',
      'ALREADY_USED',
      'NOT_STARTED',
      'EXPIRED',
      'DISABLED',
      'TOTAL_LIMIT_EXCEEDED',
      'USER_LIMIT_EXCEEDED',
      'UNSUPPORTED_REWARD',
      'INVALID_REWARD',
      'UNAUTHENTICATED',
      'REWARD_FAILED',
    ]) {
      expect(sql, contains("'$code'"));
    }
  });
}
