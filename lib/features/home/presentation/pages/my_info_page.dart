import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/modals/mameroom_modals.dart';
import '../../../../shared/design_system/components/mameroom_icons.dart';
import '../../../../shared/design_system/tokens/mameroom_icon_sizes.dart';
import '../../../../shared/design_system/tokens/mameroom_radius.dart';
import '../../../../shared/design_system/tokens/mameroom_spacing.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../coins/presentation/providers/coin_providers.dart';
import '../../../achievements/presentation/pages/achievement_page.dart';
import '../../../premium/presentation/pages/mameroom_paywall_page.dart';
import '../../../profile/presentation/edit_profile_page.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../../promotions/presentation/promotion_code_page.dart';
import '../../../notices/presentation/notice_list_page.dart';
import '../../../settings/presentation/open_source_license_page.dart';
import '../../../settings/presentation/version_info_page.dart';
import '../../../support/presentation/support_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

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
  late int _remainingQuestions;
  bool _soundEnabled = true;
  bool _alertEnabled = true;

  @override
  void initState() {
    super.initState();
    _remainingQuestions = widget.initialRemainingQuestions;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final wallet = ref.watch(coinWalletProvider).asData?.value;
    final authState = ref.watch(authControllerProvider);
    final profile = ref.watch(profileEditProvider).asData?.value;
    final emailName = user?.email?.split('@').first;
    final fallbackName = (emailName == null || emailName.isEmpty)
        ? _nickname
        : emailName;
    final displayName = profile?.nickname ?? fallbackName;
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
                    SizedBox(
                      height: metrics.headerHeight,
                      child: const _MyHeader(),
                    ),
                    SizedBox(height: metrics.gap),
                    Expanded(
                      child: CustomScrollView(
                        key: const ValueKey('my-page-scroll'),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _ProfileCard(
                              displayName: displayName,
                              onEdit: () async {
                                final changed = await context.push<bool>(
                                  EditProfilePage.routePath,
                                );
                                if (changed == true) {
                                  ref.invalidate(profileEditProvider);
                                }
                              },
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.gap),
                          ),
                          SliverToBoxAdapter(
                            child: _CurrencyCard(coinBalance: coinBalance),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.gap),
                          ),
                          SliverToBoxAdapter(
                            child: _UsageStatusCard(
                              remainingQuestions: _remainingQuestions,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.gap),
                          ),
                          const SliverToBoxAdapter(child: _LearningStatsCard()),
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.gap),
                          ),
                          SliverToBoxAdapter(
                            child: _AchievementEntryCard(
                              onTap: () =>
                                  context.push(AchievementPage.routePath),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.gap),
                          ),
                          SliverToBoxAdapter(
                            child: _SettingsCard(
                              soundEnabled: _soundEnabled,
                              alertEnabled: _alertEnabled,
                              onSoundChanged: (value) =>
                                  setState(() => _soundEnabled = value),
                              onAlertChanged: (value) =>
                                  setState(() => _alertEnabled = value),
                              onPromotion: () =>
                                  context.push(PromotionCodePage.routePath),
                              onLanguage: () => _showComingSoon(context),
                              onLogout: authState.isLoading
                                  ? null
                                  : () => _showLogoutDialog(context, ref),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: MameroomSpacing.xl),
                          ),
                          SliverToBoxAdapter(
                            child: _InfoSection(
                              title: '서비스',
                              entries: [
                                _InfoEntry(
                                  label: '공지사항',
                                  icon: Icons.campaign_rounded,
                                  onTap: () =>
                                      context.push(NoticeListPage.routePath),
                                ),
                                _InfoEntry(
                                  label: '문의하기',
                                  icon: Icons.chat_bubble_outline_rounded,
                                  onTap: () =>
                                      context.push(SupportPage.routePath),
                                ),
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: MameroomSpacing.xl),
                          ),
                          SliverToBoxAdapter(
                            child: _InfoSection(
                              title: '약관 및 정보',
                              entries: [
                                _InfoEntry(
                                  label: '이용약관',
                                  icon: Icons.description_rounded,
                                  onTap: () => context.push(
                                    TermsOfServicePage.routePath,
                                  ),
                                ),
                                _InfoEntry(
                                  label: '개인정보처리방침',
                                  icon: Icons.shield_rounded,
                                  onTap: () =>
                                      context.push(PrivacyPolicyPage.routePath),
                                ),
                                _InfoEntry(
                                  label: '오픈소스 라이선스',
                                  icon: Icons.code_rounded,
                                  onTap: () => context.push(
                                    OpenSourceLicensePage.routePath,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: MameroomSpacing.xxl),
                          ),
                          const SliverToBoxAdapter(child: _AppVersionFooter()),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: MameroomSpacing.lg + metrics.bottomSpace,
                            ),
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

  Future<void> _showComingSoon(BuildContext context) =>
      MameroomPopupService.showInfo(
        context,
        title: '준비 중인 기능입니다.',
        message: '더 나은 서비스를 제공하기 위해\n해당 기능을 준비하고 있습니다.',
      );

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await MameroomPopupService.showLogoutConfirm(context);
    if (!shouldLogout || !context.mounted) {
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
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : 844.0;
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
  const _ProfileCard({required this.displayName, required this.onEdit});

  final String displayName;
  final VoidCallback onEdit;

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
                _IconText(
                  icon: Icons.school_rounded,
                  text: _school,
                  color: colors.seedGreen,
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
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
              const Expanded(
                child: _InfoLine(label: _currentPlan, value: 'Free'),
              ),
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
              Expanded(
                child: _InfoLine(
                  label: _thisMonthUsage,
                  value: '180 / 500$_questionUnit',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _InfoLine(label: _nextResetShort, value: '2026.08.01'),
              ),
            ],
          ),
          if (isLow) ...[const SizedBox(height: 10), const _WarningBanner()],
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: () => context.push(
                '${MameroomPaywallPage.routePath}?entry=questionLimit',
              ),
              child: const Text(_premiumStart),
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
              Expanded(
                child: _StatTile(label: _totalSolved, value: '2,341'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatTile(label: _correctRate, value: '84%'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(label: _streakShort, value: '24$_dayUnit'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatTile(label: _totalStudyTime, value: '18$_hourUnit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementEntryCard extends StatelessWidget {
  const _AchievementEntryCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _Card(
      child: InkWell(
        key: const ValueKey('my-achievement-entry'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.emoji_events_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '나의 업적',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text('기록을 모아 성장 과정을 확인해요.'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
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
    required this.onPromotion,
    required this.onLanguage,
    required this.onLogout,
  });

  final bool soundEnabled;
  final bool alertEnabled;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onAlertChanged;
  final VoidCallback onPromotion;
  final VoidCallback onLanguage;
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
          _SettingRow.navigation(label: '프로모션 코드', onTap: onPromotion),
          _SettingRow.navigation(
            label: _languageSettings,
            trailingText: _korean,
            onTap: onLanguage,
          ),
          _SettingRow.logout(onTap: onLogout),
        ],
      ),
    );
  }
}

class _InfoEntry {
  const _InfoEntry({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.entries});

  final String title;
  final List<_InfoEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: MameroomSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(MameroomRadius.r16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MameroomRadius.r16),
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  _InfoMenuTile(entry: entries[index]),
                  if (index < entries.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent:
                          MameroomSpacing.lg +
                          MameroomIconSizes.md +
                          MameroomSpacing.md,
                      color: colors.line,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoMenuTile extends StatelessWidget {
  const _InfoMenuTile({required this.entry});

  final _InfoEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Semantics(
      button: true,
      label: entry.label,
      child: InkWell(
        onTap: entry.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MameroomSpacing.lg,
              vertical: MameroomSpacing.sm,
            ),
            child: Row(
              children: [
                MameroomIcon(
                  icon: entry.icon,
                  size: MameroomIconSizes.md,
                  color: colors.primary,
                ),
                const SizedBox(width: MameroomSpacing.md),
                Expanded(
                  child: Text(
                    entry.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: MameroomSpacing.sm),
                MameroomIcon(
                  icon: Icons.chevron_right_rounded,
                  size: MameroomIconSizes.md,
                  semanticLabel: '${entry.label} 열기',
                  color: colors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppVersionFooter extends ConsumerWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.mameroom;
    final info = ref.watch(packageInfoProvider);
    return Center(
      child: info.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (value) => Semantics(
          label: 'Mameroom 버전 ${value.version}, 빌드 ${value.buildNumber}',
          child: Text(
            'Mameroom v${value.version} (${value.buildNumber})',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
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
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 19,
          ),
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

  const _SettingRow.navigation({
    required this.label,
    this.trailingText,
    this.onTap,
  }) : value = null,
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
  const _IconText({
    required this.icon,
    required this.text,
    required this.color,
  });

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
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(12),
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

const _myTitle = '\uB0B4 \uC815\uBCF4';
const _settings = '\uC124\uC815';
const _notifications = '\uC54C\uB9BC';
const _nickname = '\uAE40\uD558\uC774';
const _streak = '\uC5F0\uC18D \uD559\uC2B5 24\uC77C';
const _streakShort = '\uC5F0\uC18D \uD559\uC2B5';
const _school = '\uB9C8\uBA54\uACE0\uB4F1\uD559\uAD50 2\uD559\uB144';
const _memoryRate = '\uAE30\uC5B5\uB960 84%';
const _profileEdit = '\uD504\uB85C\uD544 \uC218\uC815';
const _usageTitle = '\uC774\uC6A9 \uD604\uD669';
const _currentPlan = '\uD604\uC7AC \uD50C\uB79C';
const _remainingGeneration = '\uB0A8\uC740 \uC0DD\uC131\uB7C9';
const _thisMonthUsage = '\uC774\uBC88 \uB2EC \uC0AC\uC6A9';
const _nextResetShort = '\uB2E4\uC74C \uB9AC\uC14B';
const _premiumStart = 'Premium \uC2DC\uC791\uD558\uAE30';
const _lowQuestionBody =
    '\uB0A8\uC740 \uC0DD\uC131\uB7C9\uC774 \uBD80\uC871\uD569\uB2C8\uB2E4. \uBB38\uC81C\uB97C \uCDA9\uC804\uD558\uACE0 \uACC4\uC18D \uACF5\uBD80\uD558\uC138\uC694.';
const _mCoin = 'M-Coin';
const _currentBalance = '\uD604\uC7AC \uBCF4\uC720';
const _weeklyEarned = '\uC774\uBC88 \uC8FC \uD68D\uB4DD';
const _totalSpent = '\uCD1D \uC0AC\uC6A9';
const _history = '\uC0AC\uC6A9 \uB0B4\uC5ED';
const _sound = '\uC0AC\uC6B4\uB4DC';
const _languageSettings = '\uC5B8\uC5B4';
const _korean = '\uD55C\uAD6D\uC5B4';
const _logout = '\uB85C\uADF8\uC544\uC6C3';
const _learningStats = '\uD559\uC2B5 \uD1B5\uACC4';
const _totalSolved = '\uCD1D \uD480\uC774 \uBB38\uC81C';
const _correctRate = '\uC815\uB2F5\uB960';
const _totalStudyTime = '\uB204\uC801 \uD559\uC2B5 \uC2DC\uAC04';
const _questionUnit = '\uBB38\uC81C';
const _dayUnit = '\uC77C';
const _hourUnit = '\uC2DC\uAC04';
