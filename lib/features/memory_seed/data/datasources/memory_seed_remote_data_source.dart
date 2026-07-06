import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/memory_seed.dart';

class MemorySeedRemoteDataSource {
  const MemorySeedRemoteDataSource(this._client);

  final SupabaseClient _client;
  Future<List<MemorySeed>> loadCompletedSeeds() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to load completed memory seeds.');
    }

    final rows = await _client
        .from(SupabaseTables.memorySeeds)
        .select('id,user_id,seed_type,growth_stage,growth_value,max_growth_value,status,asset_key,created_at,updated_at,completed_at')
        .eq('user_id', user.id)
        .eq('status', 'completed')
        .order('completed_at', ascending: false);

    return rows
        .map((row) => MemorySeed.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<MemorySeed> loadCurrentSeed() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to load memory seed.');
    }

    final existing = await _client
        .from(SupabaseTables.memorySeeds)
        .select('id,user_id,seed_type,growth_stage,growth_value,max_growth_value,status,asset_key,created_at,updated_at,completed_at')
        .eq('user_id', user.id)
        .eq('status', 'growing')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return MemorySeed.fromJson(Map<String, dynamic>.from(existing));
    }

    final created = await _client
        .from(SupabaseTables.memorySeeds)
        .insert({
          'user_id': user.id,
          'seed_type': 'blossom',
          'growth_stage': 'seed',
          'growth_value': 0,
          'max_growth_value': 100,
          'status': 'growing',
          'asset_key': 'seed_blossom_seed',
        })
        .select('id,user_id,seed_type,growth_stage,growth_value,max_growth_value,status,asset_key,created_at,updated_at,completed_at')
        .single();

    return MemorySeed.fromJson(Map<String, dynamic>.from(created));
  }

  Future<MemorySeedGrowthResult> applyQuizResultGrowth({
    required int correctCount,
    required int totalCount,
    required double accuracy,
  }) async {
    final current = await loadCurrentSeed();
    if (current.isCompleted) {
      return MemorySeedGrowthResult(seed: current, growthDelta: 0, completedNow: false);
    }

    final growthDelta = _growthDelta(correctCount: correctCount, totalCount: totalCount, accuracy: accuracy);
    final nextGrowth = (current.growthValue + growthDelta).clamp(0, current.maxGrowthValue).toInt();
    final completedNow = nextGrowth >= current.maxGrowthValue;
    final nextStage = completedNow ? 'complete' : _stageFor(nextGrowth, current.maxGrowthValue);
    final nextAssetKey = 'seed_${current.seedType}_$nextStage';

    final updated = await _client
        .from(SupabaseTables.memorySeeds)
        .update({
          'growth_value': nextGrowth,
          'growth_stage': nextStage,
          'status': completedNow ? 'completed' : 'growing',
          'asset_key': nextAssetKey,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'completed_at': completedNow ? DateTime.now().toUtc().toIso8601String() : null,
        })
        .eq('id', current.id)
        .select('id,user_id,seed_type,growth_stage,growth_value,max_growth_value,status,asset_key,created_at,updated_at,completed_at')
        .single();

    return MemorySeedGrowthResult(
      seed: MemorySeed.fromJson(Map<String, dynamic>.from(updated)),
      growthDelta: growthDelta,
      completedNow: completedNow,
    );
  }

  int _growthDelta({required int correctCount, required int totalCount, required double accuracy}) {
    if (totalCount <= 0) return 0;
    final accuracyBonus = (accuracy.clamp(0, 1) * 16).round();
    final correctBonus = (correctCount * 2).clamp(0, 20).toInt();
    return (4 + accuracyBonus + correctBonus).clamp(4, 40).toInt();
  }

  String _stageFor(int growthValue, int maxGrowthValue) {
    final progress = maxGrowthValue <= 0 ? 0.0 : growthValue / maxGrowthValue;
    if (progress >= 0.75) return 'flower';
    if (progress >= 0.45) return 'leaf';
    if (progress >= 0.18) return 'sprout';
    return 'seed';
  }
}
