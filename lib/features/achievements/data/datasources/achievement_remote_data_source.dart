import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementRemoteDataSource {
  const AchievementRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> loadOverview() async {
    final rows = await _client.rpc<List<dynamic>>('get_achievement_overview');
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => (row['payload'] as Map<String, dynamic>?) ?? row)
        .toList();
  }

  Future<Map<String, dynamic>> refreshRewardState(String code) async {
    final rows = await _client.rpc<List<dynamic>>(
      'confirm_achievement_reward',
      params: {'p_achievement_code': code},
    );
    final row = rows.cast<Map<String, dynamic>>().first;
    return (row['payload'] as Map<String, dynamic>?) ?? row;
  }
}
