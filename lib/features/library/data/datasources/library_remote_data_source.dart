import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/storage_buckets.dart';
import '../../../../shared/supabase/supabase_tables.dart';

class StudyMaterialDeleteFailure implements Exception {
  const StudyMaterialDeleteFailure(this.message);
  final String message;
  @override
  String toString() => 'StudyMaterialDeleteFailure: $message';
}

class LibraryRemoteDataSource {
  const LibraryRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<void> deleteStudyMaterial(String materialId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const StudyMaterialDeleteFailure('User session is required.');
    }
    if (!_uuidPattern.hasMatch(materialId)) {
      throw const StudyMaterialDeleteFailure('Material id is not a UUID.');
    }
    debugPrint('[library.delete] materialId=$materialId userId=${user.id}');
    final response = await _client
        .from(SupabaseTables.studyMaterials)
        .delete()
        .eq('id', materialId)
        .eq('user_id', user.id)
        .select('id,user_id,storage_path,source_type');
    final rows = List<Map<String, dynamic>>.from(response);
    if (rows.isEmpty) {
      throw const StudyMaterialDeleteFailure('No owned row was deleted.');
    }
    final deleted = rows.single;
    if (deleted['id'] != materialId || deleted['user_id'] != user.id) {
      throw const StudyMaterialDeleteFailure('Ownership response mismatch.');
    }
    final path = (deleted['storage_path'] as String?)?.trim();
    if (path == null || path.isEmpty) return;
    final bucket = deleted['source_type'] == 'pdf'
        ? StorageBuckets.pdfUploads
        : StorageBuckets.materials;
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (error, stackTrace) {
      debugPrint(
        '[library.delete] storage cleanup failed bucket=$bucket path=$path error=$error\n$stackTrace',
      );
    }
  }
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
  r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
