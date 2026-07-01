import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/coin_wallet.dart';

class CoinRemoteDataSource {
  const CoinRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<CoinWallet> loadWallet() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to load wallet.');
    }

    final wallet = await _client
        .from(SupabaseTables.userWallets)
        .select('balance,total_earned,total_spent')
        .eq('user_id', user.id)
        .maybeSingle();

    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).toUtc();
    final transactions = await _client
        .from(SupabaseTables.coinTransactions)
        .select('amount')
        .eq('user_id', user.id)
        .gte('created_at', todayStart.toIso8601String());

    final todayEarned = transactions.fold<int>(0, (sum, row) {
      final amount = (row as Map)['amount'];
      if (amount is num && amount > 0) {
        return sum + amount.toInt();
      }
      return sum;
    });

    return CoinWallet(
      balance: _intFrom(wallet?['balance']),
      totalEarned: _intFrom(wallet?['total_earned']),
      totalSpent: _intFrom(wallet?['total_spent']),
      todayEarned: todayEarned,
    );
  }

  Future<CoinRewardSummary> awardQuizCompletion({
    required String materialId,
    required List<CoinRewardAnswer> answers,
    required List<CoinRewardMemoryChange> memoryChanges,
  }) async {
    var summary = CoinRewardSummary.empty;

    for (final answer in answers.where((answer) => answer.isCorrect)) {
      summary = summary.combine(
        await _award(
          amount: 1,
          transactionType: 'correct_answer',
          sourceType: 'quiz',
          sourceId: answer.questionId,
        ),
      );
    }

    if (_hasFiveCorrectStreak(answers)) {
      summary = summary.combine(
        await _award(
          amount: 2,
          transactionType: 'streak_bonus',
          sourceType: 'quiz',
          sourceId: materialId,
        ),
      );
    }

    for (final change in memoryChanges.where((change) => change.increased)) {
      summary = summary.combine(
        await _award(
          amount: 50,
          transactionType: 'memory_increase',
          sourceType: 'memory',
          sourceId: change.conceptId,
        ),
      );
    }

    summary = summary.combine(
      await _award(
        amount: 10,
        transactionType: 'first_study',
        sourceType: 'study',
        sourceId: materialId,
      ),
    );

    return summary;
  }

  Future<CoinRewardSummary> awardReviewCompletion({
    required String reviewSessionId,
    required List<CoinRewardAnswer> answers,
    required List<CoinRewardMemoryChange> memoryChanges,
  }) async {
    var summary = CoinRewardSummary.empty;

    for (final answer in answers.where((answer) => answer.isCorrect)) {
      summary = summary.combine(
        await _award(
          amount: 1,
          transactionType: 'correct_answer',
          sourceType: 'review',
          sourceId: answer.questionId,
        ),
      );
    }

    if (_hasFiveCorrectStreak(answers)) {
      summary = summary.combine(
        await _award(
          amount: 2,
          transactionType: 'streak_bonus',
          sourceType: 'review',
          sourceId: reviewSessionId,
        ),
      );
    }

    for (final change in memoryChanges.where((change) => change.increased)) {
      summary = summary.combine(
        await _award(
          amount: 50,
          transactionType: 'memory_increase',
          sourceType: 'memory',
          sourceId: change.conceptId,
        ),
      );
    }

    summary = summary.combine(
      await _award(
        amount: 20,
        transactionType: 'review_complete',
        sourceType: 'review',
        sourceId: reviewSessionId,
      ),
    );

    return summary;
  }

  Future<CoinRewardSummary> _award({
    required int amount,
    required String transactionType,
    required String sourceType,
    required String sourceId,
  }) async {
    final result = await _client.rpc('award_m_coin', params: {
      'p_amount': amount,
      'p_transaction_type': transactionType,
      'p_source_type': sourceType,
      'p_source_id': sourceId,
    });

    final row = result is List && result.isNotEmpty
        ? Map<String, dynamic>.from(result.first as Map)
        : result is Map
            ? Map<String, dynamic>.from(result)
            : const <String, dynamic>{};

    return CoinRewardSummary(
      earnedCoins: _intFrom(row['awarded_amount']),
      balance: _intFrom(row['balance']),
      bonusCoins: _intFrom(row['bonus_amount']),
    );
  }

  bool _hasFiveCorrectStreak(List<CoinRewardAnswer> answers) {
    var streak = 0;
    for (final answer in answers) {
      if (answer.isCorrect) {
        streak += 1;
        if (streak >= 5) {
          return true;
        }
      } else {
        streak = 0;
      }
    }
    return false;
  }

  int _intFrom(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}