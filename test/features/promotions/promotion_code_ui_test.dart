import 'package:ai_memory_coach/features/promotions/data/promotion_repository.dart';
import 'package:ai_memory_coach/features/promotions/domain/promotion_redemption.dart';
import 'package:ai_memory_coach/features/promotions/presentation/promotion_code_page.dart';
import 'package:ai_memory_coach/features/promotions/presentation/promotion_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePromotionRepository implements PromotionRepository {
  _FakePromotionRepository(this.result);
  final PromotionRedemption result;
  String? receivedCode;
  @override
  Future<PromotionRedemption> redeem(String code) async {
    receivedCode = code;
    return result;
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakePromotionRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [promotionRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: PromotionCodePage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('normalizes input and shows MCOIN server reward', (tester) async {
    final repository = _FakePromotionRepository(
      const PromotionRedemption(
        success: true,
        status: PromotionRedemptionStatus.success,
        message: '',
        reward: PromotionReward(type: 'MCOIN', value: 500),
      ),
    );
    await _pump(tester, repository);
    await tester.enterText(
      find.byKey(const ValueKey('promotion-code-input')),
      '  beta2026  ',
    );
    await tester.tap(find.byKey(const ValueKey('promotion-redeem')));
    await tester.pump(const Duration(seconds: 1));
    expect(repository.receivedCode, 'beta2026');
    expect(find.text('M-Coin 500개가 지급되었습니다.'), findsOneWidget);
  });

  testWidgets('blocks immediate resend after success', (tester) async {
    final repository = _FakePromotionRepository(
      const PromotionRedemption(
        success: true,
        status: PromotionRedemptionStatus.success,
        message: '',
        reward: PromotionReward(type: 'MCOIN', value: 10),
      ),
    );
    await _pump(tester, repository);
    await tester.enterText(
      find.byKey(const ValueKey('promotion-code-input')),
      'EVENT10',
    );
    await tester.tap(find.byKey(const ValueKey('promotion-redeem')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('확인'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('promotion-redeem')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('이미 적용한 코드입니다.'), findsOneWidget);
  });

  testWidgets('maps already-used failure', (tester) async {
    final repository = _FakePromotionRepository(
      const PromotionRedemption(
        success: false,
        status: PromotionRedemptionStatus.alreadyUsed,
        message: '',
      ),
    );
    await _pump(tester, repository);
    await tester.enterText(
      find.byKey(const ValueKey('promotion-code-input')),
      'USED',
    );
    await tester.tap(find.byKey(const ValueKey('promotion-redeem')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('이미 사용한 코드입니다.'), findsOneWidget);
  });
}
