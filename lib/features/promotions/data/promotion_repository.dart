import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/promotion_redemption.dart';

abstract interface class PromotionRepository {
  Future<PromotionRedemption> redeem(String code);
}

class SupabasePromotionRepository implements PromotionRepository {
  const SupabasePromotionRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<PromotionRedemption> redeem(String code) async {
    final response = await _client.rpc(
      'redeem_promotion_code',
      params: {
        'promotion_code': code.trim(),
        'client_version': '0.1.0',
        'device_type': 'flutter',
      },
    );
    final row = response is List && response.isNotEmpty
        ? Map<String, dynamic>.from(response.first as Map)
        : Map<String, dynamic>.from(response as Map);
    return PromotionRedemption.fromJson(row);
  }
}
