import 'package:ai_memory_coach/features/memory_engine/domain/entities/memory_engine_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('confirmed server result preserves authoritative schedule metadata', () {
    final reviewedAt = DateTime.utc(2026, 7, 21);
    final dueAt = reviewedAt.add(const Duration(days: 12));
    final result = MemoryEngineResult(
      submissionId: 'submission-1',
      reviewedAt: reviewedAt,
      scheduleChanged: true,
      duplicate: false,
      state: 'review',
      dueAt: dueAt,
      stability: 12.5,
      difficulty: 4.2,
      stateVersion: 3,
    );

    expect(result.dueAt, dueAt);
    expect(result.scheduleChanged, isTrue);
    expect(result.stateVersion, 3);
  });

  test('PASS-compatible result can be schedule-neutral', () {
    final result = MemoryEngineResult(
      submissionId: 'submission-pass',
      reviewedAt: DateTime.utc(2026, 7, 21),
      scheduleChanged: false,
      duplicate: false,
    );
    expect(result.scheduleChanged, isFalse);
    expect(result.dueAt, isNull);
  });
}
