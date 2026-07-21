import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../domain/entities/premium_models.dart';
import '../controllers/premium_controller.dart';
import '../widgets/premium_paywall_widgets.dart';

class MameroomPaywallPage extends ConsumerStatefulWidget {
  const MameroomPaywallPage({
    super.key,
    this.entryPoint = PaywallEntryPoint.myPlan,
    this.initialPreviewStatus,
  });

  static const routePath = '/premium';

  final PaywallEntryPoint entryPoint;
  final PremiumPurchaseStatus? initialPreviewStatus;

  @override
  ConsumerState<MameroomPaywallPage> createState() =>
      _MameroomPaywallPageState();
}

class _MameroomPaywallPageState extends ConsumerState<MameroomPaywallPage> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final controller = ref.read(premiumControllerProvider.notifier);
      await controller.loadProducts();
      final preview = widget.initialPreviewStatus;
      if (preview != null && kDebugMode) controller.setPreviewStatus(preview);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(premiumControllerProvider);
    final controller = ref.read(premiumControllerProvider.notifier);
    final terminalView = _terminalView(context, state, controller);

    return Scaffold(
      backgroundColor: MameroomColors.surfaceMuted,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _PaywallAppBar(
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/my'),
                  onManage: () => setState(() => _step = 2),
                ),
                Expanded(
                  child: ListView(
                    key: const ValueKey('premium-scroll'),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    children: [
                      Text(
                        paywallEntryMessage(widget.entryPoint),
                        style: MameroomTypography.bodyMedium.copyWith(
                          color: MameroomColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (terminalView != null)
                        terminalView
                      else if (_step == 0)
                        PremiumBenefitComparison(
                          onStartPremium: () => setState(() => _step = 1),
                          onContinueFree: () => context.canPop()
                              ? context.pop()
                              : context.go('/home'),
                        )
                      else if (_step == 1)
                        PremiumPlanSelector(
                          state: state,
                          onSelect: controller.selectProduct,
                          onContinue: controller.showPurchaseHandoff,
                          onRestore: controller.restorePurchases,
                          onRetryProducts: controller.loadProducts,
                        )
                      else
                        SubscriptionManagementView(
                          entitlement: state.entitlement,
                          onOpenManagement:
                              controller.openSubscriptionManagement,
                          onRestore: controller.restorePurchases,
                        ),
                      if (state.showHandoff)
                        MockPurchaseHandoffView(
                          selectedProduct: state.selectedProduct,
                          onClose: controller.hidePurchaseHandoff,
                          onLaunch: controller.launchSelectedPurchase,
                        ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 12),
                        PremiumDebugStateSelector(
                          currentStatus: state.status,
                          onChanged: controller.setPreviewStatus,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _terminalView(
    BuildContext context,
    PremiumPaywallState state,
    PremiumController controller,
  ) {
    return switch (state.status) {
      PremiumPurchaseStatus.loadingProducts => const ProductLoadingView(),
      PremiumPurchaseStatus.launchingPurchase ||
      PremiumPurchaseStatus.verifying ||
      PremiumPurchaseStatus.activatingEntitlement =>
        const PurchaseVerificationView(),
      PremiumPurchaseStatus.completed => PremiumActivationView(
        entitlement: state.entitlement,
        onStart: () =>
            context.canPop() ? context.pop(true) : context.go('/home'),
      ),
      PremiumPurchaseStatus.restoreInProgress => const PurchaseStateView(
        status: PremiumPurchaseStatus.restoreInProgress,
      ),
      PremiumPurchaseStatus.restoreCompleted => PurchaseStateView(
        status: PremiumPurchaseStatus.restoreCompleted,
        primaryAction: () => setState(() => _step = 2),
      ),
      PremiumPurchaseStatus.restoreEmpty => PurchaseStateView(
        status: PremiumPurchaseStatus.restoreEmpty,
        primaryAction: () => setState(() => _step = 1),
      ),
      PremiumPurchaseStatus.cancelled ||
      PremiumPurchaseStatus.failed ||
      PremiumPurchaseStatus.pending ||
      PremiumPurchaseStatus.alreadyOwned ||
      PremiumPurchaseStatus.productUnavailable ||
      PremiumPurchaseStatus.networkError ||
      PremiumPurchaseStatus.verificationFailed => PurchaseStateView(
        status: state.status,
        primaryAction: () {
          if (state.status == PremiumPurchaseStatus.alreadyOwned) {
            setState(() => _step = 2);
          } else if (state.status == PremiumPurchaseStatus.productUnavailable) {
            controller.loadProducts();
          } else {
            setState(() => _step = 1);
          }
        },
      ),
      PremiumPurchaseStatus.idle || PremiumPurchaseStatus.ready => null,
    };
  }
}

class _PaywallAppBar extends StatelessWidget {
  const _PaywallAppBar({required this.onBack, required this.onManage});

  final VoidCallback onBack;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: '뒤로',
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAMEROOM',
                  style: MameroomTypography.titleMedium.copyWith(
                    color: MameroomColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Premium / Google Play',
                  style: MameroomTypography.caption.copyWith(
                    color: MameroomColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onManage, child: const Text('구독 관리')),
        ],
      ),
    );
  }
}

PaywallEntryPoint paywallEntryPointFromString(String? value) {
  for (final entry in PaywallEntryPoint.values) {
    if (entry.name == value) return entry;
  }
  return PaywallEntryPoint.myPlan;
}

PremiumPurchaseStatus? premiumStatusFromString(String? value) {
  for (final status in PremiumPurchaseStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}
