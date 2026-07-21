import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/modals/mameroom_modals.dart';
import '../../coins/presentation/providers/coin_providers.dart';
import '../domain/promotion_redemption.dart';
import 'promotion_providers.dart';

class PromotionCodePage extends ConsumerStatefulWidget {
  const PromotionCodePage({super.key});
  static const routePath = '/settings/promotion';
  @override
  ConsumerState<PromotionCodePage> createState() => _PromotionCodePageState();
}

class _PromotionCodePageState extends ConsumerState<PromotionCodePage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _lastSuccess;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('프로모션 코드')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '프로모션 코드를 입력하고 Mameroom 혜택을 받아보세요.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('promotion-code-input'),
              controller: _controller,
              maxLength: 64,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              enabled: !_loading,
              onSubmitted: (_) => _redeem(),
              decoration: const InputDecoration(
                labelText: '프로모션 코드',
                hintText: '코드를 입력해 주세요',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('promotion-redeem'),
              onPressed: _loading ? null : _redeem,
              child: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('적용하기'),
            ),
            const SizedBox(height: 16),
            const Text('• 코드는 계정별 사용 횟수가 제한될 수 있습니다.\n• 지급 혜택은 코드마다 다릅니다.'),
          ],
        ),
      ),
    ),
  );

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.length < 3 || code.length > 64 || _lastSuccess == code) {
      await MameroomPopupService.showError(
        context,
        title: '코드를 확인해 주세요',
        message: _lastSuccess == code ? '이미 적용한 코드입니다.' : '사용할 코드를 입력해 주세요.',
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref.read(promotionRepositoryProvider).redeem(code);
      if (!mounted) return;
      if (result.success) {
        _lastSuccess = code;
        ref.invalidate(coinWalletProvider);
        await MameroomPopupService.showSuccess(
          context,
          title: '프로모션 코드가 적용되었습니다.',
          message: result.reward?.type == 'MCOIN'
              ? 'M-Coin ${result.reward!.value}개가 지급되었습니다.'
              : '${result.reward?.displayText ?? '보상'}이 지급되었습니다.',
        );
      } else {
        await MameroomPopupService.showError(
          context,
          title: '코드를 적용할 수 없어요',
          message: _message(result.status),
        );
      }
    } catch (_) {
      if (mounted) {
        await MameroomPopupService.showError(
          context,
          title: '코드를 적용할 수 없어요',
          message: '네트워크 연결을 확인한 후 다시 시도해주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(PromotionRedemptionStatus status) => switch (status) {
    PromotionRedemptionStatus.invalidCode => '사용할 수 없는 코드입니다.',
    PromotionRedemptionStatus.alreadyUsed => '이미 사용한 코드입니다.',
    PromotionRedemptionStatus.notStarted => '아직 사용할 수 없는 코드입니다.',
    PromotionRedemptionStatus.expired => '이벤트가 종료되었습니다.',
    PromotionRedemptionStatus.limitExceeded => '프로모션 사용이 마감되었습니다.',
    PromotionRedemptionStatus.userLimitExceeded => '이 코드는 더 이상 사용할 수 없습니다.',
    PromotionRedemptionStatus.disabled => '사용할 수 없는 코드입니다.',
    PromotionRedemptionStatus.rewardFailed => '보상 지급에 실패했습니다.',
    _ => '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
  };
}
