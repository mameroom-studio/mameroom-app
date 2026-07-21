import 'package:ai_memory_coach/features/promotions/data/promotion_repository.dart';
import 'package:ai_memory_coach/features/promotions/domain/promotion_redemption.dart';
import 'package:ai_memory_coach/features/promotions/presentation/promotion_code_page.dart';
import 'package:ai_memory_coach/features/promotions/presentation/promotion_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _FlowRepository implements PromotionRepository {
  var calls = 0;
  @override
  Future<PromotionRedemption> redeem(String code) async {
    calls++;
    return const PromotionRedemption(
      success: true,
      status: PromotionRedemptionStatus.success,
      message: '',
      reward: PromotionReward(type: 'MCOIN', value: 500),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Settings promotion redemption flow', (tester) async {
    final repository = _FlowRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [promotionRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: PromotionCodePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('promotion-code-input')),
      'BETA2026',
    );
    await tester.tap(find.byKey(const ValueKey('promotion-redeem')));
    await tester.pump(const Duration(seconds: 1));
    expect(repository.calls, 1);
    expect(find.text('M-Coin 500개가 지급되었습니다.'), findsOneWidget);
  });
}
