import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/streak_state.dart';

class StreakRemoteDataSource {
  const StreakRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<StreakState> loadStreak() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to load streak.');
    }

    final row = await _client
        .from(SupabaseTables.userStreaks)
        .select('current_streak,max_streak,last_studied_on')
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) {
      return StreakState.empty;
    }

    final lastStudiedOn = DateTime.tryParse(row['last_studied_on']?.toString() ?? '');
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final visibleCurrent = _isStillActive(lastStudiedOn, todayDate)
        ? _intFrom(row['current_streak'])
        : 0;

    return StreakState(
      currentStreak: visibleCurrent,
      maxStreak: _intFrom(row['max_streak']),
      milestoneReward: 0,
      walletBalance: 0,
    );
  }

  Future<StreakState> recordStudyCompletion({
    required String sourceType,
    required String sourceId,
  }) async {
    final result = await _client.rpc('record_daily_streak', params: {
      'p_source_type': sourceType,
      'p_source_id': sourceId,
    });

    final row = result is List && result.isNotEmpty
        ? Map<String, dynamic>.from(result.first as Map)
        : result is Map
            ? Map<String, dynamic>.from(result)
            : const <String, dynamic>{};

    return StreakState(
      currentStreak: _intFrom(row['current_streak']),
      maxStreak: _intFrom(row['max_streak']),
      milestoneReward: _intFrom(row['milestone_reward']),
      walletBalance: _intFrom(row['wallet_balance']),
    );
  }

  bool _isStillActive(DateTime? lastStudiedOn, DateTime todayDate) {
    if (lastStudiedOn == null) {
      return false;
    }
    final studiedDate = DateTime(
      lastStudiedOn.year,
      lastStudiedOn.month,
      lastStudiedOn.day,
    );
    return !studiedDate.isBefore(todayDate.subtract(const Duration(days: 1)));
  }

  int _intFrom(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}