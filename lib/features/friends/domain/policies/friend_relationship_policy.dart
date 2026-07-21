import '../entities/friend_profile.dart';

enum FriendAction { send, cancel, accept, reject, delete, block, unblock, none }

final class FriendRelationshipPresentation {
  const FriendRelationshipPresentation({
    required this.label,
    required this.action,
    required this.enabled,
    required this.description,
  });

  final String label;
  final FriendAction action;
  final bool enabled;
  final String description;
}

abstract final class FriendRelationshipPolicy {
  static const minimumQueryLength = 2;

  static String normalizeQuery(String value) => value.trim().toLowerCase();

  static String? validateQuery(String value) {
    final normalized = normalizeQuery(value);
    if (normalized.isEmpty) return '검색어를 입력해 주세요.';
    if (normalized.length < minimumQueryLength) return '두 글자 이상 입력해 주세요.';
    return null;
  }

  static ({String low, String high}) canonicalPair(
    String first,
    String second,
  ) {
    if (first == second) {
      throw const FriendPolicyException('본인에게 친구 요청을 보낼 수 없습니다.');
    }
    return first.compareTo(second) < 0
        ? (low: first, high: second)
        : (low: second, high: first);
  }

  static bool canTransition(FriendRequestStatus from, FriendRequestStatus to) {
    return switch (from) {
      FriendRequestStatus.pending =>
        to == FriendRequestStatus.accepted ||
            to == FriendRequestStatus.rejected ||
            to == FriendRequestStatus.cancelled ||
            to == FriendRequestStatus.expired,
      FriendRequestStatus.rejected ||
      FriendRequestStatus.expired ||
      FriendRequestStatus.cancelled => to == FriendRequestStatus.pending,
      FriendRequestStatus.accepted => false,
    };
  }

  static FriendRelationshipPresentation presentation(
    FriendRelationshipState state,
  ) {
    return switch (state) {
      FriendRelationshipState.none => const FriendRelationshipPresentation(
        label: '친구 요청',
        action: FriendAction.send,
        enabled: true,
        description: '친구 요청을 보낼 수 있어요.',
      ),
      FriendRelationshipState.outgoingPending =>
        const FriendRelationshipPresentation(
          label: '요청 보냄',
          action: FriendAction.cancel,
          enabled: true,
          description: '상대방의 수락을 기다리고 있어요.',
        ),
      FriendRelationshipState.incomingPending =>
        const FriendRelationshipPresentation(
          label: '요청 수락',
          action: FriendAction.accept,
          enabled: true,
          description: '상대방이 친구 요청을 보냈어요.',
        ),
      FriendRelationshipState.accepted => const FriendRelationshipPresentation(
        label: '친구',
        action: FriendAction.none,
        enabled: false,
        description: '이미 친구예요.',
      ),
      FriendRelationshipState.self => const FriendRelationshipPresentation(
        label: '본인',
        action: FriendAction.none,
        enabled: false,
        description: '내 프로필이에요.',
      ),
      FriendRelationshipState.blockedByMe =>
        const FriendRelationshipPresentation(
          label: '차단됨',
          action: FriendAction.unblock,
          enabled: true,
          description: '내가 차단한 사용자예요.',
        ),
      FriendRelationshipState.blockedMe => const FriendRelationshipPresentation(
        label: '이용 불가',
        action: FriendAction.none,
        enabled: false,
        description: '친구 요청을 보낼 수 없어요.',
      ),
      FriendRelationshipState.rejected ||
      FriendRelationshipState.expired ||
      FriendRelationshipState.cancelled => const FriendRelationshipPresentation(
        label: '다시 요청',
        action: FriendAction.send,
        enabled: true,
        description: '새 친구 요청을 보낼 수 있어요.',
      ),
      FriendRelationshipState.unavailable =>
        const FriendRelationshipPresentation(
          label: '이용 불가',
          action: FriendAction.none,
          enabled: false,
          description: '비활성 사용자예요.',
        ),
    };
  }
}

final class FriendPolicyException implements Exception {
  const FriendPolicyException(this.message);
  final String message;
}
