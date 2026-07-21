import 'package:ai_memory_coach/features/notifications/domain/mameroom_notification.dart';
import 'package:ai_memory_coach/features/notifications/presentation/pages/mameroom_notification_page.dart';
import 'package:ai_memory_coach/features/notifications/presentation/pages/mameroom_notification_settings_page.dart';
import 'package:ai_memory_coach/features/notifications/presentation/providers/notification_providers.dart';
import 'package:ai_memory_coach/features/notifications/presentation/widgets/mameroom_notification_badge.dart';
import 'package:ai_memory_coach/features/notifications/presentation/widgets/mameroom_notification_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeNotificationController extends MameroomNotificationController {
  _FakeNotificationController(MameroomNotificationState initialState)
    : super(initialState: initialState);
}

Widget _wrap({
  MameroomNotificationState? state,
  Widget? home,
  GoRouter? router,
}) {
  final child = router == null
      ? MaterialApp(home: home ?? const MameroomNotificationPage())
      : MaterialApp.router(routerConfig: router);
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      if (state != null)
        mameroomNotificationControllerProvider.overrideWith(
          (ref) => _FakeNotificationController(state),
        ),
    ],
    child: child,
  );
}

void main() {
  testWidgets('notification page renders list and default all filter', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('알림'), findsWidgets);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('기억씨앗이 성장했어요!'), findsOneWidget);
    expect(find.text('오늘 복습할 문제가 있어요'), findsOneWidget);
  });

  testWidgets('category filters show unread/read states', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('읽지 않음'));
    await tester.pumpAndSettle();

    expect(find.text('민지님이 공부를 완료했어요'), findsNothing);
    expect(find.text('오늘 복습할 문제가 있어요'), findsOneWidget);
    expect(find.text('코인 50개를 획득했어요'), findsOneWidget);
  });

  testWidgets('mark all read callback clears unread filter', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('모든 알림 읽기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('읽지 않음'));
    await tester.pumpAndSettle();

    expect(find.text('새로운 알림이 없어요'), findsOneWidget);
  });

  testWidgets('badge hides zero and shows 99 plus', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            MameroomNotificationBadge(count: 0),
            MameroomNotificationBadge(count: 120),
          ],
        ),
      ),
    );

    expect(find.text('99+'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('tap triggers review action resolver route', (tester) async {
    final router = GoRouter(
      initialLocation: MameroomNotificationPage.routePath,
      routes: [
        GoRoute(
          path: MameroomNotificationPage.routePath,
          builder: (context, state) => const MameroomNotificationPage(),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) =>
              const Scaffold(body: Text('Review Target')),
        ),
      ],
    );
    await tester.pumpWidget(_wrap(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('오늘 복습할 문제가 있어요'));
    await tester.pumpAndSettle();

    expect(find.text('Review Target'), findsOneWidget);
  });

  testWidgets('seed coin and diamond popups render with modal system', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => MameroomNotificationPopup.show(
                    context,
                    MameroomNotificationState.demo().notifications.first,
                  ),
                  child: const Text('seed'),
                ),
                TextButton(
                  onPressed: () => MameroomNotificationPopup.show(
                    context,
                    MameroomNotification(
                      id: 'coin-test',
                      type: MameroomNotificationType.coinReward,
                      title: 'coin',
                      message: '코인을 획득했어요',
                      createdAt: DateTime(2026, 7, 12),
                      rewardAmount: 50,
                    ),
                  ),
                  child: const Text('coin'),
                ),
                TextButton(
                  onPressed: () => MameroomNotificationPopup.show(
                    context,
                    MameroomNotification(
                      id: 'diamond-test',
                      type: MameroomNotificationType.diamondReward,
                      title: 'diamond',
                      message: '다이아를 획득했어요',
                      createdAt: DateTime(2026, 7, 12),
                      rewardAmount: 1,
                    ),
                  ),
                  child: const Text('diamond'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('seed'));
    await tester.pumpAndSettle();
    expect(find.text('성장했어요!'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('coin'));
    await tester.pumpAndSettle();
    expect(find.text('코인 획득!'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('diamond'));
    await tester.pumpAndSettle();
    expect(find.text('다이아 획득!'), findsOneWidget);
  });

  testWidgets('settings switches render', (tester) async {
    await tester.pumpWidget(
      _wrap(home: const MameroomNotificationSettingsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('알림 설정'), findsWidgets);
    expect(find.text('기억씨앗 성장'), findsOneWidget);
    expect(find.text('복습 알림'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);
  });

  testWidgets('empty loading error and retry states render', (tester) async {
    await tester.pumpWidget(
      _wrap(state: const MameroomNotificationState(notifications: [])),
    );
    await tester.pumpAndSettle();
    expect(find.text('새로운 알림이 없어요'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        state: const MameroomNotificationState(
          notifications: [],
          phase: MameroomNotificationPhase.loading,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('\uBD88\uB7EC\uC624\uB294 \uC911'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _wrap(
        state: const MameroomNotificationState(
          notifications: [],
          phase: MameroomNotificationPhase.error,
          errorMessage: 'network',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsWidgets);
  });

  testWidgets('long title does not overflow at 390x844', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        state: MameroomNotificationState(
          notifications: [
            MameroomNotification(
              id: 'long',
              type: MameroomNotificationType.reviewReminder,
              title: '아주 길고 긴 알림 제목이 들어와도 화면에서 넘치지 않고 한 줄로 정리됩니다',
              message: '긴 설명도 두 줄까지만 자연스럽게 보여줍니다.',
              createdAt: DateTime(2026, 7, 12, 9, 30),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('아주 길고 긴 알림 제목'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
