import 'package:ai_memory_coach/features/profile/domain/profile_edit_snapshot.dart';
import 'package:ai_memory_coach/features/profile/domain/profile_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps only returned owned tree and badge choices', () {
    final snapshot = ProfileEditSnapshot.fromJson({
      'profile': {
        'nickname': '마메룸사용자',
        'bio': '꾸준히 공부해요',
        'today_goal': '복습 30문제',
        'updated_at': '2026-07-19T00:00:00Z',
        'featured_memory_seed_id': 'tree-1',
        'featured_user_badge_id': 'badge-1',
      },
      'trees': [
        {'id': 'tree-1', 'seed_type': 'blossom', 'growth_stage': 'complete'},
      ],
      'badges': [
        {'id': 'badge-1', 'name': '기억 마스터', 'grade': 'gold'},
      ],
    });

    expect(snapshot.nickname, '마메룸사용자');
    expect(snapshot.featuredTreeId, 'tree-1');
    expect(snapshot.trees.single.id, 'tree-1');
    expect(snapshot.badges.single.id, 'badge-1');
  });

  test('accepts nullable optional profile fields', () {
    final snapshot = ProfileEditSnapshot.fromJson({
      'profile': {
        'nickname': null,
        'bio': null,
        'today_goal': null,
        'avatar_key': null,
        'updated_at': '2026-07-19T00:00:00Z',
        'featured_memory_seed_id': null,
        'featured_user_badge_id': null,
      },
      'trees': null,
      'badges': null,
    });

    expect(snapshot.nickname, isEmpty);
    expect(snapshot.bio, isEmpty);
    expect(snapshot.todayGoal, isEmpty);
    expect(snapshot.avatarKey, isNull);
    expect(snapshot.trees, isEmpty);
    expect(snapshot.badges, isEmpty);
  });

  test('distinguishes a missing profile row from malformed data', () {
    expect(
      () => ProfileEditSnapshot.fromJson({
        'profile': null,
        'trees': const [],
        'badges': const [],
      }),
      throwsA(isA<ProfileNotFoundException>()),
    );
    expect(
      () => ProfileEditSnapshot.fromJson({
        'profile': {'nickname': '사용자', 'updated_at': 'not-a-date'},
        'trees': const [],
        'badges': const [],
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed choice rows instead of silently dropping them', () {
    expect(
      () => ProfileEditSnapshot.fromJson({
        'profile': {'nickname': '사용자', 'updated_at': '2026-07-19T00:00:00Z'},
        'trees': [null],
        'badges': const [],
      }),
      throwsFormatException,
    );
  });
}
