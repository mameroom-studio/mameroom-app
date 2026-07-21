import '../entities/premium_models.dart';

abstract interface class PremiumBillingGateway {
  Future<List<PremiumProduct>> loadProducts();
  Future<PurchaseLaunchResult> launchPurchase(String productId);
  Future<RestorePurchaseResult> restorePurchases();
  Future<void> openSubscriptionManagement();
}
