import 'package:ai_memory_coach/features/friends/domain/entities/friend_profile.dart';
import 'package:ai_memory_coach/features/friends/domain/policies/friend_relationship_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FriendRelationshipPolicy', () {
    test('normalizes and validates search queries', () {
      expect(FriendRelationshipPolicy.normalizeQuery('  YuI  '), 'yui');
      expect(FriendRelationshipPolicy.validateQuery(''), isNotNull);
      expect(FriendRelationshipPolicy.validateQuery('a'), isNotNull);
      expect(FriendRelationshipPolicy.validateQuery('ab'), isNull);
    });

    test('creates an order-independent canonical pair', () {
      expect(FriendRelationshipPolicy.canonicalPair('b', 'a'), (
        low: 'a',
        high: 'b',
      ));
      expect(
        () => FriendRelationshipPolicy.canonicalPair('a', 'a'),
        throwsA(isA<FriendPolicyException>()),
      );
    });

    test('allows only documented request transitions', () {
      expect(
        FriendRelationshipPolicy.canTransition(
          FriendRequestStatus.pending,
          FriendRequestStatus.accepted,
        ),
        isTrue,
      );
      expect(
        FriendRelationshipPolicy.canTransition(
          FriendRequestStatus.accepted,
          FriendRequestStatus.pending,
        ),
        isFalse,
      );
      expect(
        FriendRelationshipPolicy.canTransition(
          FriendRequestStatus.expired,
          FriendRequestStatus.pending,
        ),
        isTrue,
      );
    });

    test('maps every relationship state to one presentation', () {
      for (final state in FriendRelationshipState.values) {
        final presentation = FriendRelationshipPolicy.presentation(state);
        expect(presentation.label, isNotEmpty);
        expect(presentation.description, isNotEmpty);
      }
      expect(
        FriendRelationshipPolicy.presentation(
          FriendRelationshipState.blockedMe,
        ).enabled,
        isFalse,
      );
    });

    test('room visits require accepted relation and visible room', () {
      const visible = FriendProfile(
        id: 'a',
        nickname: 'friend',
        friendCode: 'F1',
        level: 1,
        statusMessage: '',
        relationship: FriendRelationshipState.accepted,
        roomVisibility: FriendRoomVisibility.friends,
      );
      expect(visible.canVisitRoom, isTrue);
      expect(
        visible
            .copyWith(relationship: FriendRelationshipState.blockedByMe)
            .canVisitRoom,
        isFalse,
      );
    });
  });
}
