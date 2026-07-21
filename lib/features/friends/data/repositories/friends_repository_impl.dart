import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/friend_profile.dart';
import '../../domain/entities/friends_failure.dart';
import '../../domain/policies/friend_relationship_policy.dart';
import '../../domain/repositories/friends_repository.dart';

final class SupabaseFriendsRepository implements FriendsRepository {
  const SupabaseFriendsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<FriendPage<FriendProfile>> search({
    required String query,
    String? cursor,
  }) async {
    final error = FriendRelationshipPolicy.validateQuery(query);
    if (error != null) {
      throw FriendsFailure(FriendsFailureKind.validation, error);
    }
    return _execute('search_friend_profiles', () async {
      final rows =
          await _client.rpc(
                'search_friend_profiles',
                params: {
                  'p_query': FriendRelationshipPolicy.normalizeQuery(query),
                  'p_limit': 20,
                  'p_cursor': cursor,
                },
              )
              as List<dynamic>;
      final profiles = rows
          .map((row) => _profile(row as Map<String, dynamic>))
          .toList();
      return FriendPage(
        items: profiles,
        nextCursor: profiles.length == 20 ? profiles.last.id : null,
      );
    });
  }

  @override
  Future<List<FriendProfile>> recommended() => _list('recommended');
  @override
  Future<List<FriendProfile>> friends() => _list('friends');
  @override
  Future<List<FriendProfile>> incomingRequests() => _list('incoming');

  Future<List<FriendProfile>> _list(String kind) => _execute(
    'list_friend_profiles:$kind',
    () async {
      final rows =
          await _client.rpc('list_friend_profiles', params: {'p_kind': kind})
              as List<dynamic>;
      return rows.map((row) => _profile(row as Map<String, dynamic>)).toList();
    },
  );

  @override
  Future<FriendProfile> sendRequest(String userId) =>
      _execute('send_friend_request', () async {
        final requestId =
            await _client.rpc(
                  'send_friend_request',
                  params: {
                    'p_receiver_id': userId,
                    'p_idempotency_key': _uuidV4(),
                  },
                )
                as String;
        return FriendProfile(
          id: userId,
          nickname: '',
          friendCode: '',
          level: 1,
          statusMessage: '',
          relationship: FriendRelationshipState.outgoingPending,
          roomVisibility: FriendRoomVisibility.friends,
          requestId: requestId,
        );
      });

  @override
  Future<void> respondToRequest(String requestId, {required bool accept}) =>
      _voidRpc('respond_friend_request', {
        'p_request_id': requestId,
        'p_accept': accept,
      });
  @override
  Future<void> cancelRequest(String requestId) =>
      _voidRpc('cancel_friend_request', {'p_request_id': requestId});
  @override
  Future<void> deleteFriend(String userId) =>
      _voidRpc('remove_friend', {'p_friend_id': userId});
  @override
  Future<void> blockUser(String userId) =>
      _voidRpc('set_user_block', {'p_user_id': userId, 'p_blocked': true});
  @override
  Future<void> unblockUser(String userId) =>
      _voidRpc('set_user_block', {'p_user_id': userId, 'p_blocked': false});

  Future<void> _voidRpc(String name, Map<String, Object?> params) =>
      _execute(name, () async {
        await _client.rpc(name, params: params);
      });

