import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/mameroom_notification.dart';

enum MameroomNotificationPhase { data, loading, error }

@immutable
class MameroomNotificationSettings {
  const MameroomNotificationSettings({
    this.seedGrowth = true,
    this.reviewReminder = true,
    this.levelUp = true,
    this.friendActivity = true,
    this.reward = true,
    this.notice = true,
    this.quietStart = '오전 8:00',
    this.quietEnd = '오후 10:00',
    this.weekendMode = false,
  });

  final bool seedGrowth;
  final bool reviewReminder;
  final bool levelUp;
  final bool friendActivity;
  final bool reward;
  final bool notice;
  final String quietStart;
  final String quietEnd;
  final bool weekendMode;

  MameroomNotificationSettings copyWith({
    bool? seedGrowth,
    bool? reviewReminder,
    bool? levelUp,
    bool? friendActivity,
    bool? reward,
    bool? notice,
    String? quietStart,
    String? quietEnd,
    bool? weekendMode,
  }) {
    return MameroomNotificationSettings(
      seedGrowth: seedGrowth ?? this.seedGrowth,
      reviewReminder: reviewReminder ?? this.reviewReminder,
      levelUp: levelUp ?? this.levelUp,
      friendActivity: friendActivity ?? this.friendActivity,
      reward: reward ?? this.reward,
      notice: notice ?? this.notice,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
      weekendMode: weekendMode ?? this.weekendMode,
    );
  }
}

@immutable
class MameroomNotificationState {
  const MameroomNotificationState({
    required this.notifications,
    this.selectedCategory = MameroomNotificationCategory.all,
    this.phase = MameroomNotificationPhase.data,
    this.errorMessage,
    this.settings = const MameroomNotificationSettings(),
  });

  final List<MameroomNotification> notifications;
  final MameroomNotificationCategory selectedCategory;
  final MameroomNotificationPhase phase;
  final String? errorMessage;
  final MameroomNotificationSettings settings;

  bool get isLoading => phase == MameroomNotificationPhase.loading;
  bool get hasError => phase == MameroomNotificationPhase.error;
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<MameroomNotification> get visibleNotifications {
    return switch (selectedCategory) {
      MameroomNotificationCategory.all => notifications,
      MameroomNotificationCategory.unread =>
        notifications.where((n) => !n.isRead).toList(),
      _ =>
        notifications
            .where((n) => n.type.category == selectedCategory)
            .toList(),
    };
  }

  MameroomNotificationState copyWith({
    List<MameroomNotification>? notifications,
    MameroomNotificationCategory? selectedCategory,
    MameroomNotificationPhase? phase,
    String? errorMessage,
    MameroomNotificationSettings? settings,
  }) {
    return MameroomNotificationState(
      notifications: notifications ?? this.notifications,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      phase: phase ?? this.phase,
      errorMessage: errorMessage ?? this.errorMessage,
      settings: settings ?? this.settings,
    );
  }

  factory MameroomNotificationState.demo() {
    final now = DateTime(2026, 7, 12, 9, 41);
    return MameroomNotificationState(
      notifications: [
        MameroomNotification(
          id: 'seed-growth',
          type: MameroomNotificationType.seedGrowth,
          title: '기억씨앗이 성장했어요!',
          message: '새싹이 한 단계 성장했어요. 새로운 모습 확인하기',
          createdAt: now.subtract(const Duration(minutes: 1)),
          actionLabel: '확인',
          actionType: MameroomNotificationActionType.openSeed,
        ),
        MameroomNotification(
          id: 'review-reminder',
          type: MameroomNotificationType.reviewReminder,
          title: '오늘 복습할 문제가 있어요',
          message: '10문제의 복습이 기다리고 있어요',
          createdAt: now.subtract(const Duration(minutes: 15)),
          actionLabel: '복습하기',
          actionType: MameroomNotificationActionType.openReview,
        ),
        MameroomNotification(
          id: 'level-up',
          type: MameroomNotificationType.levelUp,
          title: 'Lv.20을 달성했어요!',
          message: '축하합니다! 새로운 보상을 확인하세요',
          createdAt: now.subtract(const Duration(hours: 1)),
          rewardAmount: 100,
          actionLabel: '보상 보기',
          actionType: MameroomNotificationActionType.claimReward,
        ),
        MameroomNotification(
          id: 'friend-activity',
          type: MameroomNotificationType.friendActivity,
          title: '민지님이 공부를 완료했어요',
          message: '함께 응원하고 코인을 보내보세요!',
          createdAt: now.subtract(const Duration(hours: 2)),
          isRead: true,
          actionLabel: '보러가기',
          actionType: MameroomNotificationActionType.openFriends,
        ),
        MameroomNotification(
          id: 'coin',
          type: MameroomNotificationType.coinReward,
          title: '코인 50개를 획득했어요',
          message: '출석 보상으로 코인을 받았어요',
          createdAt: now.subtract(const Duration(hours: 3)),
          rewardAmount: 50,
          actionLabel: '보상 받기',
          actionType: MameroomNotificationActionType.claimReward,
        ),
        MameroomNotification(
          id: 'event',
          type: MameroomNotificationType.event,
          title: '이벤트 보상이 도착했어요',
          message: '주간 이벤트 보상을 확인하세요',
          createdAt: now.subtract(const Duration(days: 1)),
          isRead: true,
          actionLabel: '이벤트 보기',
          actionType: MameroomNotificationActionType.openNotice,
        ),
      ],
    );
  }
}

final mameroomNotificationControllerProvider =
    StateNotifierProvider<
      MameroomNotificationController,
      MameroomNotificationState
    >((ref) {
      return MameroomNotificationController();
    });

final mameroomUnreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(mameroomNotificationControllerProvider).unreadCount;
});

class MameroomNotificationController
    extends StateNotifier<MameroomNotificationState> {
  MameroomNotificationController({MameroomNotificationState? initialState})
    : super(initialState ?? MameroomNotificationState.demo());

  void selectCategory(MameroomNotificationCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  void markRead(String id) {
    state = state.copyWith(
      notifications: [
        for (final n in state.notifications)
          n.id == id ? n.copyWith(isRead: true) : n,
      ],
    );
  }

  void markAllRead() {
    state = state.copyWith(
      notifications: [
        for (final n in state.notifications) n.copyWith(isRead: true),
      ],
    );
  }

  void retry() {
    state = MameroomNotificationState.demo().copyWith(
      selectedCategory: state.selectedCategory,
      settings: state.settings,
    );
  }

  void toggleSeedGrowth(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(seedGrowth: value),
    );
  }

  void toggleReviewReminder(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(reviewReminder: value),
    );
  }

  void toggleLevelUp(bool value) {
    state = state.copyWith(settings: state.settings.copyWith(levelUp: value));
  }

  void toggleFriendActivity(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(friendActivity: value),
    );
  }

  void toggleReward(bool value) {
    state = state.copyWith(settings: state.settings.copyWith(reward: value));
  }

  void toggleNotice(bool value) {
    state = state.copyWith(settings: state.settings.copyWith(notice: value));
  }

  void toggleWeekendMode(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(weekendMode: value),
    );
  }
}
