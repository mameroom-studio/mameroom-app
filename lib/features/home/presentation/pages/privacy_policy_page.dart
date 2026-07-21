import 'package:flutter/material.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  static const routePath = '/privacy-policy';
  static const version = '1.0';

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final _sectionKeys = List.generate(_sections.length, (_) => GlobalKey());

  Future<void> _goTo(int index) async {
    final target = _sectionKeys[index].currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? scheme.surface : colors.paper;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
        centerTitle: false,
        backgroundColor: background,
        surfaceTintColor: background,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth < 420 ? 16 : 24,
              12,
              constraints.maxWidth < 420 ? 16 : 24,
              40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Mameroom 개인정보처리방침',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '버전 ${PrivacyPolicyPage.version} · 공고일 2026.07.21 · 시행일 2026.07.21',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: dark ? scheme.onSurfaceVariant : colors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ReleaseWarning(dark: dark),
                    const SizedBox(height: 20),
                    _ContentsCard(onSelected: _goTo),
                    const SizedBox(height: 20),
                    for (var index = 0; index < _sections.length; index++) ...[
                      _PolicySectionCard(
                        key: _sectionKeys[index],
                        section: _sections[index],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseWarning extends StatelessWidget {
  const _ReleaseWarning({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Semantics(
      label: '출시 전 필수 점검',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: dark ? 0.14 : 0.10),
          border: Border.all(color: colors.warning.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '출시 전 필수: [개인정보 보호책임자]와 [OpenAI 이전 국가 및 계약 정보]를 실제 확인값으로 교체해야 합니다.',
        ),
      ),
    );
  }
}

class _ContentsCard extends StatelessWidget {
  const _ContentsCard({required this.onSelected});
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Semantics(
      container: true,
      label: '목차',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primaryMist.withValues(alpha: 0.32),
          border: Border.all(color: colors.primaryPale),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '목차',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < _sections.length; index++)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => onSelected(index),
                  child: Text(_sections[index].title),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  const _PolicySectionCard({super.key, required this.section});
  final _PolicySection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      label: section.title,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: dark ? scheme.surfaceContainerHighest : colors.paper,
          border: Border.all(color: dark ? scheme.outlineVariant : colors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              section.body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection(this.title, this.body);
  final String title;
  final String body;
}

const _sections = <_PolicySection>[
  _PolicySection(
    '1. 총칙',
    '마메룸(이하 “운영자”)은 이용자의 개인정보를 보호하고 관련 법령을 준수합니다. 본 방침은 Mameroom 서비스에 적용됩니다. 현재 별도 법인 또는 개인사업자로 등록하지 않은 서비스 준비 단계이며, 사업자 정보가 확정되면 본 방침을 변경하여 알립니다.',
  ),
  _PolicySection(
    '2. 서비스 이용 연령',
    'Mameroom은 만 14세 이상만 가입할 수 있습니다. 가입 시 이용자가 “[필수] 만 14세 이상입니다.”를 직접 확인해야 하며, 생년월일은 수집하지 않습니다.',
  ),
  _PolicySection(
    '3. 개인정보 처리 항목·목적·보유기간',
    '필수: 이메일, 인증 식별자, 닉네임, 만 14세 이상 확인 및 동의 버전·시각 — 회원가입·인증·서비스 제공을 위해 회원 탈퇴 시까지 처리합니다.\n서비스 이용 중 학습자료명, 추출 텍스트, 생성 문제·답안·학습 기록, 친구·차단·룸·재화·문의 정보가 기능 제공을 위해 생성될 수 있습니다. 일반 문의는 처리 목적 달성 후 지체 없이 삭제하며, 소비자 불만·분쟁 처리 기록에 해당하면 3년간 일반 데이터와 분리하여 보관합니다. 법정 보존 대상은 해당 기간 동안 별도 보관합니다.',
  ),
  _PolicySection(
    '4. 학습자료 처리 및 원본 삭제',
    '텍스트가 포함된 PDF 및 직접 입력 텍스트를 지원합니다. OCR, 이미지·스캔 PDF·손글씨 자료는 지원하지 않습니다. PDF 원본은 추출 텍스트를 안전하게 저장한 뒤 서버에서 삭제하고, 삭제 성공을 확인한 경우에만 분석 완료 단계로 처리합니다. 삭제에 실패하면 완료로 표시하지 않고 제한된 횟수만큼 재시도한 뒤 운영 확인 대상으로 관리합니다. 재분석에 원본이 필요하면 이용자에게 다시 업로드하도록 안내합니다. 추출 텍스트는 학습 제공을 위해 자료 삭제 또는 회원 탈퇴 시까지 보관합니다. 실패·취소·시간 초과 원본은 영구 보관하지 않고 삭제 대상으로 관리합니다.',
  ),
  _PolicySection(
    '5. 생성형 AI를 이용한 학습자료 분석',
    '학습자료에서 추출한 텍스트는 핵심 개념과 학습 문제 생성을 위해 OpenAI API로 전송될 수 있습니다. 운영자는 이를 광고에 사용하거나 다른 이용자에게 공개하지 않습니다. 구체적인 이전 국가와 계약 정보는 [OpenAI 이전 국가 및 계약 정보] 확인 후 고지합니다.',
  ),
  _PolicySection(
    '6. 개인정보 제3자 제공',
    '운영자는 이용자의 개인정보를 제3자에게 제공하지 않습니다. 법령에 특별한 근거가 있거나 이용자가 별도로 동의한 경우는 예외입니다.',
  ),
  _PolicySection(
    '7. 개인정보 처리위탁',
    '서비스 운영을 위해 Supabase(인증·DB·Storage·Edge Function)와 OpenAI(AI 분석)를 이용합니다. Google Play 결제는 도입 예정이며, 실제 연동 전에는 결제정보나 purchase token을 수집하지 않습니다. 결제를 도입할 때 위탁 업무와 보유기간을 본 방침에 반영합니다. 정확한 계약 당사자·업무·보유기간은 실제 계약과 Dashboard 확인 후 출시 전에 확정합니다.',
  ),
  _PolicySection(
    '8. 개인정보 국외 이전',
    'Supabase 프로젝트 Region은 ap-northeast-1(일본 도쿄)입니다. OpenAI 관련 이전 국가와 계약 정보는 [OpenAI 이전 국가 및 계약 정보]입니다. 이전 항목·시점·방법·보유기간은 실제 계약을 확인해 출시 전에 고지합니다.',
  ),
  _PolicySection(
    '9. 회원 탈퇴 및 파기',
    '회원 탈퇴는 이용자 재확인, 삭제 대상과 소유권 확인, 법정 보존정보 분리, 서비스 데이터 삭제, Storage 원본 삭제, Auth 계정 삭제, 결과 반환과 세션 종료 순서로 처리합니다. 인증 계정, 프로필, 학습자료와 원본, 추출 텍스트, 생성 문제·답안·통계, 친구·차단·룸·재화·프로모션·일반 문의 등 서비스 데이터를 삭제합니다. 부분 실패는 완료로 숨기지 않고 제한된 운영자만 확인할 수 있는 재처리 상태로 관리합니다. 계약·청약철회 및 결제·재화 공급 기록은 5년, 소비자 불만·분쟁 기록은 3년, 표시·광고 기록은 6개월간 일반 데이터와 분리해 제한된 권한으로 보관할 수 있습니다.',
  ),
  _PolicySection(
    '10. 정보주체 권리와 행사 방법',
    '이용자는 앱 설정 또는 mameroom.studio@gmail.com을 통해 개인정보 열람·정정·삭제·처리정지 및 회원 탈퇴를 요청할 수 있습니다. 본인 확인 후 지체 없이 처리합니다.',
  ),
  _PolicySection(
    '11. 자동 수집 정보',
    '서비스 보안과 오류 대응 과정에서 접속 시각, 앱 버전, 플랫폼, 언어, 현재 화면 경로 및 서버가 생성하는 IP·User-Agent 등의 접속 로그가 처리될 수 있습니다. 실제 로그 보존기간과 범위는 운영 설정 확인 후 확정합니다.',
  ),
  _PolicySection(
    '12. 자동화된 결정',
    'Mameroom의 AI 분석 결과는 학습 보조 자료이며 이용자에게 법적 또는 중대한 영향을 주는 자동화된 결정을 수행하지 않습니다.',
  ),
  _PolicySection(
    '13. 안전성 확보조치',
    '접근권한 최소화, 전송구간 암호화, Row Level Security, 서버 비밀키 분리, 로그 최소화, 삭제 권한 검증 등 기술적·관리적 조치를 적용합니다.',
  ),
  _PolicySection(
    '14. 개인정보 보호책임자',
    '서비스 운영자: 마메룸\n대표자명: 마메룸\n개인정보 보호책임자: [개인정보 보호책임자]\n문의 이메일: mameroom.studio@gmail.com\n현재 별도 법인 또는 개인사업자로 등록하지 않은 서비스 준비 단계이므로 사업자등록번호와 사업장 주소는 기재하지 않습니다. 등록 정보가 확정되면 본 방침을 변경하여 알립니다.',
  ),
  _PolicySection(
    '15. 개인정보 침해 구제',
    '이용자는 개인정보침해 신고센터, 개인정보분쟁조정위원회 등 관계 기관에 상담 또는 구제를 신청할 수 있습니다. 기관의 최신 연락처와 URL은 출시 전 공식 자료로 확인합니다.',
  ),
  _PolicySection(
    '16. 처리방침 변경',
    '내용이 변경되는 경우 앱 내 공지 등으로 사전에 알립니다. 현재 기존 가입자는 없습니다. 향후 중요한 변경에는 재동의를 요청할 수 있으며, 필수 재동의를 완료하지 않으면 관련 법령과 변경 내용에 따라 서비스 이용이 제한될 수 있습니다. 공고일은 2026년 7월 21일입니다.',
  ),
  _PolicySection('17. 시행일', '본 방침의 버전은 v1.0이며 2026년 7월 21일부터 시행합니다.'),
];
