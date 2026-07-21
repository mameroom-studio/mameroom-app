import '../../domain/entities/premium_models.dart';
import '../../domain/gateways/premium_billing_gateway.dart';

class MockPremiumBillingGateway implements PremiumBillingGateway {
  MockPremiumBillingGateway({
    this.nextPurchaseResult = PurchaseLaunchResultType.completed,
    this.restoreResult = RestorePurchaseResultType.completed,
    this.productsAvailable = true,
    this.delay = const Duration(milliseconds: 120),
  });

  PurchaseLaunchResultType nextPurchaseResult;
  RestorePurchaseResultType restoreResult;
  bool productsAvailable;
  Duration delay;
  int launchCount = 0;
  int managementOpenCount = 0;

  @override
  Future<List<PremiumProduct>> loadProducts() async {
    await Future<void>.delayed(delay);
    if (!productsAvailable) return const [];
    return mockPremiumProducts;
  }

  @override
  Future<PurchaseLaunchResult> launchPurchase(String productId) async {
    launchCount++;
    await Future<void>.delayed(delay);
    return PurchaseLaunchResult(nextPurchaseResult);
  }

  @override
  Future<RestorePurchaseResult> restorePurchases() async {
    await Future<void>.delayed(delay);
    if (restoreResult == RestorePurchaseResultType.completed) {
      return RestorePurchaseResult(restoreResult, entitlement: mockEntitlement);
    }
    return RestorePurchaseResult(restoreResult);
  }

  @override
  Future<void> openSubscriptionManagement() async {
    managementOpenCount++;
    await Future<void>.delayed(delay);
  }
}

const mockPremiumProducts = <PremiumProduct>[
  PremiumProduct(
    id: 'mock_premium_annual',
    title: '연간 플랜',
    description: '1년 동안 Premium 혜택을 이용해요.',
    localizedPrice: '₩47,000',
    billingPeriod: '/ 년',
    planType: PremiumPlanType.annual,
    benefits: ['300문제/무제한 제공', '광고 제거', '맞춤 복습 알림', '방 꾸미기 전체 이용'],
    discountLabel: '20% 할인',
    isRecommended: true,
  ),
  PremiumProduct(
    id: 'mock_premium_monthly',
    title: '월간 플랜',
    description: '매월 Premium 혜택을 이용해요.',
    localizedPrice: '₩4,900',
    billingPeriod: '/ 월',
    planType: PremiumPlanType.monthly,
    benefits: ['300문제 제공', '고급 AI 분석', '광고 제거', '기본 복습 알림'],
  ),
];

final mockEntitlement = PremiumEntitlement(
  planType: PremiumPlanType.annual,
  isActive: true,
  questionAllowance: 300,
  adFree: true,
  unlimitedReview: true,
  premiumAnalysis: true,
  seedGrowthMultiplier: 2,
  roomDecorationAccess: true,
  renewalDate: DateTime(2026, 8, 30),
);
