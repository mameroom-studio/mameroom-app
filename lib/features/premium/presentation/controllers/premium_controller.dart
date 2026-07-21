import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/gateways/mock_premium_billing_gateway.dart';
import '../../domain/entities/premium_models.dart';
import '../../domain/gateways/premium_billing_gateway.dart';

final premiumBillingGatewayProvider = Provider<PremiumBillingGateway>((ref) {
  return MockPremiumBillingGateway();
});

final premiumControllerProvider =
    StateNotifierProvider.autoDispose<PremiumController, PremiumPaywallState>((
      ref,
    ) {
      return PremiumController(ref.watch(premiumBillingGatewayProvider));
    });

class PremiumPaywallState {
  const PremiumPaywallState({
    required this.status,
    this.products = const [],
    this.selectedProductId,
    this.entitlement,
    this.errorMessage,
    this.showHandoff = false,
  });

  final PremiumPurchaseStatus status;
  final List<PremiumProduct> products;
  final String? selectedProductId;
  final PremiumEntitlement? entitlement;
  final String? errorMessage;
  final bool showHandoff;

  PremiumProduct? get selectedProduct {
    for (final product in products) {
      if (product.id == selectedProductId) return product;
    }
    return null;
  }

  bool get canLaunchPurchase =>
      selectedProduct != null &&
      selectedProduct!.isAvailable &&
      status != PremiumPurchaseStatus.launchingPurchase &&
      status != PremiumPurchaseStatus.verifying &&
      status != PremiumPurchaseStatus.activatingEntitlement;

  PremiumPaywallState copyWith({
    PremiumPurchaseStatus? status,
    List<PremiumProduct>? products,
    String? selectedProductId,
    PremiumEntitlement? entitlement,
    String? errorMessage,
    bool? showHandoff,
  }) {
    return PremiumPaywallState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      entitlement: entitlement ?? this.entitlement,
      errorMessage: errorMessage,
      showHandoff: showHandoff ?? this.showHandoff,
    );
  }
}

class PremiumController extends StateNotifier<PremiumPaywallState> {
  PremiumController(this._gateway)
    : super(const PremiumPaywallState(status: PremiumPurchaseStatus.idle));

  final PremiumBillingGateway _gateway;
  bool _purchaseInFlight = false;

  Future<void> loadProducts() async {
    if (state.status == PremiumPurchaseStatus.loadingProducts) return;
    state = state.copyWith(status: PremiumPurchaseStatus.loadingProducts);
    try {
      final products = await _gateway.loadProducts();
      final selected = products
          .where((product) => product.isAvailable)
          .cast<PremiumProduct?>()
          .firstWhere(
            (product) => product?.isRecommended ?? false,
            orElse: () =>
                products.where((product) => product.isAvailable).isEmpty
                ? null
                : products.where((product) => product.isAvailable).first,
          )
          ?.id;
      state = state.copyWith(
        status: products.isEmpty
            ? PremiumPurchaseStatus.productUnavailable
            : PremiumPurchaseStatus.ready,
        products: products,
        selectedProductId: selected,
      );
    } catch (error) {
      state = state.copyWith(
        status: PremiumPurchaseStatus.networkError,
        errorMessage: error.toString(),
      );
    }
  }

  void selectProduct(String productId) {
    final product = state.products
        .where((candidate) => candidate.id == productId)
        .cast<PremiumProduct?>()
        .firstWhere((candidate) => candidate != null, orElse: () => null);
    if (product == null || !product.isAvailable || _purchaseInFlight) return;
    state = state.copyWith(selectedProductId: productId);
  }

  void showPurchaseHandoff() {
    if (!state.canLaunchPurchase) return;
    state = state.copyWith(showHandoff: true);
  }

  void hidePurchaseHandoff() {
    state = state.copyWith(showHandoff: false);
  }

