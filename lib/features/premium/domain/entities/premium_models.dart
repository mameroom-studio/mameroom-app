import 'package:flutter/material.dart';

enum PremiumPlanType { monthly, annual }

enum PremiumPurchaseStatus {
  idle,
  loadingProducts,
  ready,
  launchingPurchase,
  pending,
  verifying,
  activatingEntitlement,
  completed,
  cancelled,
  failed,
  verificationFailed,
  alreadyOwned,
  productUnavailable,
  networkError,
  restoreInProgress,
  restoreCompleted,
  restoreEmpty,
}

enum PaywallEntryPoint {
  questionLimit,
  premiumAnalysis,
  adRemoval,
  unlimitedReview,
  seedGrowth,
  roomDecoration,
  myPlan,
  campaign,
}

enum PurchaseLaunchResultType {
  completed,
  cancelled,
  failed,
  pending,
  alreadyOwned,
  productUnavailable,
  networkError,
  verificationFailed,
}

enum RestorePurchaseResultType { completed, empty, failed, networkError }

class PremiumProduct {
  const PremiumProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.localizedPrice,
    required this.billingPeriod,
    required this.planType,
    required this.benefits,
    this.introductoryOffer,
    this.trialDescription,
    this.discountLabel,
    this.isRecommended = false,
    this.isAvailable = true,
  });

  final String id;
  final String title;
  final String description;
  final String localizedPrice;
  final String billingPeriod;
  final PremiumPlanType planType;
  final List<String> benefits;
  final String? introductoryOffer;
  final String? trialDescription;
  final String? discountLabel;
  final bool isRecommended;
  final bool isAvailable;
}

class PremiumBenefit {
  const PremiumBenefit({
    required this.title,
    required this.freeValue,
    required this.premiumValue,
    required this.icon,
    this.isHighlighted = false,
  });

  final String title;
  final String freeValue;
  final String premiumValue;
  final IconData icon;
  final bool isHighlighted;
}

class PremiumEntitlement {
  const PremiumEntitlement({
    required this.planType,
    required this.isActive,
    required this.questionAllowance,
    required this.adFree,
    required this.unlimitedReview,
    required this.premiumAnalysis,
    required this.seedGrowthMultiplier,
    required this.roomDecorationAccess,
    this.renewalDate,
    this.expirationDate,
  });

  final PremiumPlanType planType;
  final bool isActive;
  final int questionAllowance;
  final bool adFree;
  final bool unlimitedReview;
  final bool premiumAnalysis;
  final double seedGrowthMultiplier;
  final bool roomDecorationAccess;
  final DateTime? renewalDate;
  final DateTime? expirationDate;
}

class PurchaseLaunchResult {
  const PurchaseLaunchResult(this.type, {this.message});

  final PurchaseLaunchResultType type;
  final String? message;
}

class RestorePurchaseResult {
  const RestorePurchaseResult(this.type, {this.entitlement});

  final RestorePurchaseResultType type;
  final PremiumEntitlement? entitlement;
}

class PurchaseRecord {
  const PurchaseRecord({
    required this.productId,
    required this.purchasedAt,
    required this.isActive,
  });

  final String productId;
  final DateTime purchasedAt;
  final bool isActive;
}

const premiumBenefits = <PremiumBenefit>[
  PremiumBenefit(
    title: '월 제공 문제 수',
    freeValue: '30문제',
    premiumValue: '300문제/무제한',
    icon: Icons.quiz_rounded,
    isHighlighted: true,
  ),
  PremiumBenefit(
    title: 'AI 분석',
    freeValue: '기본',
    premiumValue: '고급 분석',
    icon: Icons.psychology_alt_rounded,
    isHighlighted: true,
  ),
  PremiumBenefit(
    title: '복습 리마인드',
    freeValue: '기본 알림',
    premiumValue: '맞춤 리마인드',
    icon: Icons.notifications_active_rounded,
  ),
  PremiumBenefit(
    title: '광고 제거',
    freeValue: '노출',
    premiumValue: '광고 없음',
    icon: Icons.block_rounded,
    isHighlighted: true,
  ),
  PremiumBenefit(
    title: '씨앗 성장 가속',
    freeValue: '기본',
    premiumValue: '2배 성장',
    icon: Icons.eco_rounded,
  ),
  PremiumBenefit(
    title: '방 꾸미기 아이템',
    freeValue: '제한',
    premiumValue: '전체 이용',
    icon: Icons.chair_rounded,
  ),
];
