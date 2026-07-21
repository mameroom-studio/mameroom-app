import 'package:ai_memory_coach/features/promotions/domain/promotion_redemption.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps data-driven QUESTION reward', () {
    final result = PromotionRedemption.fromJson({
      'success': true,
      'status': 'SUCCESS',
      'reward': {'type': 'QUESTION', 'value': 30},
      'message': '30문제가 지급되었습니다.',
    });
    expect(result.status, PromotionRedemptionStatus.success);
    expect(result.reward?.displayText, '30문제');
  });

  test('maps every server failure status without reward calculation', () {
    const statuses = {
      'INVALID_CODE': PromotionRedemptionStatus.invalidCode,
      'ALREADY_USED': PromotionRedemptionStatus.alreadyUsed,
      'EXPIRED': PromotionRedemptionStatus.expired,
      'NOT_STARTED': PromotionRedemptionStatus.notStarted,
      'LIMIT_EXCEEDED': PromotionRedemptionStatus.limitExceeded,
      'USER_LIMIT_EXCEEDED': PromotionRedemptionStatus.userLimitExceeded,
      'DISABLED': PromotionRedemptionStatus.disabled,
      'REWARD_FAILED': PromotionRedemptionStatus.rewardFailed,
    };
    for (final entry in statuses.entries) {
      final result = PromotionRedemption.fromJson({
        'success': false,
        'status': entry.key,
        'message': 'failure',
      });
      expect(result.status, entry.value);
      expect(result.reward, isNull);
    }
  });
}
