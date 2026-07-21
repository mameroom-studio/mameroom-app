import 'package:ai_memory_coach/app/theme.dart';
import 'package:ai_memory_coach/features/premium/data/gateways/mock_premium_billing_gateway.dart';
import 'package:ai_memory_coach/features/premium/domain/entities/premium_models.dart';
import 'package:ai_memory_coach/features/premium/presentation/controllers/premium_controller.dart';
import 'package:ai_memory_coach/features/premium/presentation/pages/mameroom_paywall_page.dart';
import 'package:ai_memory_coach/features/premium/presentation/widgets/premium_paywall_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mock plans load from the billing gateway', () async {
    final gateway = MockPremiumBillingGateway(delay: Duration.zero);

    final products = await gateway.loadProducts();

    expect(
      products.map((product) => product.planType),
      containsAll([PremiumPlanType.monthly, PremiumPlanType.annual]),
    );
    expect(products.first.localizedPrice, isNotEmpty);
  });

  testWidgets('comparison renders benefits and free continuation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PremiumBenefitComparison(onStartPremium: () {}, onContinueFree: () {}),
      ),
    );

    expect(find.text('FREE vs PREMIUM'), findsOneWidget);
    expect(find.text('월 제공 문제 수'), findsOneWidget);
    expect(find.text('아니요, 계속 무료로 사용할래요'), findsOneWidget);
  });

  testWidgets('plan selection changes one selected card at a time', (
    tester,
  ) async {
    final state = PremiumPaywallState(
      status: PremiumPurchaseStatus.ready,
      products: mockPremiumProducts,
      selectedProductId: mockPremiumProducts.first.id,
    );
    String? selected;
    await tester.pumpWidget(
      _wrap(
        PremiumPlanSelector(
          state: state,
          onSelect: (id) => selected = id,
          onContinue: () {},
          onRestore: () {},
          onRetryProducts: () {},
        ),
      ),
    );

    await tester.tap(find.text('월간 플랜'));
    await tester.pump();

    expect(selected, 'mock_premium_monthly');
    expect(find.text('계속하기'), findsOneWidget);
  });

  testWidgets('unavailable plan cannot be selected', (tester) async {
    const unavailable = PremiumProduct(
      id: 'unavailable',
      title: '긴 이름의 사용할 수 없는 Premium 월간 플랜',
      description: '테스트',
      localizedPrice: '₩0',
      billingPeriod: '/ 월',
      planType: PremiumPlanType.monthly,
      benefits: ['테스트'],
      isAvailable: false,
    );
    String? selected;
    await tester.pumpWidget(
      _wrap(
        PremiumPlanSelector(
          state: const PremiumPaywallState(
            status: PremiumPurchaseStatus.ready,
            products: [unavailable],
          ),
          onSelect: (id) => selected = id,
          onContinue: () {},
          onRestore: () {},
          onRetryProducts: () {},
        ),
      ),
    );

    await tester.tap(find.text('긴 이름의 사용할 수 없는 Premium 월간 플랜'));
    await tester.pump();

    expect(selected, isNull);
  });

  test('purchase launch disables repeated CTA while in flight', () async {
    final gateway = MockPremiumBillingGateway(
      delay: const Duration(milliseconds: 50),
    );
    final controller = PremiumController(gateway);

    await controller.loadProducts();
    final launch = controller.launchSelectedPurchase();
    expect(controller.state.status, PremiumPurchaseStatus.launchingPurchase);
    expect(controller.state.canLaunchPurchase, isFalse);
    await launch;

    expect(gateway.launchCount, 1);
    expect(controller.state.status, PremiumPurchaseStatus.completed);
  });

  testWidgets('purchase micro states render', (tester) async {
    for (final status in [
      PremiumPurchaseStatus.cancelled,
      PremiumPurchaseStatus.failed,
      PremiumPurchaseStatus.pending,
      PremiumPurchaseStatus.alreadyOwned,
      PremiumPurchaseStatus.networkError,
      PremiumPurchaseStatus.verificationFailed,
    ]) {
      await tester.pumpWidget(_wrap(PurchaseStateView(status: status)));
      expect(
        find.byKey(ValueKey('purchase-state-${status.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('restore states render', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PurchaseStateView(
          status: PremiumPurchaseStatus.restoreInProgress,
        ),
      ),
    );
    expect(find.text('구매 복원 중'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        const PurchaseStateView(status: PremiumPurchaseStatus.restoreCompleted),
      ),
    );
    expect(find.text('구매 복원이 완료되었어요.'), findsOneWidget);
  });

  testWidgets('subscription management renders and callback works', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      _wrap(
        SubscriptionManagementView(
          entitlement: mockEntitlement,
          onOpenManagement: () => opened = true,
          onRestore: () {},
        ),
      ),
    );

    expect(find.text('Premium (연간 플랜)'), findsOneWidget);
    await tester.tap(find.text('정기 결제 관리'));
    await tester.pump();
    expect(opened, isTrue);
  });

  testWidgets('390x844 page renders Korean text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumBillingGatewayProvider.overrideWithValue(
            MockPremiumBillingGateway(delay: Duration.zero),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MameroomPaywallPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('FREE vs PREMIUM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}
