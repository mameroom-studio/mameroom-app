import '../../domain/entities/premium_models.dart';
import '../../domain/gateways/premium_billing_gateway.dart';

class GooglePlayPremiumBillingGateway implements PremiumBillingGateway {
  const GooglePlayPremiumBillingGateway();

  @override
  Future<List<PremiumProduct>> loadProducts() {
    // TODO: Load configured Google Play product IDs after Play Console setup.
    // TODO: Map Store product metadata into PremiumProduct without UI changes.
    throw UnimplementedError('Google Play Billing is not connected yet.');
  }

  @override
  Future<PurchaseLaunchResult> launchPurchase(String productId) {
    // TODO: Launch Google Play Billing purchase flow for the selected product.
    // TODO: Listen for purchase updates and map them to PurchaseLaunchResult.
    throw UnimplementedError('Google Play Billing is not connected yet.');
  }

  @override
  Future<RestorePurchaseResult> restorePurchases() {
    // TODO: Query previous Google Play purchases and verify active entitlement.
    // TODO: Integrate receipt/token verification API before granting access.
    throw UnimplementedError('Google Play Billing is not connected yet.');
  }

  @override
  Future<void> openSubscriptionManagement() {
    // TODO: Open Google Play subscription-management deep link.
    throw UnimplementedError('Google Play Billing is not connected yet.');
  }
}
