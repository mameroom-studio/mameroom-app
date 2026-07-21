import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/achievement.dart';
import '../../domain/entities/achievement_failure.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../datasources/achievement_remote_data_source.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  const AchievementRepositoryImpl(this._remote);

  final AchievementRemoteDataSource _remote;

  @override
  Future<AchievementOverview> loadOverview() => _execute(
    'get_achievement_overview',
    () async {
      final achievements = (await _remote.loadOverview()).map(_map).toList();
      final visible = achievements.where((item) => !item.isHidden).toList();
      final completed = visible
          .where(
            (item) =>
                item.status == AchievementStatus.completed ||
                item.status == AchievementStatus.rewarded,
          )
          .length;
      final badgeCount = visible
          .expand((item) => item.rewards)
          .where(
            (reward) =>
                reward.type == AchievementRewardType.badge && reward.delivered,
          )
          .length;
      final next = visible
          .where(
            (item) =>
                item.status == AchievementStatus.inProgress ||
                item.status == AchievementStatus.notStarted,
          )
          .firstOrNull;
      return AchievementOverview(
        summary: AchievementSummary(
          completed: completed,
          total: visible.length,
          badgeCount: badgeCount,
          nextAchievement: next,
        ),
        achievements: visible,
      );
    },
  );

  @override
  Future<Achievement> loadAchievement(String code) =>
      _execute('get_achievement_detail', () async {
        final overview = await loadOverview();
        return overview.achievements
                .where((item) => item.code == code)
                .firstOrNull ??
            (throw const AchievementNotFoundException());
      });

  @override
  Future<Achievement> refreshRewardState(String code) => _execute(
    'confirm_achievement_reward',
    () async => _map(await _remote.refreshRewardState(code)),
  );

  Achievement _map(Map<String, dynamic> row) {
    final code = _requiredString(row, 'code');
    final title = _requiredString(row, 'title');
    final description = _requiredString(row, 'description');
    final condition = _requiredString(row, 'condition_label');
    final target = _requiredPositiveInt(row, 'target_value');
    final progress = _optionalNonNegativeInt(row, 'progress_value');
    final category = _category(_requiredString(row, 'category'));
    final status = _status(_requiredString(row, 'status'));
    final rewardsValue = row['rewards'];
    if (rewardsValue != null && rewardsValue is! List) {
      throw const FormatException('achievement_rewards_is_not_a_list');
    }
    final rewards = (rewardsValue as List? ?? const [])
        .map((value) {
          if (value is! Map) {
            throw const FormatException('achievement_reward_is_not_an_object');
          }
          final reward = Map<String, dynamic>.from(value);
          return AchievementReward(
            type: _rewardType(_requiredString(reward, 'type')),
            label: _requiredString(reward, 'label'),
            amount: _nullableInt(reward, 'amount'),
            assetPath: reward['asset_path'] as String?,
            delivered: reward['delivered'] == true,
          );
        })
        .toList(growable: false);
    final rawCompletedAt = row['completed_at'];
    final completedAt = rawCompletedAt == null
        ? null
        : DateTime.tryParse(rawCompletedAt as String);
    if (rawCompletedAt != null && completedAt == null) {
      throw const FormatException('achievement_completed_at_is_invalid');
    }
    return Achievement(
      code: code,
      title: title,
      description: description,
      category: category,
      status: status,
      current: progress,
      target: target,
      condition: condition,
      rewards: rewards,
      iconAsset: row['icon_asset'] as String?,
      completedAt: completedAt,
      badgeGrade: _grade(row['badge_grade'] as String?),
      isHidden: row['is_hidden'] == true,
    );
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('achievement_$key is invalid');
    }
    return value;
  }

  static int _requiredPositiveInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! num || value.toInt() <= 0) {
      throw FormatException('achievement_$key is invalid');
    }
    return value.toInt();
  }

  static int _optionalNonNegativeInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return 0;
    if (value is! num || value.toInt() < 0) {
      throw FormatException('achievement_$key is invalid');
    }
    return value.toInt();
  }

  static int? _nullableInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is! num) throw FormatException('achievement_$key is invalid');
    return value.toInt();
  }

  AchievementCategory _category(String value) =>
      AchievementCategory.values
          .where((item) => item.name == value)
          .firstOrNull ??
      (throw const FormatException('achievement_category_is_unknown'));

  AchievementStatus _status(String value) =>
      AchievementStatus.values
          .where((item) => item.name == value)
          .firstOrNull ??
      (throw const FormatException('achievement_status_is_unknown'));

  AchievementRewardType _rewardType(String value) =>
      AchievementRewardType.values
          .where((item) => item.name == value)
          .firstOrNull ??
      (throw const FormatException('achievement_reward_type_is_unknown'));

  BadgeGrade? _grade(String? value) {
    if (value == null) return null;
    return BadgeGrade.values.where((item) => item.name == value).firstOrNull ??
        (throw const FormatException('achievement_badge_grade_is_unknown'));
  }

  Future<T> _execute<T>(String operation, Future<T> Function() request) async {
    try {
      if (kDebugMode) {
        debugPrint('[Achievement][$operation] request started');
      }
      final value = await request();
      if (kDebugMode) {
        final count = value is AchievementOverview
            ? value.achievements.length
            : 1;
        debugPrint(
          '[Achievement][$operation] response parsed (rowCount=$count)',
        );
      }
      return value;
    } on AchievementFailure catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      rethrow;
    } on AchievementNotFoundException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw AchievementFailure(
        AchievementFailureKind.notFound,
        '해당 업적을 찾을 수 없어요.',
        operation: operation,
      );
    } on PostgrestException catch (error, stackTrace) {
      _logPostgrest(operation, error, stackTrace);
      throw _mapPostgrest(error, operation);
    } on AuthException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw AchievementFailure(
        AchievementFailureKind.authentication,
        '로그인 정보를 확인할 수 없어요.',
        operation: operation,
      );
    } on SocketException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw AchievementFailure(
        AchievementFailureKind.network,
        _temporaryMessage,
        operation: operation,
      );
    } on TimeoutException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw AchievementFailure(
        AchievementFailureKind.timeout,
        _temporaryMessage,
        operation: operation,
      );
    } on FormatException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw AchievementFailure(
        AchievementFailureKind.parsing,
        _temporaryMessage,
        operation: operation,
      );
    } on TypeError catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw AchievementFailure(
        AchievementFailureKind.parsing,
        _temporaryMessage,
        operation: operation,
      );
    } catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw AchievementFailure(
        AchievementFailureKind.unknown,
        _temporaryMessage,
        operation: operation,
      );
    }
  }

  static AchievementFailure _mapPostgrest(
    PostgrestException error,
    String operation,
  ) {
    if (error.code == 'PGRST301' ||
        error.code == '28000' ||
        error.message.contains('Authentication is required')) {
      return AchievementFailure(
        AchievementFailureKind.authentication,
        '로그인 정보를 확인할 수 없어요.',
        operation: operation,
      );
    }
    if (error.code == '42501') {
      return AchievementFailure(
        AchievementFailureKind.authorization,
        '업적 정보를 볼 권한이 없어요.',
        operation: operation,
      );
    }
    if (error.code == 'PGRST202' ||
        error.code == '42P01' ||
        error.code == '42703' ||
        error.message.contains('schema cache')) {
      return AchievementFailure(
        AchievementFailureKind.schema,
        _temporaryMessage,
        operation: operation,
      );
    }
    return AchievementFailure(
      AchievementFailureKind.server,
      _temporaryMessage,
      operation: operation,
    );
  }

  static void _logPostgrest(
    String operation,
    PostgrestException error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      '[Achievement][$operation] PostgrestException '
      'code=${_redact(error.code ?? '<none>')} '
      'message=${_redact(error.message)} '
      'details=${_redact('${error.details}')} '
      'hint=${_redact('${error.hint}')}',
    );
    debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
  }

  static void _logFailure(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      '[Achievement][$operation] ${error.runtimeType}: ${_redact('$error')}',
    );
    debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
  }

  static String _redact(String value) => value
      .replaceAll(
        RegExp(r'Bearer\s+[A-Za-z0-9._-]+', caseSensitive: false),
        'Bearer <redacted>',
      )
      .replaceAll(
        RegExp(r'[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'),
        '<token>',
      )
      .replaceAll(
        RegExp(
          r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}',
        ),
        '<uuid>',
      )
      .replaceAll(RegExp(r'\)=\([^)]+\)'), ')=(<redacted>)')
      .replaceAll(
        RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
        '<email>',
      );
}

const _temporaryMessage = '업적을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
