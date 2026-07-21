import 'package:flutter/foundation.dart';

enum SupportCategory {
  materialAnalysis('MATERIAL_ANALYSIS', '학습자료·분석'),
  quizStudy('QUIZ_STUDY', '문제·학습'),
  paymentQuota('PAYMENT_QUOTA', '결제·이용권'),
  accountProfile('ACCOUNT_PROFILE', '계정·프로필'),
  friendNotification('FRIEND_NOTIFICATION', '친구·알림'),
  bugReport('BUG_REPORT', '오류 신고'),
  suggestionOther('SUGGESTION_OTHER', '서비스 제안·기타');

  const SupportCategory(this.code, this.label);
  final String code;
  final String label;

  static SupportCategory fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => suggestionOther,
  );
}

enum SupportStatus {
  received('RECEIVED', '접수됨'),
  inReview('IN_REVIEW', '확인 중'),
  answered('ANSWERED', '답변 완료'),
  closed('CLOSED', '종료');

  const SupportStatus(this.code, this.label);
  final String code;
  final String label;

  static SupportStatus fromCode(String code) =>
      values.firstWhere((value) => value.code == code, orElse: () => received);
}

@immutable
class SupportReply {
  const SupportReply({required this.content, required this.createdAt});
  final String content;
  final DateTime createdAt;

  factory SupportReply.fromJson(Map<String, dynamic> json) => SupportReply(
    content: json['content'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

@immutable
class SupportInquiry {
  const SupportInquiry({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    this.appVersion,
    this.platform,
    this.reply,
  });

  final String id;
  final SupportCategory category;
  final String title;
  final String content;
  final SupportStatus status;
  final DateTime createdAt;
  final String? appVersion;
  final String? platform;
  final SupportReply? reply;

  factory SupportInquiry.fromJson(Map<String, dynamic> json) {
    final replies = json['support_replies'] as List<dynamic>? ?? const [];
    return SupportInquiry(
      id: json['id'] as String,
      category: SupportCategory.fromCode(json['category'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      status: SupportStatus.fromCode(json['status'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      appVersion: json['app_version'] as String?,
      platform: json['platform'] as String?,
      reply: replies.isEmpty
          ? null
          : SupportReply.fromJson(replies.first as Map<String, dynamic>),
    );
  }
}

enum CreateSupportResultCode {
  success('SUCCESS'),
  unauthenticated('UNAUTHENTICATED'),
  invalidCategory('INVALID_CATEGORY'),
  invalidTitle('INVALID_TITLE'),
  invalidContent('INVALID_CONTENT'),
  rateLimited('RATE_LIMITED'),
  dailyLimitExceeded('DAILY_LIMIT_EXCEEDED'),
  duplicateInquiry('DUPLICATE_INQUIRY'),
  invalidRelatedMaterial('INVALID_RELATED_MATERIAL'),
  accountRestricted('ACCOUNT_RESTRICTED'),
  internalError('INTERNAL_ERROR');

  const CreateSupportResultCode(this.code);
  final String code;

  static CreateSupportResultCode fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => internalError,
  );

  String get userMessage => switch (this) {
    success => '문의가 접수되었습니다.',
    unauthenticated => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
    invalidCategory || invalidTitle || invalidContent => '입력한 내용을 확인해 주세요.',
    rateLimited => '잠시 후 다시 문의해 주세요.',
    dailyLimitExceeded => '오늘 접수할 수 있는 문의 수를 초과했습니다.',
    duplicateInquiry => '같은 내용의 문의가 이미 접수되었습니다.',
    invalidRelatedMaterial => '연결된 학습자료를 확인해 주세요.',
    accountRestricted => '현재 계정에서는 문의를 접수할 수 없습니다.',
    internalError => '문의를 접수하지 못했습니다. 잠시 후 다시 시도해 주세요.',
  };
}

@immutable
class SupportEnvironment {
  const SupportEnvironment({
    this.appVersion,
    this.buildNumber,
    this.platform,
    this.osVersion,
    this.locale,
    this.currentRoute,
  });
  final String? appVersion;
  final String? buildNumber;
  final String? platform;
  final String? osVersion;
  final String? locale;
  final String? currentRoute;
}
