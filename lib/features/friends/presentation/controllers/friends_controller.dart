import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/repositories/friends_repository_impl.dart';
import '../../domain/entities/friend_profile.dart';
import '../../domain/entities/friends_failure.dart';
import '../../domain/repositories/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? DemoFriendsRepository()
      : SupabaseFriendsRepository(client);
});

final friendsControllerProvider =
    StateNotifierProvider<FriendsController, FriendsState>((ref) {
      final controller = FriendsController(
        ref.watch(friendsRepositoryProvider),
      );
      return controller..loadOverview();
    });

final class FriendsState {
  const FriendsState({
    this.query = '',
    this.results = const [],
    this.recommended = const [],
    this.friends = const [],
    this.incoming = const [],
    this.recentQueries = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.errorKind,
    this.friendsFailure,
    this.incomingFailure,
    this.validationMessage,
    this.nextCursor,
  });
  final String query;
  final List<FriendProfile> results;
  final List<FriendProfile> recommended;
  final List<FriendProfile> friends;
  final List<FriendProfile> incoming;
  final List<String> recentQueries;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final FriendsFailureKind? errorKind;
  final FriendsFailure? friendsFailure;
  final FriendsFailure? incomingFailure;
  final String? validationMessage;
  final String? nextCursor;

  FriendsState copyWith({
    String? query,
    List<FriendProfile>? results,
    List<FriendProfile>? recommended,
    List<FriendProfile>? friends,
    List<FriendProfile>? incoming,
    List<String>? recentQueries,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    FriendsFailureKind? errorKind,
    bool clearError = false,
    FriendsFailure? friendsFailure,
    FriendsFailure? incomingFailure,
    bool clearFriendsFailure = false,
    bool clearIncomingFailure = false,
    String? validationMessage,
    bool clearValidation = false,
    String? nextCursor,
    bool clearCursor = false,
  }) => FriendsState(
    query: query ?? this.query,
    results: results ?? this.results,
    recommended: recommended ?? this.recommended,
    friends: friends ?? this.friends,
    incoming: incoming ?? this.incoming,
    recentQueries: recentQueries ?? this.recentQueries,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    errorKind: clearError ? null : errorKind ?? this.errorKind,
    friendsFailure: clearFriendsFailure
        ? null
        : friendsFailure ?? this.friendsFailure,
    incomingFailure: clearIncomingFailure
        ? null
        : incomingFailure ?? this.incomingFailure,
    validationMessage: clearValidation
        ? null
        : validationMessage ?? this.validationMessage,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
  );
}

final class FriendsController extends StateNotifier<FriendsState> {
  FriendsController(this._repository) : super(const FriendsState());
  final FriendsRepository _repository;
  Timer? _debounce;
  int _searchGeneration = 0;

  Future<void> loadOverview({bool refreshing = false}) async {
    state = state.copyWith(
      isRefreshing: true,
      clearError: true,
      clearFriendsFailure: true,
      clearIncomingFailure: true,
    );
    final results = await Future.wait([
      _capture(_repository.friends, operation: 'friends'),
      _capture(_repository.incomingRequests, operation: 'incoming'),
    ]);
    if (!mounted) return;
    final friendsResult = results[0];
    final incomingResult = results[1];
    state = state.copyWith(
      friends: friendsResult.items,
      incoming: incomingResult.items,
      friendsFailure: friendsResult.failure,
      incomingFailure: incomingResult.failure,
      clearFriendsFailure: friendsResult.failure == null,
      clearIncomingFailure: incomingResult.failure == null,
      isRefreshing: false,
    );
  }

  Future<_FriendsSectionResult> _capture(
    Future<List<FriendProfile>> Function() request, {
    required String operation,
  }) async {
    try {
      return _FriendsSectionResult(items: await request());
    } on FriendsFailure catch (error) {
      return _FriendsSectionResult(failure: error);
    } catch (_) {
      return _FriendsSectionResult(
        failure: FriendsFailure(
          FriendsFailureKind.unknown,
          '잠시 후 다시 시도해 주세요.',
          operation: operation,
        ),
      );
    }
  }