  Future<void> launchSelectedPurchase() async {
    final product = state.selectedProduct;
    if (product == null || _purchaseInFlight) return;
    _purchaseInFlight = true;
    state = state.copyWith(
      status: PremiumPurchaseStatus.launchingPurchase,
      showHandoff: false,
    );
    try {
      final result = await _gateway.launchPurchase(product.id);
      await _applyPurchaseResult(product, result.type);
    } catch (error) {
      state = state.copyWith(
        status: PremiumPurchaseStatus.networkError,
        errorMessage: error.toString(),
      );
    } finally {
      _purchaseInFlight = false;
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(status: PremiumPurchaseStatus.restoreInProgress);
    try {
      final result = await _gateway.restorePurchases();
      state = switch (result.type) {
        RestorePurchaseResultType.completed => state.copyWith(
          status: PremiumPurchaseStatus.restoreCompleted,
          entitlement: result.entitlement ?? mockEntitlement,
        ),
        RestorePurchaseResultType.empty => state.copyWith(
          status: PremiumPurchaseStatus.restoreEmpty,
        ),
        RestorePurchaseResultType.failed => state.copyWith(
          status: PremiumPurchaseStatus.failed,
        ),
        RestorePurchaseResultType.networkError => state.copyWith(
          status: PremiumPurchaseStatus.networkError,
        ),
      };
    } catch (error) {
      state = state.copyWith(
        status: PremiumPurchaseStatus.networkError,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> openSubscriptionManagement() async {
    await _gateway.openSubscriptionManagement();
  }

  void setPreviewStatus(PremiumPurchaseStatus status) {
    state = state.copyWith(
      status: status,
      entitlement:
          status == PremiumPurchaseStatus.completed ||
              status == PremiumPurchaseStatus.alreadyOwned ||
              status == PremiumPurchaseStatus.restoreCompleted
          ? mockEntitlement
          : state.entitlement,
    );
  }

  Future<void> _applyPurchaseResult(
    PremiumProduct product,
    PurchaseLaunchResultType type,
  ) async {
    switch (type) {
      case PurchaseLaunchResultType.completed:
        state = state.copyWith(status: PremiumPurchaseStatus.verifying);
        await Future<void>.delayed(const Duration(milliseconds: 140));
        state = state.copyWith(
          status: PremiumPurchaseStatus.activatingEntitlement,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        state = state.copyWith(
          status: PremiumPurchaseStatus.completed,
          entitlement: _entitlementFor(product),
        );
      case PurchaseLaunchResultType.cancelled:
        state = state.copyWith(status: PremiumPurchaseStatus.cancelled);
      case PurchaseLaunchResultType.failed:
        state = state.copyWith(status: PremiumPurchaseStatus.failed);
      case PurchaseLaunchResultType.pending:
        state = state.copyWith(status: PremiumPurchaseStatus.pending);
      case PurchaseLaunchResultType.alreadyOwned:
        state = state.copyWith(
          status: PremiumPurchaseStatus.alreadyOwned,
          entitlement: _entitlementFor(product),
        );
      case PurchaseLaunchResultType.productUnavailable:
        state = state.copyWith(
          status: PremiumPurchaseStatus.productUnavailable,
        );
      case PurchaseLaunchResultType.networkError:
        state = state.copyWith(status: PremiumPurchaseStatus.networkError);
      case PurchaseLaunchResultType.verificationFailed:
        state = state.copyWith(
          status: PremiumPurchaseStatus.verificationFailed,
        );
    }
  }

  PremiumEntitlement _entitlementFor(PremiumProduct product) {
    return PremiumEntitlement(
      planType: product.planType,
      isActive: true,
      questionAllowance: 300,
      adFree: true,
      unlimitedReview: true,
      premiumAnalysis: true,
      seedGrowthMultiplier: 2,
      roomDecorationAccess: true,
      renewalDate: DateTime(2026, 8, 30),
    );
  }
}

String paywallEntryMessage(PaywallEntryPoint entryPoint) {
  return switch (entryPoint) {
    PaywallEntryPoint.questionLimit => '문제를 더 생성하려면 Premium이 필요해요.',
    PaywallEntryPoint.premiumAnalysis => '고급 AI 분석은 Premium에서 사용할 수 있어요.',
    PaywallEntryPoint.adRemoval => '광고 없이 학습에 집중해보세요.',
    PaywallEntryPoint.unlimitedReview => 'Premium으로 복습 흐름을 더 넓게 열어보세요.',
    PaywallEntryPoint.seedGrowth => '씨앗 성장을 더 빠르게 키워보세요.',
    PaywallEntryPoint.roomDecoration => 'Premium 꾸미기 아이템을 만나보세요.',
    PaywallEntryPoint.myPlan => '현재 플랜과 Premium 혜택을 확인해보세요.',
    PaywallEntryPoint.campaign => 'MAMEROOM Premium 혜택을 준비했어요.',
  };
}
