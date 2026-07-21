import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/repositories/next_study_repository.dart';

class SupabaseNextStudyRepository implements NextStudyRepository {
  const SupabaseNextStudyRepository(this.client);

  final SupabaseClient client;

  @override
  Future<String?> findUnlearnedMaterialId() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final materials = await client
        .from(SupabaseTables.studyMaterials)
        .select('id,updated_at,created_at')
        .eq('user_id', user.id)
        .eq('status', 'completed')
        .order('updated_at', ascending: false)
        .order('created_at', ascending: false)
        .order('id', ascending: true);
    if (materials.isEmpty) return null;

    final materialIds = materials
        .map((row) => (row as Map)['id']?.toString())
        .whereType<String>()
        .toList(growable: false);
    final questions = await client
        .from(SupabaseTables.questions)
        .select('id,material_id,options,answer,order_index')
        .eq('user_id', user.id)
        .eq('initial_batch', true)
        .eq('type', 'multiple_choice')
        .inFilter('material_id', materialIds)
        .order('order_index', ascending: true)
        .order('id', ascending: true);

    final attempts = await client
        .from(SupabaseTables.quizAttempts)
        .select('question_id')
        .eq('user_id', user.id);
    final attemptedIds = attempts
        .map((row) => (row as Map)['question_id']?.toString())
        .whereType<String>()
        .toSet();

    final eligibleMaterialIds = <String>{};
    for (final raw in questions) {
      final row = Map<String, dynamic>.from(raw as Map);
      final id = row['id']?.toString();
      final materialId = row['material_id']?.toString();
      final answer = row['answer']?.toString().trim() ?? '';
      final options = row['options'];
      if (id == null || materialId == null || attemptedIds.contains(id)) {
        continue;
      }
      if (options is! List || options.length < 2 || answer.isEmpty) continue;
      final normalized = options.map((item) => item.toString().trim()).toSet();
      if (!normalized.contains(answer)) continue;
      eligibleMaterialIds.add(materialId);
    }

    for (final materialId in materialIds) {
      if (eligibleMaterialIds.contains(materialId)) return materialId;
    }
    return null;
  }
}
