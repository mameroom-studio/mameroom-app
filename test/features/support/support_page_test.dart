import 'package:ai_memory_coach/features/support/data/support_repository.dart';
import 'package:ai_memory_coach/features/support/domain/support_inquiry.dart';
import 'package:ai_memory_coach/features/support/presentation/support_page.dart';
import 'package:ai_memory_coach/features/support/presentation/support_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements SupportRepository {
  @override
  Future<List<SupportInquiry>> loadMine() async => const [];
  @override
  Future<SupportInquiry?> loadMineById(String id) async => null;
  @override
  Future<CreateSupportResultCode> create({
    required SupportCategory category,
    required String title,
    required String content,
    required SupportEnvironment environment,
    String? relatedMaterialId,
  }) async => CreateSupportResultCode.success;
}

void main() {
  test('support category and status contracts are stable', () {
    expect(
      SupportCategory.values.map((e) => e.code),
      containsAll(<String>[
        'MATERIAL_ANALYSIS',
        'QUIZ_STUDY',
        'PAYMENT_QUOTA',
        'ACCOUNT_PROFILE',
        'FRIEND_NOTIFICATION',
        'BUG_REPORT',
        'SUGGESTION_OTHER',
      ]),
    );
    expect(SupportStatus.values.map((e) => e.code), <String>[
      'RECEIVED',
      'IN_REVIEW',
      'ANSWERED',
      'CLOSED',
    ]);
  });

  testWidgets('support form exposes text-only notice and validates input', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(home: SupportPage()),
      ),
    );
    expect(find.textContaining('파일 첨부는 지원하지 않습니다.'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -350));
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('support-submit')), findsOneWidget);
  });
}
