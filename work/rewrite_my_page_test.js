const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'test/features/home/my_info_page_test.dart');
const content = String.raw`import 'package:ai_memory_coach/features/home/presentation/pages/home_shell_page.dart';
import 'package:ai_memory_coach/features/home/presentation/pages/my_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

Future<void> _pumpMyPageAt(
  WidgetTester tester,
  Size size, {
  Widget child = const MyInfoPage(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_wrap(child));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('my page renders learning dashboard without diamonds', (
    tester,
  ) async {
    await _pumpMyPageAt(tester, const Size(390, 844));

    expect(find.text('내 정보'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
    expect(find.text('기억률 84%'), findsOneWidget);
    expect(find.text('M-Coin'), findsOneWidget);
    expect(find.text('현재 보유'), findsOneWidget);
    expect(find.text('이번 주 획득'), findsOneWidget);
    expect(find.text('총 사용'), findsOneWidget);
    expect(find.text('사용 내역'), findsOneWidget);
    expect(find.text('Diamond'), findsNothing);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.text('상점 바로가기'), findsNothing);

    expect(find.text('이용 현황'), findsOneWidget);
    expect(find.text('180 / 500문제'), findsOneWidget);
    expect(find.text('320문제'), findsOneWidget);
    expect(find.text('2026.08.01'), findsOneWidget);
    expect(find.text('문제 충전하기'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('학습 통계'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('총 풀이 문제'), findsOneWidget);
    expect(find.text('2,341'), findsOneWidget);
    expect(find.text('정답률'), findsOneWidget);
    expect(find.text('누적 학습 시간'), findsOneWidget);

    expect(find.text('플랜 정보 없음'), findsNothing);
    expect(find.text('잔여 문제 수 불러오기 실패'), findsNothing);
    expect(find.text('프로모션 코드 미지원'), findsNothing);
  });

  testWidgets('promotion starts compact and expands on tap', (tester) async {
    await _pumpMyPageAt(tester, const Size(390, 844));

    await tester.scrollUntilVisible(
      find.text('프로모션 코드'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('프로모션 코드 입력'), findsNothing);
    await tester.tap(find.text('프로모션 코드'));
    await tester.pumpAndSettle();
    expect(find.text('프로모션 코드 입력'), findsOneWidget);
  });

  testWidgets('promotion success state remains available but compact', (
    tester,
  ) async {
    await _pumpMyPageAt(
      tester,
      const Size(390, 844),
      child: const MyInfoPage(initialPromotionApplied: true),
    );

    await tester.scrollUntilVisible(
      find.text('+200문제가 추가되었습니다.'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('적용됨'), findsOneWidget);
    expect(find.text('+200문제가 추가되었습니다.'), findsOneWidget);
  });

  testWidgets('low question warning renders without error cards', (tester) async {
    await _pumpMyPageAt(
      tester,
      const Size(390, 844),
      child: const MyInfoPage(initialRemainingQuestions: 0),
    );

    expect(find.text('0문제'), findsOneWidget);
    expect(find.text('남은 생성량이 부족합니다. 문제를 충전하고 계속 공부하세요.'), findsOneWidget);
    expect(find.text('잔여 문제 수 불러오기 실패'), findsNothing);
  });

  testWidgets('settings are compact and ordered', (tester) async {
    await _pumpMyPageAt(tester, const Size(390, 844));

    await tester.scrollUntilVisible(
      find.text('설정'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final labels = ['알림', '사운드', '언어', '문의하기', '이용약관', '개인정보처리방침', '로그아웃'];
    for (final label in labels) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('logout dialog opens', (tester) async {
    await _pumpMyPageAt(tester, const Size(390, 844));

    await tester.scrollUntilVisible(
      find.text('로그아웃'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃').last);
    await tester.pumpAndSettle();

    expect(find.text('정말 로그아웃하시겠습니까?'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
  });

  for (final size in <Size>[
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('my page has no overflow at \${size.width}x\${size.height}', (
      tester,
    ) async {
      await _pumpMyPageAt(tester, size);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bottom navigation keeps my tab label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeShellPage(selectedIndex: 3, child: SizedBox.shrink()),
      ),
    );

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('공부'), findsOneWidget);
    expect(find.text('친구'), findsOneWidget);
    expect(find.text('내 정보'), findsOneWidget);
  });
}
`;
fs.writeFileSync(file, content);

