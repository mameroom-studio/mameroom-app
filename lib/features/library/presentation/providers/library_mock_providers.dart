import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/study_material.dart';

class RecentStudyRecord {
  const RecentStudyRecord({
    required this.title,
    required this.subtitle,
    required this.scoreLabel,
  });

  final String title;
  final String subtitle;
  final String scoreLabel;
}

class LibraryDashboard {
  const LibraryDashboard({
    required this.todayReviewCount,
    required this.totalMemoryPercent,
    required this.materials,
    required this.recentRecords,
  });

  final int todayReviewCount;
  final int totalMemoryPercent;
  final List<StudyMaterial> materials;
  final List<RecentStudyRecord> recentRecords;
}

final useEmptyLibraryMockProvider = Provider<bool>((ref) => false);

final libraryDashboardProvider = FutureProvider<LibraryDashboard>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client?.auth.currentUser;
  if (client == null || user == null || ref.watch(useEmptyLibraryMockProvider)) {
    return const LibraryDashboard(
      todayReviewCount: 0,
      totalMemoryPercent: 0,
      materials: [],
      recentRecords: [],
    );
  }

  final now = DateTime.now().toUtc();
  final materialRows = await client
      .from(SupabaseTables.studyMaterials)
      .select('id,title,status,created_at')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  final questionRows = await client
      .from(SupabaseTables.questions)
      .select('id,material_id')
      .eq('user_id', user.id);

  final attemptRows = await client
      .from(SupabaseTables.quizAttempts)
      .select('material_id,question_id,attempted_at,is_correct')
      .eq('user_id', user.id)
      .order('attempted_at', ascending: false);

  final memoryRows = await client
      .from(SupabaseTables.memoryStates)
      .select('material_id,memory_score,last_reviewed_at,next_review_at')
      .eq('user_id', user.id);

  final streakRows = await client
      .from(SupabaseTables.userStreaks)
      .select('current_streak')
      .eq('user_id', user.id)
      .limit(1);

  final questionCountByMaterial = <String, int>{};
  for (final row in questionRows) {
    final map = Map<String, dynamic>.from(row as Map);
    final materialId = map['material_id']?.toString();
    if (materialId == null) continue;
    questionCountByMaterial[materialId] = (questionCountByMaterial[materialId] ?? 0) + 1;
  }

  final completedQuestionIdsByMaterial = <String, Set<String>>{};
  final latestAttemptByMaterial = <String, DateTime>{};
  for (final row in attemptRows) {
    final map = Map<String, dynamic>.from(row as Map);
    final materialId = map['material_id']?.toString();
    final questionId = map['question_id']?.toString();
    if (materialId == null) continue;
    if (questionId != null) {
      completedQuestionIdsByMaterial.putIfAbsent(materialId, () => <String>{}).add(questionId);
    }
    final attemptedAt = _dateFrom(map['attempted_at']);
    if (attemptedAt != null && (latestAttemptByMaterial[materialId] == null || attemptedAt.isAfter(latestAttemptByMaterial[materialId]!))) {
      latestAttemptByMaterial[materialId] = attemptedAt;
    }
  }

  final memoryScoresByMaterial = <String, List<double>>{};
  final dueReviewCountByMaterial = <String, int>{};
  final latestMemoryByMaterial = <String, DateTime>{};
  for (final row in memoryRows) {
    final map = Map<String, dynamic>.from(row as Map);
    final materialId = map['material_id']?.toString();
    if (materialId == null) continue;
    memoryScoresByMaterial.putIfAbsent(materialId, () => <double>[]).add(_doubleFrom(map['memory_score']).clamp(0, 1).toDouble());
    final nextReviewAt = _dateFrom(map['next_review_at']);
    if (nextReviewAt != null && !nextReviewAt.isAfter(now)) {
      dueReviewCountByMaterial[materialId] = (dueReviewCountByMaterial[materialId] ?? 0) + 1;
    }
    final lastReviewedAt = _dateFrom(map['last_reviewed_at']);
    if (lastReviewedAt != null && (latestMemoryByMaterial[materialId] == null || lastReviewedAt.isAfter(latestMemoryByMaterial[materialId]!))) {
      latestMemoryByMaterial[materialId] = lastReviewedAt;
    }
  }

  final currentStreak = streakRows.isEmpty ? 0 : _intFrom(Map<String, dynamic>.from(streakRows.first as Map)['current_streak']);
  final totalMemoryPercent = _averageMemoryPercent(memoryRows);
  final materials = materialRows
      .map((row) => _materialFromRow(
            Map<String, dynamic>.from(row as Map),
            questionCountByMaterial: questionCountByMaterial,
            completedQuestionIdsByMaterial: completedQuestionIdsByMaterial,
            memoryScoresByMaterial: memoryScoresByMaterial,
            dueReviewCountByMaterial: dueReviewCountByMaterial,
            latestAttemptByMaterial: latestAttemptByMaterial,
            latestMemoryByMaterial: latestMemoryByMaterial,
            currentStreak: currentStreak,
            now: now,
          ))
      .toList(growable: false);

  return LibraryDashboard(
    todayReviewCount: dueReviewCountByMaterial.values.fold<int>(0, (sum, count) => sum + count),
    totalMemoryPercent: totalMemoryPercent,
    materials: materials,
    recentRecords: _recentRecords(materials),
  );
});

