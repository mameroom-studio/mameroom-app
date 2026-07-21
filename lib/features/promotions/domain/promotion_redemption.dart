enum PromotionRedemptionStatus {
  success,
  invalidCode,
  alreadyUsed,
  expired,
  notStarted,
  limitExceeded,
  userLimitExceeded,
  disabled,
  rewardFailed,
  unsupportedReward,
  invalidReward,
  unauthenticated,
  internalError,
  unknown;

  static PromotionRedemptionStatus fromWire(String value) => switch (value) {
    'SUCCESS' => success,
    'INVALID_CODE' => invalidCode,
    'ALREADY_USED' => alreadyUsed,
    'EXPIRED' => expired,
    'NOT_STARTED' => notStarted,
    'LIMIT_EXCEEDED' || 'TOTAL_LIMIT_EXCEEDED' => limitExceeded,
    'USER_LIMIT_EXCEEDED' => userLimitExceeded,
    'DISABLED' => disabled,
    'REWARD_FAILED' => rewardFailed,
    'UNSUPPORTED_REWARD' => unsupportedReward,
    'INVALID_REWARD' => invalidReward,
    'UNAUTHENTICATED' => unauthenticated,
    'INTERNAL_ERROR' => internalError,
    _ => unknown,
  };
}

class PromotionReward {
  const PromotionReward({required this.type, required this.value});
  final String type;
  final int value;

  String get displayText => switch (type) {
    'QUESTION' => '$value문제',
    'MCOIN' => '$value M-Coin',
    'PREMIUM_DAYS' => 'Premium $value일',
    'ITEM' => '아이템 $value개',
    'BADGE' => 'Badge $value개',
    'MEMORY_TREE' => '기억나무 $value개',
    _ => '보상 $value개',
  };
}

class PromotionRedemption {
  const PromotionRedemption({
    required this.success,
    required this.status,
    required this.message,
    this.reward,
  });
  final bool success;
  final PromotionRedemptionStatus status;
  final String message;
  final PromotionReward? reward;

  factory PromotionRedemption.fromJson(Map<String, dynamic> json) {
    final rawReward = json['reward'];
    final reward = rawReward is Map
        ? PromotionReward(
            type: '${rawReward['type'] ?? ''}',
            value: (rawReward['value'] as num?)?.toInt() ?? 0,
          )
        : null;
    return PromotionRedemption(
      success: json['success'] == true,
      status: PromotionRedemptionStatus.fromWire('${json['status'] ?? ''}'),
      message: '${json['message'] ?? ''}',
      reward: reward,
    );
  }
}
