import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/support_inquiry.dart';

abstract interface class SupportRepository {
  Future<List<SupportInquiry>> loadMine();
  Future<SupportInquiry?> loadMineById(String id);
  Future<CreateSupportResultCode> create({
    required SupportCategory category,
    required String title,
    required String content,
    required SupportEnvironment environment,
    String? relatedMaterialId,
  });
}

class SupabaseSupportRepository implements SupportRepository {
  const SupabaseSupportRepository(this._client);
  final SupabaseClient _client;

  static const _columns =
      'id,category,title,content,status,app_version,platform,created_at,'
      'support_replies(content,created_at)';

  @override
  Future<List<SupportInquiry>> loadMine() async {
    final rows = await _client
        .from('support_inquiries')
        .select(_columns)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(50);
    return rows.map(SupportInquiry.fromJson).toList(growable: false);
  }

  @override
  Future<SupportInquiry?> loadMineById(String id) async {
    final row = await _client
        .from('support_inquiries')
        .select(_columns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : SupportInquiry.fromJson(row);
  }

  @override
  Future<CreateSupportResultCode> create({
    required SupportCategory category,
    required String title,
    required String content,
    required SupportEnvironment environment,
    String? relatedMaterialId,
  }) async {
    try {
      final response = await _client.rpc(
        'create_support_inquiry',
        params: {
          'p_category': category.code,
          'p_title': title.trim(),
          'p_content': content.trim(),
          'p_app_version': environment.appVersion,
          'p_build_number': environment.buildNumber,
          'p_platform': environment.platform,
          'p_os_version': environment.osVersion,
          'p_locale': environment.locale,
          'p_current_route': environment.currentRoute,
          'p_related_material_id': relatedMaterialId,
        },
      );
      final row = response is List
          ? (response.isEmpty ? null : response.first)
          : response;
      final code = row is Map ? row['result_code'] as String? : null;
      return CreateSupportResultCode.fromCode(code ?? 'INTERNAL_ERROR');
    } on AuthException {
      return CreateSupportResultCode.unauthenticated;
    } on PostgrestException {
      return CreateSupportResultCode.internalError;
    }
  }
}