StudyMaterial _materialFromRow(
  Map<String, dynamic> row, {
  required Map<String, int> questionCountByMaterial,
  required Map<String, Set<String>> completedQuestionIdsByMaterial,
  required Map<String, List<double>> memoryScoresByMaterial,
  required Map<String, int> dueReviewCountByMaterial,
  required Map<String, DateTime> latestAttemptByMaterial,
  required Map<String, DateTime> latestMemoryByMaterial,
  required int currentStreak,
  required DateTime now,
}) {
  final id = row['id'].toString();
  final status = row['status'] as String? ?? 'uploaded';
  final totalQuestions = questionCountByMaterial[id] ?? 0;
  final completedQuestions = completedQuestionIdsByMaterial[id]?.length ?? 0;
  final progressPercent = totalQuestions == 0 ? _progressForStatus(status) : ((completedQuestions / totalQuestions) * 100).round().clamp(0, 100);
  final memoryPercent = _materialMemoryPercent(memoryScoresByMaterial[id] ?? const []);
  final latestStudyAt = latestAttemptByMaterial[id] ?? latestMemoryByMaterial[id] ?? _dateFrom(row['created_at']);
  final seed = _seedState(memoryPercent, progressPercent);

  return StudyMaterial(
    id: id,
    title: row['title'] as String? ?? 'Untitled material',
    sectionCount: 0,
    progressPercent: progressPercent,
    memoryPercent: memoryPercent,
    nextReviewLabel: status == 'completed' ? 'Ready' : _labelForStatus(status),
    totalQuestionCount: totalQuestions,
    completedQuestionCount: completedQuestions,
    dueReviewCount: dueReviewCountByMaterial[id] ?? 0,
    seedEmoji: seed.emoji,
    seedLabel: seed.label,
    recentStudyLabel: latestStudyAt == null ? '아직 학습 전' : _relativeTime(latestStudyAt, now),
    currentStreak: currentStreak,
    status: status,
  );
}

List<RecentStudyRecord> _recentRecords(List<StudyMaterial> materials) {
  return materials
      .where((material) => material.completedQuestionCount > 0)
      .take(3)
      .map((material) => RecentStudyRecord(
            title: material.title,
            subtitle: '최근 학습 ${material.recentStudyLabel} · 복습 예정 ${material.dueReviewCount}개',
            scoreLabel: '${material.memoryPercent}%',
          ))
      .toList(growable: false);
}

int _averageMemoryPercent(List<dynamic> rows) {
  if (rows.isEmpty) {
    return 0;
  }
  final total = rows.fold<double>(0, (sum, row) {
    final value = Map<String, dynamic>.from(row as Map)['memory_score'];
    return sum + _doubleFrom(value);
  });
  return ((total / rows.length) * 100).round().clamp(0, 100);
}

int _materialMemoryPercent(List<double> scores) {
  if (scores.isEmpty) {
    return 0;
  }
  final total = scores.fold<double>(0, (sum, score) => sum + score);
  return ((total / scores.length) * 100).round().clamp(0, 100);
}

_SeedState _seedState(int memoryPercent, int progressPercent) {
  if (memoryPercent >= 90 && progressPercent >= 90) return const _SeedState('🏅', '완성');
  if (memoryPercent >= 75) return const _SeedState('🌸', '개화');
  if (memoryPercent >= 55) return const _SeedState('🌳', '성장중');
  if (progressPercent > 0 || memoryPercent >= 25) return const _SeedState('🌿', '새싹');
  return const _SeedState('🌱', '씨앗');
}

String _relativeTime(DateTime date, DateTime now) {
  final localDate = date.toLocal();
  final localNow = now.toLocal();
  final difference = localNow.difference(localDate);
  if (difference.inMinutes < 1) return '방금 전';
  if (difference.inHours < 1) return '${difference.inMinutes}분 전';
  if (difference.inHours < 24) return '${difference.inHours}시간 전';
  if (difference.inDays == 1) return '어제';
  if (difference.inDays < 7) return '${difference.inDays}일 전';
  return '${localDate.month}/${localDate.day}';
}

DateTime? _dateFrom(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

double _doubleFrom(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _intFrom(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _progressForStatus(String status) {
  return switch (status) {
    'uploaded' => 10,
    'extracting' => 25,
    'analyzing' => 55,
    'concepts_completed' => 70,
    'questions_generating' => 85,
    'completed' => 0,
    'failed' => 0,
    _ => 0,
  };
}

String _labelForStatus(String status) {
  return switch (status) {
    'uploaded' => 'Uploaded',
    'extracting' => 'Extracting',
    'analyzing' => 'Analyzing',
    'concepts_completed' => 'Concepts ready',
    'questions_generating' => 'Generating quiz',
    'failed' => 'Failed',
    _ => status,
  };
}

class _SeedState {
  const _SeedState(this.emoji, this.label);

  final String emoji;
  final String label;
}
