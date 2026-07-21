import 'package:flutter/material.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const routePath = '/terms-of-service';

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? scheme.surface : colors.paper;
    final textColor = isDark ? scheme.onSurface : colors.ink;
    final mutedColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.72)
        : colors.muted;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('이용약관'),
        centerTitle: false,
        backgroundColor: background,
        surfaceTintColor: background,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TermsHeader(textColor: textColor, mutedColor: mutedColor),
                  const SizedBox(height: 20),
                  for (final section in _sections) ...[
                    _TermsSectionCard(section: section),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsHeader extends StatelessWidget {
  const _TermsHeader({required this.textColor, required this.mutedColor});

  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이용약관',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primaryMist.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.primaryPale),
            ),
            child: Text(
              '최종 수정일  2026.08.01',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSectionCard extends StatelessWidget {
  const _TermsSectionCard({required this.section});

  final _TermsSection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? scheme.surfaceContainerHighest : colors.paper;
    final textColor = isDark ? scheme.onSurface : colors.ink;
    final bodyColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.84)
        : colors.ink.withValues(alpha: 0.82);

    return Semantics(
      container: true,
      label: section.title,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(
            color: isDark
                ? scheme.outlineVariant.withValues(alpha: 0.44)
                : colors.line,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: isDark ? 0.02 : 0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryMist.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(section.icon, color: colors.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              section.body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: bodyColor,
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
                height: 1.68,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

const _sections = <_TermsSection>[
  _TermsSection(
    title: '마메룸 이용약관',
    icon: Icons.description_rounded,
    body: '''최종 수정일 : 2026년 8월 1일

마메룸(MameRoom)을 이용해 주셔서 감사합니다.

마메룸은 AI 기반 개인 학습 서비스로, 사용자가 업로드한 자료를 활용하여 문제 생성, 핵심 개념 추출 및 복습을 지원합니다.

서비스를 이용하기 전에 아래 이용약관을 확인하여 주시기 바랍니다.''',
  ),
  _TermsSection(
    title: '제1조 서비스 소개',
    icon: Icons.auto_stories_rounded,
    body: '''마메룸은 사용자가 업로드한 학습 자료를 AI를 활용하여 분석하고 개인 맞춤형 학습을 제공하는 서비스입니다.

회사는 서비스 품질 향상을 위해 기능을 추가하거나 변경할 수 있습니다.''',
  ),
  _TermsSection(
    title: '제2조 회원의 의무',
    icon: Icons.verified_user_rounded,
    body: '''회원은 다음 사항을 준수하여야 합니다.

• 관련 법령 및 본 약관을 준수합니다.

• 타인의 권리를 침해하지 않습니다.

• 서비스를 부정한 방법으로 이용하지 않습니다.

• 회사 및 다른 회원의 서비스 이용을 방해하지 않습니다.''',
  ),
  _TermsSection(
    title: '제3조 업로드 자료',
    icon: Icons.upload_file_rounded,
    body: '''회원은 다음 자료만 업로드할 수 있습니다.

• 본인이 직접 작성한 자료

• 직접 제작한 자료

• 적법하게 구매하거나 이용 권한을 가진 자료

• 저작권자의 허락을 받은 자료

다음 자료는 업로드할 수 없습니다.

• 불법 복제 자료

• 무단 스캔본

• 인터넷 불법 공유 PDF

• 타인의 강의자료를 무단 복제한 자료

• 기타 저작권을 침해하는 자료

회원이 적법한 권한 없이 자료를 업로드하여 발생하는 모든 민사상·형사상 책임은 해당 회원에게 있습니다.''',
  ),
  _TermsSection(
    title: '제4조 업로드 자료의 보호',
    icon: Icons.lock_rounded,
    body: '''마메룸은 사용자의 자료를 안전하게 보호하기 위해 다음 원칙을 적용합니다.

• 업로드 자료는 회원 본인만 열람할 수 있습니다.

• 다른 회원에게 공유되지 않습니다.

• 회사는 회원의 동의 없이 제3자에게 제공하지 않습니다.

• 서비스 제공 목적 외에는 사용하지 않습니다.''',
  ),
  _TermsSection(
    title: '제5조 AI 서비스 이용',
    icon: Icons.smart_toy_rounded,
    body: '''회원이 업로드한 자료는 다음 기능을 제공하기 위해 AI가 처리합니다.

• 핵심 개념 추출

• 문제 생성

• 요약

• 설명 생성

• 학습 분석

• 복습 기능

회사는 업로드된 자료를 AI 모델의 학습 데이터로 사용하지 않습니다.

AI가 생성한 결과는 참고자료이며 오류가 포함될 수 있으므로 회원은 내용을 확인한 후 이용하여야 합니다.''',
  ),
  _TermsSection(
    title: '제6조 저작권',
    icon: Icons.copyright_rounded,
    body: '''업로드 자료의 저작권은 회원 또는 원저작자에게 있습니다.

회사는 서비스 제공을 위한 최소한의 범위에서만 자료를 처리하며 별도의 동의 없이 공개하거나 상업적으로 이용하지 않습니다.''',
  ),
  _TermsSection(
    title: '제7조 유료 서비스',
    icon: Icons.workspace_premium_rounded,
    body: '''일부 기능은 Premium 플랜 가입 후 이용할 수 있습니다.

문제 생성 수량, 이용기간 및 혜택은 서비스 내 안내에 따릅니다.

환불은 Google Play 및 Apple App Store 정책과 대한민국 관계 법령을 따릅니다.''',
  ),
  _TermsSection(
    title: '제8조 서비스 이용 제한',
    icon: Icons.block_rounded,
    body: '''회사는 다음과 같은 경우 서비스 이용을 제한할 수 있습니다.

• 법령 위반

• 저작권 침해

• 비정상적인 서비스 이용

• 회사 또는 다른 회원의 권리 침해''',
  ),
  _TermsSection(
    title: '제9조 서비스 변경 및 중단',
    icon: Icons.build_circle_rounded,
    body:
        '회사는 시스템 점검, 장애, 서비스 개선 등의 사유로 서비스의 일부 또는 전부를 변경하거나 일시적으로 중단할 수 있습니다.',
  ),
  _TermsSection(
    title: '제10조 면책',
    icon: Icons.gavel_rounded,
    body: '''회사는 AI가 생성한 결과의 정확성, 완전성 및 최신성을 보증하지 않습니다.

회원은 AI 결과를 자신의 판단과 책임 하에 이용하여야 합니다.''',
  ),
  _TermsSection(
    title: '제11조 준거법',
    icon: Icons.balance_rounded,
    body: '''본 약관은 대한민국 법률에 따라 적용됩니다.

서비스 이용과 관련하여 분쟁이 발생하는 경우 관련 법령에 따른 관할 법원을 따릅니다.''',
  ),
  _TermsSection(
    title: '사용자 권리 보호',
    icon: Icons.shield_rounded,
    body: '''마메룸은 사용자의 학습 자료를 가장 중요한 자산으로 생각합니다.

우리는 다음 원칙을 약속합니다.

✓ 사용자의 자료는 다른 회원에게 공개되지 않습니다.

✓ 업로드 자료는 AI 모델 학습에 사용되지 않습니다.

✓ 회원은 언제든지 자신의 자료를 삭제할 수 있습니다.

✓ 회원 탈퇴 시 관련 법령상 보관 의무가 있는 정보를 제외한 개인정보와 학습 자료는 삭제 절차에 따라 처리됩니다.

마메룸은 사용자의 신뢰를 최우선 가치로 서비스를 운영합니다.''',
  ),
];
