import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile_edit_snapshot.dart';
import '../domain/profile_failure.dart';

abstract interface class ProfileRepository {
  Future<ProfileEditSnapshot> load();
  Future<ProfileEditSnapshot> save({
    required String nickname,
    required String bio,
    required String todayGoal,
    required DateTime expectedUpdatedAt,
    String? featuredTreeId,
    String? featuredBadgeId,
  });
}

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<ProfileEditSnapshot> load() =>
      _execute('get_my_edit_profile', () async {
        _requireSession('get_my_edit_profile');
        final result = await _client.rpc('get_my_edit_profile');
        return _decode(result);
      });

  @override
  Future<ProfileEditSnapshot> save({
    required String nickname,
    required String bio,
    required String todayGoal,
    required DateTime expectedUpdatedAt,
    String? featuredTreeId,
    String? featuredBadgeId,
  }) => _execute('update_my_profile', () async {
    _requireSession('update_my_profile');
    final result = await _client.rpc(
      'update_my_profile',
      params: {
        'p_nickname': nickname,
        'p_bio': bio,
        'p_today_goal': todayGoal,
        'p_featured_memory_seed_id': featuredTreeId,
        'p_featured_user_badge_id': featuredBadgeId,
        'p_expected_updated_at': expectedUpdatedAt.toUtc().toIso8601String(),
      },
    );
    return _decode(result);
  });

  void _requireSession(String operation) {
    if (_client.auth.currentSession == null ||
        _client.auth.currentUser == null) {
      throw ProfileFailure(
        ProfileFailureKind.authentication,
        _authenticationMessage,
        operation: operation,
      );
    }
  }

  static ProfileEditSnapshot _decode(Object? result) {
    if (result is! Map) {
      throw const FormatException('profile_rpc_response_is_not_an_object');
    }
    return ProfileEditSnapshot.fromJson(Map<String, dynamic>.from(result));
  }

  Future<T> _execute<T>(String operation, Future<T> Function() request) async {
    try {
      if (kDebugMode) {
        debugPrint('[Profile][$operation] request started');
      }
      final value = await request();
      if (kDebugMode) {
        debugPrint('[Profile][$operation] response parsed successfully');
      }
      return value;
    } on ProfileFailure catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      rethrow;
    } on ProfileNotFoundException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw ProfileFailure(
        ProfileFailureKind.notFound,
        _notFoundMessage,
        operation: operation,
      );
    } on PostgrestException catch (error, stackTrace) {
      _logPostgrest(operation, error, stackTrace);
      throw _mapPostgrest(error, operation);
    } on AuthException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw ProfileFailure(
        ProfileFailureKind.authentication,
        _authenticationMessage,
        operation: operation,
      );
    } on SocketException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw ProfileFailure(
        ProfileFailureKind.network,
        _networkMessage,
        operation: operation,
      );
    } on TimeoutException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw ProfileFailure(
        ProfileFailureKind.timeout,
        _networkMessage,
        operation: operation,
      );
    } on FormatException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw ProfileFailure(
        ProfileFailureKind.parsing,
        _parsingMessage,
        operation: operation,
      );
    } on TypeError catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw ProfileFailure(
        ProfileFailureKind.parsing,
        _parsingMessage,
        operation: operation,
      );
    } catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw ProfileFailure(
        ProfileFailureKind.unknown,
        _serverMessage,
        operation: operation,
      );
    }
  }

  static ProfileFailure _mapPostgrest(
    PostgrestException error,
    String operation,
  ) {
    if (error.code == 'PGRST301' ||
        error.code == '28000' ||
        error.message.contains('Authentication is required')) {
      return ProfileFailure(
        ProfileFailureKind.authentication,
        _authenticationMessage,
        operation: operation,
      );
    }
    if (error.code == '42501') {
      return ProfileFailure(
        ProfileFailureKind.authorization,
        _authorizationMessage,
        operation: operation,
      );
    }
    if (error.code == 'P0002') {
      return ProfileFailure(
        ProfileFailureKind.notFound,
        _notFoundMessage,
        operation: operation,
      );
    }
    if (error.code == 'PGRST202' ||
        error.code == '42P01' ||
        error.code == '42703' ||
        error.message.contains('schema cache')) {
      return ProfileFailure(
        ProfileFailureKind.schema,
        _serverMessage,
        operation: operation,
      );
    }
    if (error.code == '23505' || error.code == '40001') {
      return ProfileFailure(
        ProfileFailureKind.conflict,
        error.code == '23505'
            ? '이미 사용 중인 닉네임입니다.'
            : '다른 기기에서 변경되었습니다. 다시 불러와 주세요.',
        operation: operation,
      );
    }
    if (error.code == '22023') {
      return ProfileFailure(
        ProfileFailureKind.validation,
        '입력한 프로필 정보를 확인해 주세요.',
        operation: operation,
      );
    }
    return ProfileFailure(
      ProfileFailureKind.server,
      _serverMessage,
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
      '[Profile][$operation] PostgrestException '
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
      '[Profile][$operation] ${error.runtimeType}: ${_redact('$error')}',
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

const _authenticationMessage = '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.';
const _notFoundMessage = '프로필 정보가 아직 준비되지 않았습니다.';
const _authorizationMessage = '프로필 정보를 볼 권한이 없습니다.';
const _networkMessage = '인터넷 연결을 확인한 뒤 다시 시도해 주세요.';
const _serverMessage = '프로필 서비스를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
const _parsingMessage = '프로필 정보를 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';
