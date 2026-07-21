import 'profile_failure.dart';

class ProfileChoice {
  const ProfileChoice({required this.id, required this.title, this.subtitle});
  final String id;
  final String title;
  final String? subtitle;
}

class ProfileEditSnapshot {
  const ProfileEditSnapshot({
    required this.nickname,
    required this.bio,
    required this.todayGoal,
    required this.updatedAt,
    required this.trees,
    required this.badges,
    this.avatarKey,
    this.featuredTreeId,
    this.featuredBadgeId,
  });

  final String nickname;
  final String bio;
  final String todayGoal;
  final String? avatarKey;
  final DateTime updatedAt;
  final String? featuredTreeId;
  final String? featuredBadgeId;
  final List<ProfileChoice> trees;
  final List<ProfileChoice> badges;

  factory ProfileEditSnapshot.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    if (rawProfile == null) throw const ProfileNotFoundException();
    if (rawProfile is! Map) {
      throw const FormatException('profile_response_profile_is_not_an_object');
    }
    final profile = Map<String, dynamic>.from(rawProfile);
    final rawUpdatedAt = profile['updated_at'];
    final updatedAt = rawUpdatedAt is String
        ? DateTime.tryParse(rawUpdatedAt)
        : null;
    if (updatedAt == null) {
      throw const FormatException('profile_response_updated_at_is_invalid');
    }

    List<ProfileChoice> choices(Object? value, bool tree) {
      if (value == null) return const [];
      if (value is! List) {
        throw const FormatException('profile_response_choices_is_not_a_list');
      }
      return value
          .map((item) {
            if (item is! Map) {
              throw const FormatException(
                'profile_response_choice_is_not_an_object',
              );
            }
            final map = Map<String, dynamic>.from(item);
            final id = map['id'];
            if (id is! String || id.isEmpty) {
              throw const FormatException(
                'profile_response_choice_id_is_invalid',
              );
            }
            return ProfileChoice(
              id: id,
              title: tree
                  ? '${map['seed_type'] ?? 'memory'} 기억나무'
                  : '${map['name'] ?? 'Badge'}',
              subtitle: tree
                  ? '${map['growth_stage'] ?? 'complete'}'
                  : map['grade'] as String?,
            );
          })
          .toList(growable: false);
    }

    return ProfileEditSnapshot(
      nickname: profile['nickname'] as String? ?? '',
      bio: profile['bio'] as String? ?? '',
      todayGoal: profile['today_goal'] as String? ?? '',
      avatarKey: profile['avatar_key'] as String?,
      updatedAt: updatedAt,
      featuredTreeId: profile['featured_memory_seed_id'] as String?,
      featuredBadgeId: profile['featured_user_badge_id'] as String?,
      trees: choices(json['trees'], true),
      badges: choices(json['badges'], false),
    );
  }
}