  void queryChanged(String value) {
    state = state.copyWith(
      query: value,
      clearError: true,
      clearValidation: true,
    );
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      state = state.copyWith(
        results: const [],
        isLoading: false,
        clearCursor: true,
      );
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => search());
  }

  Future<void> search({bool append = false}) async {
    final query = state.query;
    final generation = ++_searchGeneration;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearValidation: true,
    );
    try {
      final page = await _repository.search(
        query: query,
        cursor: append ? state.nextCursor : null,
      );
      if (!mounted || generation != _searchGeneration) return;
      final recent = [
        query.trim(),
        ...state.recentQueries.where((e) => e != query.trim()),
      ].take(5).toList();
      state = state.copyWith(
        results: append ? [...state.results, ...page.items] : page.items,
        nextCursor: page.nextCursor,
        recentQueries: recent,
        isLoading: false,
        clearCursor: page.nextCursor == null,
      );
    } on FriendsFailure catch (error) {
      if (!mounted) return;
      state = error.kind == FriendsFailureKind.validation
          ? state.copyWith(isLoading: false, validationMessage: error.message)
          : state.copyWith(
              isLoading: false,
              errorMessage: error.message,
              errorKind: error.kind,
            );
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '친구 정보를 불러오지 못했어요.',
          errorKind: FriendsFailureKind.unknown,
        );
      }
    }
  }

  Future<String?> act(FriendProfile profile) async {
    if (profile.isProcessing) return null;
    _setProcessing(profile.id, true);
    try {
      switch (profile.relationship) {
        case FriendRelationshipState.none ||
            FriendRelationshipState.rejected ||
            FriendRelationshipState.expired ||
            FriendRelationshipState.cancelled:
          await _repository.sendRequest(profile.id);
        case FriendRelationshipState.outgoingPending:
          if (profile.requestId != null) {
            await _repository.cancelRequest(profile.requestId!);
          }
        case FriendRelationshipState.incomingPending:
          if (profile.requestId != null) {
            await _repository.respondToRequest(
              profile.requestId!,
              accept: true,
            );
          }
        case FriendRelationshipState.blockedByMe:
          await _repository.unblockUser(profile.id);
        default:
          return null;
      }
      await _resync();
      return '친구 상태가 반영되었어요.';
    } catch (error) {
      _setProcessing(profile.id, false);
      return _message(error);
    }
  }

  Future<String?> reject(FriendProfile p) async {
    if (p.requestId == null || p.isProcessing) return null;
    _setProcessing(p.id, true);
    try {
      await _repository.respondToRequest(p.requestId!, accept: false);
      await _resync();
      return '친구 요청을 거절했어요.';
    } catch (e) {
      _setProcessing(p.id, false);
      return _message(e);
    }
  }

  Future<String?> deleteFriend(String id) async {
    final friend = state.friends.where((item) => item.id == id).firstOrNull;
    if (friend?.isProcessing ?? false) return null;
    _setProcessing(id, true);
    try {
      await _repository.deleteFriend(id);
      await _resync();
      return '친구를 삭제했어요.';
    } catch (e) {
      _setProcessing(id, false);
      return _message(e);
    }
  }

  Future<String?> block(String id) async {
    try {
      await _repository.blockUser(id);
      await _resync();
      return '사용자를 차단했어요.';
    } catch (e) {
      return _message(e);
    }
  }

  Future<void> _resync() async {
    await loadOverview();
    if (state.query.trim().isNotEmpty) await search();
  }

  void _setProcessing(String id, bool value) {
    FriendProfile map(FriendProfile p) =>
        p.id == id ? p.copyWith(isProcessing: value) : p;
    state = state.copyWith(
      results: state.results.map(map).toList(),
      recommended: state.recommended.map(map).toList(),
      incoming: state.incoming.map(map).toList(),
      friends: state.friends.map(map).toList(),
    );
  }

  String _message(Object error) =>
      error is FriendsFailure ? error.message : '잠시 후 다시 시도해 주세요.';
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final class _FriendsSectionResult {
  const _FriendsSectionResult({this.items = const [], this.failure});

  final List<FriendProfile> items;
  final FriendsFailure? failure;
}
