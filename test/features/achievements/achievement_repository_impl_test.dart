import 'package:ai_memory_coach/features/achievements/data/datasources/achievement_remote_data_source.dart';
import 'package:ai_memory_coach/features/achievements/data/repositories/achievement_repository_impl.dart';
import 'package:ai_memory_coach/features/achievements/domain/entities/achievement_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('zero RPC rows produce a normal empty overview', () async {
    final repository = AchievementRepositoryImpl(_FakeRemote(rows: const []));

    final overview = await repository.loadOverview();

    expect(overview.achievements, isEmpty);
    expect(overview.summary.total, 0);
    expect(overview.summary.nextAchievement, isNull);
  });

  test('nullable optional values are accepted', () async {
    final repository = AchievementRepositoryImpl(
      _FakeRemote(rows: [_validRow()]),
    );

    final overview = await repository.loadOverview();

    expect(overview.achievements.single.iconAsset, isNull);
    expect(overview.achievements.single.completedAt, isNull);
    expect(overview.achievements.single.rewards, isEmpty);
  });

  test('malformed model values are reported as parsing failures', () async {
    final repository = AchievementRepositoryImpl(
      _FakeRemote(rows: [_validRow()..['target_value'] = null]),
    );

    await expectLater(
      repository.loadOverview(),
      throwsA(
        isA<AchievementFailure>().having(
          (failure) => failure.kind,
          'kind',
          AchievementFailureKind.parsing,
        ),
      ),
    );
  });

  test('missing RPC is reported as schema failure', () async {
    final repository = AchievementRepositoryImpl(
      _FakeRemote(
        error: const PostgrestException(
          message: 'Could not find the function in the schema cache',
          code: 'PGRST202',
        ),
      ),
    );

    await expectLater(
      repository.loadOverview(),
      throwsA(
        isA<AchievementFailure>().having(
          (failure) => failure.kind,
          'kind',
          AchievementFailureKind.schema,
        ),
      ),
    );
  });
}

Map<String, dynamic> _validRow() => {
  'code': 'study_first',
  'title': '첫 공부',
  'description': '첫 학습을 완료해요.',
  'category': 'learning',
  'condition_label': '학습 1회 완료',
  'target_value': 1,
  'progress_value': 0,
  'status': 'notStarted',
  'icon_asset': null,
  'completed_at': null,
  'badge_grade': null,
  'is_hidden': false,
  'rewards': const [],
};

class _FakeRemote extends AchievementRemoteDataSource {
  _FakeRemote({this.rows = const [], this.error})
    : super(SupabaseClient('http://localhost', 'test-anon-key'));

  final List<Map<String, dynamic>> rows;
  final Object? error;

  @override
  Future<List<Map<String, dynamic>>> loadOverview() async {
    if (error case final error?) throw error;
    return rows;
  }
}
