import 'package:flutter/material.dart';

import '../../../shared/design_system/theme/mameroom_theme_extension.dart';
import 'mameroom_modal.dart';
import 'mameroom_modal_theme.dart';

class MameroomRewardLine {
  const MameroomRewardLine({
    required this.label,
    required this.value,
    this.icon = Icons.monetization_on_rounded,
  });

  final String label;
  final String value;
  final IconData icon;
}

class MameroomPopupService {
  const MameroomPopupService._();

  static Future<void> showInfo(
    BuildContext context, {
    String title = _infoTitle,
    String message = _infoMessage,
  }) {
    return _show<void>(
      context,
      MameroomModal(
        title: title,
        message: message,
        variant: MameroomModalVariant.info,
        primaryButtonText: _ok,
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<void> showSuccess(
    BuildContext context, {
    String title = _successTitle,
    String message = _successMessage,
  }) {
    return _show<void>(
      context,
      MameroomModal(
        title: title,
        message: message,
        variant: MameroomModalVariant.success,
        primaryButtonText: _ok,
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<bool> showWarning(
    BuildContext context, {
    String title = _warningTitle,
    String message = _warningMessage,
    String confirmText = _ok,
  }) async {
    return await _show<bool>(
          context,
          MameroomModal(
            title: title,
            message: message,
            variant: MameroomModalVariant.warning,
            primaryButtonText: confirmText,
            secondaryButtonText: _cancel,
            primaryVariant: MameroomModalButtonVariant.warning,
            onPrimary: () => Navigator.of(context).pop(true),
            onSecondary: () => Navigator.of(context).pop(false),
          ),
        ) ??
        false;
  }

  static Future<void> showError(
    BuildContext context, {
    String title = _errorTitle,
    String message = _errorMessage,
  }) {
    return _show<void>(
      context,
      MameroomModal(
        title: title,
        message: message,
        variant: MameroomModalVariant.error,
        primaryButtonText: _ok,
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<bool> showConfirm(
    BuildContext context, {
    String title = _confirmTitle,
    String message = _confirmMessage,
    String confirmText = _delete,
  }) async {
    return await _show<bool>(
          context,
          MameroomModal(
            title: title,
            message: message,
            variant: MameroomModalVariant.confirm,
            secondaryButtonText: _cancel,
            destructiveButtonText: confirmText,
            onSecondary: () => Navigator.of(context).pop(false),
            onDestructive: () => Navigator.of(context).pop(true),
          ),
        ) ??
        false;
  }

  static Future<bool> showLogoutConfirm(BuildContext context) {
    return showConfirm(
      context,
      title: _logoutTitle,
      message: _logoutMessage,
      confirmText: _logoutTitle,
    );
  }

  static Future<void> showLevelUp(
    BuildContext context, {
    String level = _levelUpTitle,
    List<MameroomRewardLine> rewards = const [
      MameroomRewardLine(
        label: 'Diamond',
        value: '+50',
        icon: Icons.diamond_rounded,
      ),
      MameroomRewardLine(label: 'M-Coin', value: '+100'),
    ],
  }) {
    return _show<void>(
      context,
      MameroomModal(
        title: level,
        message: _rewardPaidMessage,
        variant: MameroomModalVariant.levelUp,
        icon: Icons.auto_awesome_rounded,
        customContent: _RewardList(rewards: rewards),
        primaryButtonText: _ok,
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<void> showReward(
    BuildContext context, {
    List<MameroomRewardLine> rewards = const [
      MameroomRewardLine(
        label: 'Diamond',
        value: '+30',
        icon: Icons.diamond_rounded,
      ),
      MameroomRewardLine(label: 'Memory Coin', value: '+100'),
    ],
  }) {
    return _show<void>(
      context,
      MameroomModal(
        title: _rewardTitle,
        message: _rewardMessage,
        variant: MameroomModalVariant.reward,
        icon: Icons.inventory_2_rounded,
        customContent: _RewardList(rewards: rewards),
        primaryButtonText: _ok,
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<void> showSeedGrowth(BuildContext context) {
    return _show<void>(
      context,
      MameroomModal(
        title: _seedGrowthTitle,
        message: _seedGrowthMessage,
        variant: MameroomModalVariant.seedGrowth,
        customContent: const _SeedGrowthPreview(),
        primaryButtonText: _ok,
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<void> showPurchaseComplete(
    BuildContext context, {
    String itemName = _defaultItemName,
    IconData itemIcon = Icons.chair_rounded,
  }) {
    return _show<void>(
      context,
      MameroomModal(
        title: _purchaseCompleteTitle,
        message: _purchaseCompleteMessage,
        variant: MameroomModalVariant.purchase,
        icon: itemIcon,
        customContent: Text(
          itemName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.mameroom.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        primaryButtonText: _ok,
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<bool> showPurchaseConfirm(
    BuildContext context, {
    String itemName = _defaultItemName,
    String itemDescription = _defaultItemDescription,
    int price = 100,
    int balance = 320,
    IconData itemIcon = Icons.chair_rounded,
  }) async {
    return await _show<bool>(
          context,
          MameroomModal(
            title: itemName,
            variant: MameroomModalVariant.purchase,
            icon: itemIcon,
            customContent: _PurchaseSummary(
              description: itemDescription,
              price: price,
              balance: balance,
            ),
            secondaryButtonText: _cancel,
            primaryButtonText: _buy,
            onSecondary: () => Navigator.of(context).pop(false),
            onPrimary: () => Navigator.of(context).pop(true),
          ),
        ) ??
        false;
  }

  static Future<void> showUploadComplete(BuildContext context) {
    return _show<void>(
      context,
      MameroomModal(
        title: _uploadCompleteTitle,
        message: _uploadCompleteMessage,
        variant: MameroomModalVariant.success,
        icon: Icons.description_rounded,
        primaryButtonText: _ok,
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<void> showGenerating(
    BuildContext context, {
    double progress = 0.75,
    VoidCallback? onCancel,
  }) {
    final percent = '\${(progress * 100).round()}%';
    return _show<void>(
      context,
      MameroomModal(
        title: _generatingTitle,
        message: _generatingMessage,
        variant: MameroomModalVariant.loading,
        showCloseButton: false,
        customContent: MameroomModalProgress(value: progress, label: percent),
        secondaryButtonText: _cancel,
        onSecondary: onCancel ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<void> showEmptyState(
    BuildContext context, {
    VoidCallback? onUpload,
  }) {
    return _show<void>(
      context,
      MameroomModal(
        title: _emptyTitle,
        message: _emptyMessage,
        variant: MameroomModalVariant.empty,
        primaryButtonText: _uploadButton,
        onPrimary: onUpload ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<void> showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    return _show<void>(
      context,
      MameroomModal(
        title: _networkErrorTitle,
        message: _networkErrorMessage,
        variant: MameroomModalVariant.networkError,
        primaryButtonText: _retry,
        onPrimary: onRetry ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<T?> _show<T>(BuildContext context, Widget child) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: _close,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => child,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _RewardList extends StatelessWidget {
  const _RewardList({required this.rewards});

  final List<MameroomRewardLine> rewards;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      children: [
        for (final reward in rewards)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colors.cloud,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(reward.icon, color: colors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reward.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  reward.value,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SeedGrowthPreview extends StatelessWidget {
  const _SeedGrowthPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    const stages = [
      Icons.circle,
      Icons.grass_rounded,
      Icons.eco_rounded,
      Icons.local_florist_rounded,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          _SeedStage(icon: stages[i]),
          if (i != stages.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.arrow_forward_rounded, color: colors.primary),
            ),
        ],
      ],
    );
  }
}

class _SeedStage extends StatelessWidget {
  const _SeedStage({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.seedGreen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: colors.seedGreen),
    );
  }
}

class _PurchaseSummary extends StatelessWidget {
  const _PurchaseSummary({
    required this.description,
    required this.price,
    required this.balance,
  });

  final String description;
  final int price;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      children: [
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond_rounded, color: colors.primary, size: 19),
            const SizedBox(width: 5),
            Text(
              _comma(price),
              style: TextStyle(color: colors.ink, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '$_ownedPrefix: \${_comma(balance)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _purchaseQuestion,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.ink,
            height: 1.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _comma(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

const _infoTitle = '\uC54C\uB9BC';
const _infoMessage =
    '\uC791\uC5C5\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.';
const _successTitle = '\uC644\uB8CC!';
const _successMessage =
    '\uBB38\uC81C \uC0DD\uC131\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.';
const _warningTitle = '\uC8FC\uC758';
const _warningMessage =
    '\uC815\uB9D0\uB85C \uC774 \uC791\uC5C5\uC744 \uC9C4\uD589\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?';
const _errorTitle = '\uC624\uB958';
const _errorMessage =
    '\uB124\uD2B8\uC6CC\uD06C \uC5F0\uACB0\uC744 \uD655\uC778\uD558\uACE0 \uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.';
const _confirmTitle = '\uD655\uC778';
const _confirmMessage =
    '\uC815\uB9D0\uB85C \uC0AD\uC81C\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?\n\uC774 \uC791\uC5C5\uC740 \uB418\uB3CC\uB9B4 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.';
const _logoutTitle = '\uB85C\uADF8\uC544\uC6C3';
const _logoutMessage =
    '\uC815\uB9D0\uB85C \uB85C\uADF8\uC544\uC6C3 \uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?';
const _levelUpTitle = 'Lv.20 \uB2EC\uC131!';
const _rewardPaidMessage =
    '\uBCF4\uC0C1\uC774 \uC9C0\uAE09\uB418\uC5C8\uC2B5\uB2C8\uB2E4.';
const _rewardTitle = '\uBCF4\uC0C1 \uD68D\uB4DD!';
const _rewardMessage =
    '\uB2E4\uC74C \uBCF4\uC0C1\uC744 \uD68D\uB4DD\uD588\uC2B5\uB2C8\uB2E4.';
const _seedGrowthTitle =
    '\uAE30\uC5B5\uC528\uC557\uC774 \uC131\uC7A5\uD588\uC5B4\uC694!';
const _seedGrowthMessage =
    '\uC0C8\uB85C\uC6B4 \uBAA8\uC2B5\uC73C\uB85C \uC790\uB790\uC2B5\uB2C8\uB2E4.';
const _purchaseCompleteTitle = '\uAD6C\uB9E4 \uC644\uB8CC!';
const _purchaseCompleteMessage =
    '\uC544\uC774\uD15C\uC774 \uB0B4 \uBC29\uC73C\uB85C \uC9C0\uAE09\uB418\uC5C8\uC2B5\uB2C8\uB2E4.';
const _defaultItemName = '\uAE30\uBCF8 \uC758\uC790';
const _defaultItemDescription = '\uC791\uC740 \uACF5\uBD80 \uC758\uC790';
const _uploadCompleteTitle = '\uC5C5\uB85C\uB4DC \uC644\uB8CC';
const _uploadCompleteMessage =
    '\uC790\uB8CC \uC5C5\uB85C\uB4DC\uAC00 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.';
const _generatingTitle = '\uBB38\uC81C \uC0DD\uC131 \uC911';
const _generatingMessage =
    'AI\uAC00 \uBB38\uC81C\uB97C \uC0DD\uC131\uD558\uACE0 \uC788\uC5B4\uC694.';
const _emptyTitle = '\uC544\uC9C1 \uC790\uB8CC\uAC00 \uC5C6\uC5B4\uC694';
const _emptyMessage =
    '\uC0C8 \uC790\uB8CC\uB97C \uC5C5\uB85C\uB4DC\uD558\uC5EC\n\uD559\uC2B5\uC744 \uC2DC\uC791\uD574\uBCF4\uC138\uC694.';
const _networkErrorTitle = '\uC5F0\uACB0\uC774 \uBD88\uC548\uC815\uD574\uC694';
const _networkErrorMessage =
    '\uC778\uD130\uB137 \uC5F0\uACB0\uC744 \uD655\uC778\uD558\uACE0\n\uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.';
const _ok = '\uD655\uC778';
const _cancel = '\uCDE8\uC18C';
const _delete = '\uC0AD\uC81C';
const _buy = '\uAD6C\uB9E4\uD558\uAE30';
const _uploadButton = '\uC790\uB8CC \uC5C5\uB85C\uB4DC';
const _retry = '\uB2E4\uC2DC \uC2DC\uB3C4';
const _close = '\uB2EB\uAE30';
const _ownedPrefix = '\uBCF4\uC720';
const _purchaseQuestion =
    '\uD574\uB2F9 \uC544\uC774\uD15C\uC744\n\uAD6C\uB9E4\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?';
