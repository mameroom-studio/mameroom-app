import 'package:flutter/material.dart';

import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../data/gateways/mock_premium_billing_gateway.dart';
import '../../domain/entities/premium_models.dart';
import '../controllers/premium_controller.dart';

class PremiumBenefitComparison extends StatelessWidget {
  const PremiumBenefitComparison({
    super.key,
    required this.onStartPremium,
    required this.onContinueFree,
  });

  final VoidCallback onStartPremium;
  final VoidCallback onContinueFree;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('premium-comparison'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumHero(title: 'FREE vs PREMIUM'),
        const SizedBox(height: 12),
        MameroomCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _PlanAvatar(label: 'FREE', crowned: false)),
                  Expanded(child: _PlanAvatar(label: 'PREMIUM', crowned: true)),
                ],
              ),
              const SizedBox(height: 10),
              ...premiumBenefits.map((benefit) => PremiumBenefitRow(benefit)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MameroomPrimaryButton(label: 'Premium 시작하기', onPressed: onStartPremium),
        const SizedBox(height: 8),
        MameroomSecondaryButton(
          label: '아니요, 계속 무료로 사용할래요',
          onPressed: onContinueFree,
        ),
      ],
    );
  }
}

class PremiumHero extends StatelessWidget {
  const PremiumHero({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return MameroomCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const MameroomBrandCharacter(
            expression: MameroomCharacterExpression.excited,
            size: 96,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: MameroomTypography.titleLarge.copyWith(
                    color: MameroomColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '학습 몰입을 위한 Premium 경험',
                  style: MameroomTypography.bodyMedium.copyWith(
                    color: MameroomColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumBenefitRow extends StatelessWidget {
  const PremiumBenefitRow(this.benefit, {super.key});

  final PremiumBenefit benefit;

  @override
  Widget build(BuildContext context) {
    final textStyle = MameroomTypography.caption.copyWith(
      color: MameroomColors.textPrimary,
      fontWeight: FontWeight.w800,
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: MameroomColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Row(
              children: [
                Icon(benefit.icon, size: 15, color: MameroomColors.primary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    benefit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              benefit.freeValue,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
          Expanded(
            child: Text(
              benefit.premiumValue,
              textAlign: TextAlign.center,
              style: textStyle.copyWith(color: MameroomColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumPlanSelector extends StatelessWidget {
  const PremiumPlanSelector({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onContinue,
    required this.onRestore,
    required this.onRetryProducts,
  });

  final PremiumPaywallState state;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;
  final VoidCallback onRestore;
  final VoidCallback onRetryProducts;

  @override
  Widget build(BuildContext context) {
    if (state.status == PremiumPurchaseStatus.productUnavailable) {
      return PurchaseStateView(
        status: PremiumPurchaseStatus.productUnavailable,
        primaryAction: onRetryProducts,
      );
    }
    return Column(
      key: const ValueKey('premium-plan-selector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumHero(title: '플랜을 선택하세요'),
        const SizedBox(height: 12),
        ...state.products.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PremiumPlanCard(
              product: product,
              selected: product.id == state.selectedProductId,
              onTap: () => onSelect(product.id),
            ),
          ),
        ),
        Text(
          '실제 결제는 Google Play 상품 등록 후 연결됩니다.',
          style: MameroomTypography.caption.copyWith(
            color: MameroomColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        MameroomPrimaryButton(
          label: '계속하기',
          onPressed: state.canLaunchPurchase ? onContinue : null,
        ),
        const SizedBox(height: 8),
        RestorePurchaseButton(onRestore: onRestore),
      ],
    );
  }
}

class PremiumPlanCard extends StatelessWidget {
  const PremiumPlanCard({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final PremiumProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '${product.title} ${selected ? "선택됨" : "선택 가능"}',
      child: MameroomInteractiveCard(
        selected: selected,
        disabled: !product.isAvailable,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.title,
                    style: MameroomTypography.titleMedium.copyWith(
                      color: MameroomColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (product.discountLabel != null)
                  PremiumBadge(label: product.discountLabel!),
                const SizedBox(width: 6),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? MameroomColors.primary
                      : MameroomColors.primarySoft,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: product.localizedPrice,
                style: MameroomTypography.titleLarge.copyWith(
                  color: MameroomColors.primary,
                  fontWeight: FontWeight.w900,
                ),
                children: [
                  TextSpan(
                    text: ' ${product.billingPeriod}',
                    style: MameroomTypography.bodyMedium.copyWith(
                      color: MameroomColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.description,
              style: MameroomTypography.caption.copyWith(
                color: MameroomColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            ...product.benefits
                .take(3)
                .map((benefit) => _CheckLine(text: benefit)),
          ],
        ),
      ),
    );
  }
}

class MockPurchaseHandoffView extends StatelessWidget {
  const MockPurchaseHandoffView({
    super.key,
    required this.selectedProduct,
    required this.onClose,
    required this.onLaunch,
  });

  final PremiumProduct? selectedProduct;
  final VoidCallback onClose;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('mock-purchase-handoff'),
      padding: const EdgeInsets.only(top: 12),
      child: MameroomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PremiumHero(title: 'Google Play 결제 준비'),
            const SizedBox(height: 12),
            Text(
              '현재는 개발 단계로 실제 결제가 진행되지 않습니다. 선택한 플랜의 결제 흐름을 미리 확인할 수 있어요.',
              style: MameroomTypography.bodyMedium.copyWith(
                color: MameroomColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _InfoPanel(
              icon: Icons.play_arrow_rounded,
              text: selectedProduct == null
                  ? '선택된 플랜이 없어요.'
                  : '${selectedProduct!.title} ${selectedProduct!.localizedPrice}',
            ),
            const SizedBox(height: 12),
            MameroomPrimaryButton(label: '결제 흐름 미리보기', onPressed: onLaunch),
            const SizedBox(height: 8),
            MameroomSecondaryButton(label: '닫기', onPressed: onClose),
          ],
        ),
      ),
    );
  }
}

class ProductLoadingView extends StatelessWidget {
  const ProductLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MameroomCard(
      key: ValueKey('product-loading'),
      child: Column(
        children: [
          MameroomSkeleton(width: 180, height: 22),
          SizedBox(height: 12),
          MameroomSkeleton(height: 96),
          SizedBox(height: 10),
          MameroomSkeleton(height: 96),
        ],
      ),
    );
  }
}

class PurchaseVerificationView extends StatelessWidget {
  const PurchaseVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return MameroomCard(
      key: const ValueKey('purchase-verification'),
      child: Column(
        children: [
          Text(
            '구매 정보를 확인하고 있어요',
            style: MameroomTypography.titleMedium.copyWith(
              color: MameroomColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const MameroomBrandCharacter(
            expression: MameroomCharacterExpression.thinking,
            size: 116,
          ),
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          const _CheckLine(text: '구매 정보를 확인 중입니다.'),
          const _CheckLine(text: '잠시만 기다려주세요.'),
          const _CheckLine(text: 'Premium 혜택을 준비하고 있어요.'),
        ],
      ),
    );
  }
}

class PremiumActivationView extends StatelessWidget {
  const PremiumActivationView({
    super.key,
    required this.entitlement,
    required this.onStart,
  });

  final PremiumEntitlement? entitlement;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final active = entitlement ?? mockEntitlement;
    return MameroomCard(
      key: const ValueKey('premium-activation-complete'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumHero(title: 'Premium 활성화 완료!'),
          const SizedBox(height: 12),
          _CheckLine(text: '${active.questionAllowance}문제/무제한 이용 가능'),
          if (active.adFree) const _CheckLine(text: '광고가 제거되었어요'),
          if (active.unlimitedReview)
            const _CheckLine(text: 'Premium 복습 접근 활성화'),
          if (active.premiumAnalysis) const _CheckLine(text: '고급 AI 분석 이용 가능'),
          if (active.roomDecorationAccess)
            const _CheckLine(text: '방 꾸미기 전체 이용 가능'),
          const SizedBox(height: 12),
          MameroomPrimaryButton(label: '시작하기', onPressed: onStart),
        ],
      ),
    );
  }
}

class PurchaseStateView extends StatelessWidget {
  const PurchaseStateView({
    super.key,
    required this.status,
    this.primaryAction,
  });

  final PremiumPurchaseStatus status;
  final VoidCallback? primaryAction;

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(status);
    return MameroomCard(
      key: ValueKey('purchase-state-${status.name}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(copy.icon, color: copy.color, size: 54),
          const SizedBox(height: 12),
          Text(
            copy.title,
            textAlign: TextAlign.center,
            style: MameroomTypography.titleMedium.copyWith(
              color: MameroomColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (copy.description != null) ...[
            const SizedBox(height: 8),
            Text(
              copy.description!,
              textAlign: TextAlign.center,
              style: MameroomTypography.bodyMedium.copyWith(
                color: MameroomColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          MameroomPrimaryButton(label: copy.button, onPressed: primaryAction),
        ],
      ),
    );
  }
}

class RestorePurchaseButton extends StatelessWidget {
  const RestorePurchaseButton({super.key, required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return MameroomSecondaryButton(
      label: '구매 복원',
      leadingIcon: Icons.restore_rounded,
      onPressed: onRestore,
    );
  }
}

class SubscriptionManagementView extends StatelessWidget {
  const SubscriptionManagementView({
    super.key,
    required this.entitlement,
    required this.onOpenManagement,
    required this.onRestore,
  });

  final PremiumEntitlement? entitlement;
  final VoidCallback onOpenManagement;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final active = entitlement ?? mockEntitlement;
    return Column(
      key: const ValueKey('subscription-management'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MameroomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '구독 관리',
                style: MameroomTypography.titleMedium.copyWith(
                  color: MameroomColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _InfoPanel(
                icon: Icons.workspace_premium_rounded,
                text: 'Premium (연간 플랜)',
              ),
              _InfoPanel(
                icon: Icons.verified_rounded,
                text: active.isActive ? '상태: 활성' : '상태: 비활성',
              ),
              _InfoPanel(icon: Icons.event_rounded, text: '다음 결제일: 2026.08.30'),
              const _InfoPanel(
                icon: Icons.store_rounded,
                text: '결제 스토어: Google Play',
              ),
              const _InfoPanel(
                icon: Icons.autorenew_rounded,
                text: '자동 갱신: 켜짐',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MameroomCard(
          child: Column(
            children: [
              _ManagementRow(label: '구독 정보', icon: Icons.receipt_long_rounded),
              _ManagementRow(label: '결제 내역', icon: Icons.history_rounded),
              _ManagementRow(
                label: '결제 수단 관리',
                icon: Icons.credit_card_off_rounded,
              ),
              _ManagementRow(
                label: '정기 결제 관리',
                icon: Icons.autorenew_rounded,
                onTap: onOpenManagement,
              ),
              _ManagementRow(label: '이용 약관', icon: Icons.description_rounded),
              _ManagementRow(
                label: '개인정보 처리방침',
                icon: Icons.privacy_tip_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MameroomBanner(
          message: '개발 단계 안내: 실제 Google Play 구독 관리는 아직 연결되지 않았습니다.',
          variant: MameroomFeedbackVariant.info,
        ),
        const SizedBox(height: 10),
        RestorePurchaseButton(onRestore: onRestore),
      ],
    );
  }
}

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MameroomColors.success.withValues(alpha: 0.16),
        borderRadius: MameroomRadius.pillRadius,
      ),
      child: Text(
        label,
        style: MameroomTypography.caption.copyWith(
          color: MameroomColors.success,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class PremiumDebugStateSelector extends StatelessWidget {
  const PremiumDebugStateSelector({
    super.key,
    required this.currentStatus,
    required this.onChanged,
  });

  final PremiumPurchaseStatus currentStatus;
  final ValueChanged<PremiumPurchaseStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return MameroomCard(
      child: DropdownButtonFormField<PremiumPurchaseStatus>(
        isExpanded: true,
        initialValue: currentStatus,
        decoration: const InputDecoration(labelText: '개발 상태 미리보기'),
        items: PremiumPurchaseStatus.values
            .map(
              (status) =>
                  DropdownMenuItem(value: status, child: Text(status.name)),
            )
            .toList(),
        onChanged: (status) {
          if (status != null) onChanged(status);
        },
      ),
    );
  }
}

class _PlanAvatar extends StatelessWidget {
  const _PlanAvatar({required this.label, required this.crowned});

  final String label;
  final bool crowned;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            MameroomBrandCharacter(
              expression: crowned
                  ? MameroomCharacterExpression.celebration
                  : MameroomCharacterExpression.neutral,
              size: 72,
            ),
            if (crowned)
              const Positioned(
                top: -10,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: MameroomColors.warning,
                ),
              ),
          ],
        ),
        Text(
          label,
          style: MameroomTypography.caption.copyWith(
            color: crowned
                ? MameroomColors.primary
                : MameroomColors.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: MameroomColors.success,
            size: 18,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: MameroomTypography.bodyMedium.copyWith(
                color: MameroomColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MameroomColors.primaryMist.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: MameroomColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: MameroomTypography.bodyMedium.copyWith(
                color: MameroomColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementRow extends StatelessWidget {
  const _ManagementRow({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: MameroomColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: MameroomTypography.bodyMedium.copyWith(
                  color: MameroomColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: MameroomColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

_StateCopy _copyFor(PremiumPurchaseStatus status) {
  return switch (status) {
    PremiumPurchaseStatus.cancelled => const _StateCopy(
      title: '구매가 취소되었어요.',
      description: '필요할 때 다시 시도할 수 있어요.',
      button: '확인',
      icon: Icons.close_rounded,
      color: MameroomColors.primary,
    ),
    PremiumPurchaseStatus.failed => const _StateCopy(
      title: '결제에 실패했어요.',
      description: '잠시 후 다시 시도해주세요.',
      button: '다시 시도',
      icon: Icons.error_rounded,
      color: MameroomColors.error,
    ),
    PremiumPurchaseStatus.pending => const _StateCopy(
      title: '결제가 보류 중이에요.',
      description: '결제 상태가 확인되면 Premium이 활성화됩니다.',
      button: '확인',
      icon: Icons.schedule_rounded,
      color: MameroomColors.warning,
    ),
    PremiumPurchaseStatus.alreadyOwned => const _StateCopy(
      title: '이미 Premium을 이용 중이에요.',
      button: '구독 관리',
      icon: Icons.verified_rounded,
      color: MameroomColors.success,
    ),
    PremiumPurchaseStatus.productUnavailable => const _StateCopy(
      title: '현재 플랜 정보를 불러올 수 없어요.',
      button: '다시 불러오기',
      icon: Icons.inventory_2_outlined,
      color: MameroomColors.warning,
    ),
    PremiumPurchaseStatus.networkError => const _StateCopy(
      title: '네트워크 연결을 확인해주세요.',
      button: '다시 시도',
      icon: Icons.wifi_off_rounded,
      color: MameroomColors.error,
    ),
    PremiumPurchaseStatus.verificationFailed => const _StateCopy(
      title: '구매 확인을 완료하지 못했어요.',
      description: '잠시 후 다시 확인해주세요.',
      button: '다시 확인',
      icon: Icons.policy_rounded,
      color: MameroomColors.error,
    ),
    PremiumPurchaseStatus.restoreInProgress => const _StateCopy(
      title: '구매 복원 중',
      description: '이전 구매 내역을 확인하고 있어요.',
      button: '확인',
      icon: Icons.sync_rounded,
      color: MameroomColors.primary,
    ),
    PremiumPurchaseStatus.restoreCompleted => const _StateCopy(
      title: '구매 복원이 완료되었어요.',
      button: '구독 관리',
      icon: Icons.check_circle_rounded,
      color: MameroomColors.success,
    ),
    PremiumPurchaseStatus.restoreEmpty => const _StateCopy(
      title: '복원할 구매가 없어요.',
      button: '확인',
      icon: Icons.inbox_rounded,
      color: MameroomColors.textMuted,
    ),
    _ => const _StateCopy(
      title: 'Premium 상태를 확인하고 있어요.',
      button: '확인',
      icon: Icons.info_rounded,
      color: MameroomColors.primary,
    ),
  };
}

class _StateCopy {
  const _StateCopy({
    required this.title,
    required this.button,
    required this.icon,
    required this.color,
    this.description,
  });

  final String title;
  final String? description;
  final String button;
  final IconData icon;
  final Color color;
}
