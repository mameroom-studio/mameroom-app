const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'lib/features/home/presentation/pages/my_info_page.dart');
const content = String.raw`import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../coins/presentation/providers/coin_providers.dart';

class MyInfoPage extends ConsumerStatefulWidget {
  const MyInfoPage({
    super.key,
    this.initialRemainingQuestions = 320,
    this.initialPromotionApplied = false,
    this.initialSettingsExpanded = true,
  });

  final int initialRemainingQuestions;
  final bool initialPromotionApplied;
  final bool initialSettingsExpanded;

  @override
  ConsumerState<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends ConsumerState<MyInfoPage> {
  late final TextEditingController _promotionController;
  late int _remainingQuestions;
  late bool _promotionApplied;
  late bool _promotionExpanded;
  bool _soundEnabled = true;
  bool _alertEnabled = true;

  @override
  void initState() {
    super.initState();
    _remainingQuestions = widget.initialRemainingQuestions;
    _promotionApplied = widget.initialPromotionApplied;
    _promotionExpanded = widget.initialPromotionApplied;
    _promotionController = TextEditingController(
      text: _promotionApplied ? 'MAME2025' : '',
    );
  }

  @override
  void dispose() {
    _promotionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final wallet = ref.watch(coinWalletProvider).asData?.value;
    final authState = ref.watch(authControllerProvider);
    final emailName = user?.email?.split('@').first;
    final displayName = (emailName == null || emailName.isEmpty)
        ? _nickname
        : emailName;
    final coinBalance = wallet?.balance ?? 0;

    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _MyMetrics.from(constraints);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.sidePadding,
                  metrics.topPadding,
                  metrics.sidePadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: metrics.headerHeight, child: const _MyHeader()),
                    SizedBox(height: metrics.gap),
                    Expanded(
                      child: CustomScrollView(
                        key: const ValueKey('my-page-scroll'),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _ProfileCard(displayName: displayName),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: metrics.gap)),
                          SliverToBoxAdapter(
                            child: _CurrencyCard(coinBalance: coinBalance),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: metrics.gap)),
                          SliverToBoxAdapter(
                            child: _UsageStatusCard(
                              remainingQuestions: _remainingQuestions,
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: metrics.gap)),
                          const SliverToBoxAdapter(child: _LearningStatsCard()),
                          SliverToBoxAdapter(child: SizedBox(height: metrics.gap)),
                          SliverToBoxAdapter(
                            child: _SettingsCard(
                              soundEnabled: _soundEnabled,
                              alertEnabled: _alertEnabled,
                              onSoundChanged: (value) =>
                                  setState(() => _soundEnabled = value),
                              onAlertChanged: (value) =>
                                  setState(() => _alertEnabled = value),
                              onLogout: authState.isLoading
                                  ? null
                                  : () => _showLogoutDialog(context, ref),
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: metrics.gap)),
                          SliverToBoxAdapter(
                            child: _PromotionCard(
                              controller: _promotionController,
                              applied: _promotionApplied,
                              expanded: _promotionExpanded,
                              onToggleExpanded: () => setState(
                                () => _promotionExpanded = !_promotionExpanded,
                              ),
                              onApply: () => setState(() {
                                _promotionApplied = true;
                                _promotionExpanded = true;
                                if (_promotionController.text.trim().isEmpty) {
                                  _promotionController.text = 'MAME2025';
                                }
                              }),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.bottomSpace),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => const _LogoutDialog(),
    );
    if (shouldLogout != true || !context.mounted) {
      return;
    }
    await ref.read(authControllerProvider.notifier).signOut();
    if (context.mounted) {
      context.go(LoginPage.routePath);
    }
  }
}

class _MyMetrics {
  const _MyMetrics({
    required this.sidePadding,
    required this.topPadding,
    required this.headerHeight,
    required this.gap,
    required this.bottomSpace,
  });

  final double sidePadding;
  final double topPadding;
  final double headerHeight;
  final double gap;
  final double bottomSpace;

  static _MyMetrics from(BoxConstraints constraints) {
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 390.0;
    final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 844.0;
    final dense = width < 380 || height < 820;
    return _MyMetrics(
      sidePadding: width < 380 ? 14 : 18,
      topPadding: dense ? 8 : 12,
      headerHeight: dense ? 40 : 44,
      gap: dense ? 8 : 10,
      bottomSpace: dense ? 14 : 18,
    );
  }
}

class _MyHeader extends StatelessWidget {
  const _MyHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Expanded(
          child: Text(
            _myTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _IconButtonBox(
          icon: Icons.notifications_none_rounded,
          tooltip: _notifications,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _Card(
      child: Row(
        children: [
          const _PixelAvatar(size: 76),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _LevelBadge(label: 'Lv.18'),
                  ],
                ),
                const SizedBox(height: 7),
                _IconText(
                  icon: Icons.local_fire_department_rounded,
                  text: _streak,
                  color: Colors.orange,
                ),
                const SizedBox(height: 4),
                _IconText(
                  icon: Icons.psychology_alt_rounded,
                  text: _memoryRate,
                  color: colors.primary,
                ),
                const SizedBox(height: 4),
                _IconText(icon: Icons.school_rounded, text: _school, color: colors.seedGreen),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      label: const Text(_profileEdit),
                    ),
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

class _CurrencyCard extends StatelessWidget {
  const _CurrencyCard({required this.coinBalance});

  final int coinBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: colors.sun, size: 26),
              const SizedBox(width: 8),
              Expanded(child: _CardTitleText(_mCoin)),
              TextButton(onPressed: () {}, child: const Text(_history)),
            ],
          ),
          const SizedBox(height: 8),
          _CurrencyLine(label: _currentBalance, value: _comma(coinBalance)),
          const SizedBox(height: 5),
          const _CurrencyLine(label: _weeklyEarned, value: '+120'),
          const SizedBox(height: 5),
          const _CurrencyLine(label: _totalSpent, value: '430'),
        ],
      ),
    );
  }
}

class _UsageStatusCard extends StatelessWidget {
  const _UsageStatusCard({required this.remainingQuestions});

  final int remainingQuestions;

  @override
  Widget build(BuildContext context) {
    final isLow = remainingQuestions <= 0;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitleText(_usageTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: _InfoLine(label: _currentPlan, value: 'Free')),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoLine(
                  label: _remainingGeneration,
                  value: '$remainingQuestions$_questionUnit',
                  valueColor: isLow ? Colors.redAccent : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _InfoLine(label: _thisMonthUsage, value: '180 / 500$_questionUnit')),
              SizedBox(width: 10),
              Expanded(child: _InfoLine(label: _nextResetShort, value: '2026.08.01')),
            ],
          ),
          if (isLow) ...[
            const SizedBox(height: 10),
            const _WarningBanner(),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: () {},
              child: const Text(_chargeQuestions),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningStatsCard extends StatelessWidget {
  const _LearningStatsCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitleText(_learningStats),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatTile(label: _totalSolved, value: '2,341')),
              SizedBox(width: 8),
              Expanded(child: _StatTile(label: _correctRate, value: '84%')),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatTile(label: _streakShort, value: '24$_dayUnit')),
              SizedBox(width: 8),
              Expanded(child: _StatTile(label: _totalStudyTime, value: '18$_hourUnit')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.controller,
    required this.applied,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onApply,
  });

  final TextEditingController controller;
  final bool applied;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggleExpanded,
            child: Row(
              children: [
                Icon(Icons.card_giftcard_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: _CardTitleText(_promotionTitle)),
                if (applied)
                  Text(
                    _applied,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.seedGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: colors.muted,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: _promotionHint,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: onApply,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(_apply),
                  ),
                ),
              ],
            ),
            if (applied) ...[
              const SizedBox(height: 8),
              Text(
                _promotionSuccessBody,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.seedGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.soundEnabled,
    required this.alertEnabled,
    required this.onSoundChanged,
    required this.onAlertChanged,
    required this.onLogout,
  });

  final bool soundEnabled;
  final bool alertEnabled;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onAlertChanged;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitleText(_settings),
          const SizedBox(height: 6),
          _SettingRow.switcher(
            label: _notifications,
            value: alertEnabled,
            onChanged: onAlertChanged,
          ),
          _SettingRow.switcher(
            label: _sound,
            value: soundEnabled,
            onChanged: onSoundChanged,
          ),
          const _SettingRow.navigation(label: _languageSettings, trailingText: _korean),
          const _SettingRow.navigation(label: _contact),
          const _SettingRow.navigation(label: _terms),
          const _SettingRow.navigation(label: _privacy),
          _SettingRow.logout(onTap: onLogout),
        ],
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PixelAvatar(size: 78),
            const SizedBox(height: 12),
            Text(
              _logout,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _logoutQuestion,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(_cancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(_logout),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.09),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lowQuestionBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitleText extends StatelessWidget {
  const _CardTitleText(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: context.mameroom.ink,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _CurrencyLine extends StatelessWidget {
  const _CurrencyLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.primaryMist.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: valueColor ?? colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primaryMist.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow.switcher({
    required this.label,
    required this.value,
    required this.onChanged,
  }) : onTap = null,
       trailingText = null,
       isLogout = false;

  const _SettingRow.navigation({required this.label, this.trailingText, this.onTap})
    : value = null,
      onChanged = null,
      isLogout = false;

  const _SettingRow.logout({this.onTap})
    : label = _logout,
      value = null,
      trailingText = null,
      onChanged = null,
      isLogout = true;

  final String label;
  final bool? value;
  final String? trailingText;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onChanged;
  final bool isLogout;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final textColor = isLogout ? Colors.redAccent : colors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onChanged != null)
              Transform.scale(
                scale: 0.82,
                child: Switch(value: value ?? false, onChanged: onChanged),
              )
            else ...[
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                isLogout ? Icons.logout_rounded : Icons.chevron_right_rounded,
                color: textColor,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryMist.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PixelAvatar extends StatelessWidget {
  const _PixelAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryMist.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: colors.primaryPale),
      ),
      child: Icon(Icons.face_rounded, size: size * 0.58, color: colors.ink),
    );
  }
}

class _IconButtonBox extends StatelessWidget {
  const _IconButtonBox({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: colors.ink),
      style: IconButton.styleFrom(
        backgroundColor: colors.paper,
        side: BorderSide(color: colors.line),
        fixedSize: const Size.square(38),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(12)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
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

const _myTitle = '내 정보';
const _settings = '설정';
const _notifications = '알림';
const _nickname = '김유이';
const _streak = '연속 학습 24일';
const _streakShort = '연속 학습';
const _school = '마메고등학교 2학년';
const _memoryRate = '기억률 84%';
const _profileEdit = '프로필 수정';
const _usageTitle = '이용 현황';
const _currentPlan = '현재 플랜';
const _remainingGeneration = '남은 생성량';
const _thisMonthUsage = '이번 달 사용';
const _nextResetShort = '다음 리셋';
const _chargeQuestions = '문제 충전하기';
const _lowQuestionBody = '남은 생성량이 부족합니다. 문제를 충전하고 계속 공부하세요.';
const _currencyTitle = '보유 재화';
const _mCoin = 'M-Coin';
const _currentBalance = '현재 보유';
const _weeklyEarned = '이번 주 획득';
const _totalSpent = '총 사용';
const _history = '사용 내역';
const _promotionTitle = '프로모션 코드';
const _promotionHint = '프로모션 코드 입력';
const _apply = '적용';
const _applied = '적용됨';
const _promotionSuccessBody = '+200문제가 추가되었습니다.';
const _sound = '사운드';
const _languageSettings = '언어';
const _korean = '한국어';
const _contact = '문의하기';
const _terms = '이용약관';
const _privacy = '개인정보처리방침';
const _logout = '로그아웃';
const _logoutQuestion = '정말 로그아웃하시겠습니까?';
const _cancel = '취소';
const _learningStats = '학습 통계';
const _totalSolved = '총 풀이 문제';
const _correctRate = '정답률';
const _totalStudyTime = '누적 학습 시간';
const _questionUnit = '문제';
const _dayUnit = '일';
const _hourUnit = '시간';
`;
fs.writeFileSync(file, content);