  Future<T> _execute<T>(String operation, Future<T> Function() request) async {
    try {
      return await request();
    } on PostgrestException catch (error, stackTrace) {
      _logPostgrest(operation, error, stackTrace);
      throw _mapPostgrest(error, operation);
    } on AuthException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw FriendsFailure(
        FriendsFailureKind.authentication,
        _authenticationMessage,
        operation: operation,
      );
    } on SocketException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw FriendsFailure(
        FriendsFailureKind.network,
        _networkMessage,
        operation: operation,
      );
    } on TimeoutException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw FriendsFailure(
        FriendsFailureKind.timeout,
        _timeoutMessage,
        operation: operation,
      );
    } on FormatException catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw FriendsFailure(
        FriendsFailureKind.parsing,
        _parsingMessage,
        operation: operation,
      );
    } on TypeError catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw FriendsFailure(
        FriendsFailureKind.parsing,
        _parsingMessage,
        operation: operation,
      );
    } catch (error, stackTrace) {
      _logFailure(operation, error, stackTrace);
      throw FriendsFailure(
        FriendsFailureKind.unknown,
        _serverMessage,
        operation: operation,
      );
    }
  }

  static FriendProfile _profile(Map<String, dynamic> json) {
    final id = json['user_id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('friend_profile_missing_user_id');
    }
    return FriendProfile(
      id: id,
      nickname: json['nickname'] as String? ?? '',
      friendCode: json['friend_code'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      statusMessage: json['status_message'] as String? ?? '',
      relationship: FriendRelationshipState.values.firstWhere(
        (value) => value.name == json['relationship_state'],
        orElse: () => FriendRelationshipState.unavailable,
      ),
      roomVisibility: FriendRoomVisibility.values.firstWhere(
        (value) => value.name == json['room_visibility'],
        orElse: () => FriendRoomVisibility.private,
      ),
      avatarKey: json['avatar_key'] as String?,
      requestId: json['request_id'] as String?,
      requestedAt: DateTime.tryParse(json['requested_at'] as String? ?? ''),
    );
  }

  static FriendsFailure _mapPostgrest(
    PostgrestException error,
    String operation,
  ) {
    final message = error.message;
    if (message.contains('self_request') ||
        message.contains('query_too_short')) {
      return FriendsFailure(
        FriendsFailureKind.validation,
        message.contains('self_request') ? _selfRequestMessage : _queryMessage,
        operation: operation,
      );
    }
    if (message.contains('already_friends') ||
        message.contains('incoming_request_exists') ||
        message.contains('expired') ||
        error.code == '23505' ||
        error.code == '23514') {
      return FriendsFailure(
        FriendsFailureKind.conflict,
        _conflictMessage,
        operation: operation,
      );
    }
    if (error.code == 'PGRST301' ||
        message.contains('authentication_required')) {
      return FriendsFailure(
        FriendsFailureKind.authentication,
        _authenticationMessage,
        operation: operation,
      );
    }
    if (error.code == '42501' || message.contains('blocked')) {
      return FriendsFailure(
        FriendsFailureKind.authorization,
        _authorizationMessage,
        operation: operation,
      );
    }
    if (error.code == 'PGRST202' ||
        error.code == '42P01' ||
        error.code == '42703' ||
        message.contains('schema cache')) {
      return FriendsFailure(
        FriendsFailureKind.schema,
        _schemaMessage,
        operation: operation,
      );
    }
    return FriendsFailure(
      FriendsFailureKind.server,
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
      '[Friends][$operation] PostgrestException '
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
      '[Friends][$operation] ${error.runtimeType}: ${_redact('$error')}',
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
      .replaceAll(
        RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
        '<email>',
      );
}

const _authenticationMessage =
    '\uB85C\uADF8\uC778 \uC815\uBCF4\uAC00 \uB9CC\uB8CC\uB418\uC5C8\uC5B4\uC694.';
const _authorizationMessage =
    '\uCE5C\uAD6C \uC815\uBCF4\uB97C \uBCFC \uAD8C\uD55C\uC774 \uC5C6\uC5B4\uC694.';
const _networkMessage =
    '\uC778\uD130\uB137 \uC5F0\uACB0\uC744 \uD655\uC778\uD574 \uC8FC\uC138\uC694.';
const _timeoutMessage =
    '\uC11C\uBC84 \uC751\uB2F5\uC774 \uC9C0\uC5F0\uB418\uACE0 \uC788\uC5B4\uC694.';
const _schemaMessage =
    '\uCE5C\uAD6C \uC11C\uBE44\uC2A4\uB97C \uC900\uBE44\uD558\uB294 \uC911\uC774\uC5D0\uC694.';
const _serverMessage =
    '\uCE5C\uAD6C \uC815\uBCF4\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC5B4\uC694.';
const _parsingMessage =
    '\uCE5C\uAD6C \uC815\uBCF4\uB97C \uCC98\uB9AC\uD558\uC9C0 \uBABB\uD588\uC5B4\uC694.';
const _selfRequestMessage =
    '\uBCF8\uC778\uC5D0\uAC8C \uCE5C\uAD6C \uC694\uCCAD\uC744 \uBCF4\uB0BC \uC218 \uC5C6\uC5B4\uC694.';
const _queryMessage =
    '\uAC80\uC0C9\uC5B4\uB97C 2\uC790 \uC774\uC0C1 \uC785\uB825\uD574 \uC8FC\uC138\uC694.';
const _conflictMessage =
    '\uCE5C\uAD6C \uC0C1\uD0DC\uAC00 \uC774\uBBF8 \uBCC0\uACBD\uB418\uC5C8\uC5B4\uC694. \uC0C8\uB85C\uACE0\uCE68\uD574 \uC8FC\uC138\uC694.';

final class DemoFriendsRepository implements FriendsRepository {
  final List<FriendProfile> _profiles = List.of(_demoProfiles);
  @override
  Future<FriendPage<FriendProfile>> search({
    required String query,
    String? cursor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final error = FriendRelationshipPolicy.validateQuery(query);
    if (error != null) {
      throw FriendsFailure(FriendsFailureKind.validation, error);
    }
    final q = FriendRelationshipPolicy.normalizeQuery(query);
    return FriendPage(
      items: _profiles
          .where(
            (p) =>
                p.nickname.toLowerCase().contains(q) ||
                p.friendCode.toLowerCase() == q,
          )
          .toList(),
    );
  }

  @override
  Future<List<FriendProfile>> recommended() async => _profiles.take(3).toList();
  @override
  Future<List<FriendProfile>> friends() async => _profiles
      .where((p) => p.relationship == FriendRelationshipState.accepted)
      .toList();
  @override
  Future<List<FriendProfile>> incomingRequests() async => _profiles
      .where((p) => p.relationship == FriendRelationshipState.incomingPending)
      .toList();
  @override
  Future<FriendProfile> sendRequest(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _replace(userId, FriendRelationshipState.outgoingPending);
  }

  @override
  Future<void> respondToRequest(
    String requestId, {
    required bool accept,
  }) async {
    final p = _profiles.firstWhere((e) => e.requestId == requestId);
    _replace(
      p.id,
      accept
          ? FriendRelationshipState.accepted
          : FriendRelationshipState.rejected,
    );
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    final p = _profiles.firstWhere((e) => e.requestId == requestId);
    _replace(p.id, FriendRelationshipState.cancelled);
  }

  @override
  Future<void> deleteFriend(String userId) async {
    _replace(userId, FriendRelationshipState.none);
  }

  @override
  Future<void> blockUser(String userId) async {
    _replace(userId, FriendRelationshipState.blockedByMe);
  }

  @override
  Future<void> unblockUser(String userId) async {
    _replace(userId, FriendRelationshipState.none);
  }

  FriendProfile _replace(String id, FriendRelationshipState state) {
    final index = _profiles.indexWhere((e) => e.id == id);
    final updated = _profiles[index].copyWith(
      relationship: state,
      requestId: state == FriendRelationshipState.outgoingPending
          ? 'request-$id'
          : _profiles[index].requestId,
    );
    _profiles[index] = updated;
    return updated;
  }
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

const _demoProfiles = <FriendProfile>[
  FriendProfile(
    id: 'demo-yui',
    nickname: '유이',
    friendCode: 'YUI204',
    level: 18,
    statusMessage: '함께 공부해요!',
    relationship: FriendRelationshipState.none,
    roomVisibility: FriendRoomVisibility.public,
  ),
  FriendProfile(
    id: 'demo-minho',
    nickname: '민호',
    friendCode: 'MINHO7',
    level: 17,
    statusMessage: '오늘도 한 걸음',
    relationship: FriendRelationshipState.incomingPending,
    roomVisibility: FriendRoomVisibility.friends,
    requestId: 'request-minho',
  ),
  FriendProfile(
    id: 'friend-hyunwoo',
    nickname: '지훈',
    friendCode: 'JH120',
    level: 16,
    statusMessage: '복습 완료!',
    relationship: FriendRelationshipState.accepted,
    roomVisibility: FriendRoomVisibility.friends,
  ),
  FriendProfile(
    id: 'demo-me',
    nickname: '나 (본인)',
    friendCode: 'ME001',
    level: 18,
    statusMessage: '',
    relationship: FriendRelationshipState.self,
    roomVisibility: FriendRoomVisibility.private,
  ),
  FriendProfile(
    id: 'demo-blocked',
    nickname: '현수',
    friendCode: 'HS999',
    level: 15,
    statusMessage: '',
    relationship: FriendRelationshipState.blockedByMe,
    roomVisibility: FriendRoomVisibility.private,
  ),
];
