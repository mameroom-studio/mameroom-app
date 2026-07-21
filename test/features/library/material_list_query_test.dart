import 'package:ai_memory_coach/features/library/domain/entities/material_list_query.dart';
import 'package:ai_memory_coach/features/library/domain/entities/study_material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final old = DateTime.utc(2026, 1, 1);
  final recent = DateTime.utc(2026, 6, 1);
  final materials = [
    _material('b', '  보험   수학 2  ', recent, old),
    _material('a', 'Actuary_Notes', old, recent),
    _material('c', '미학습 자료', recent, null),
  ];

  test('normalizes spaces and supports Korean title search', () {
    const query = MaterialListQuery(searchQuery: ' 보험  수학 ');
    expect(query.apply(materials).map((item) => item.id), ['b']);
  });

  test('matches English without case sensitivity and special characters', () {
    const query = MaterialListQuery(searchQuery: 'actuary_');
    expect(query.apply(materials).single.id, 'a');
  });

  test('recently studied puts null last and keeps a stable tie-breaker', () {
    const query = MaterialListQuery(
      sortOption: MaterialSortOption.recentlyStudied,
    );
    expect(query.apply(materials).map((item) => item.id), ['a', 'b', 'c']);
  });

  test('clear keeps sort and name ordering is deterministic', () {
    const selected = MaterialListQuery(
      searchQuery: '보험',
      sortOption: MaterialSortOption.name,
    );
    final cleared = selected.copyWith(searchQuery: '');
    expect(cleared.sortOption, MaterialSortOption.name);
    expect(cleared.apply(materials).map((item) => item.id), ['a', 'c', 'b']);
  });

  test('oldest and newest use upload date with id tie-breaker', () {
    const newest = MaterialListQuery();
    const oldest = MaterialListQuery(sortOption: MaterialSortOption.oldest);
    expect(newest.apply(materials).map((item) => item.id), ['b', 'c', 'a']);
    expect(oldest.apply(materials).map((item) => item.id), ['a', 'b', 'c']);
  });
}

StudyMaterial _material(
  String id,
  String title,
  DateTime uploadedAt,
  DateTime? lastStudiedAt,
) {
  return StudyMaterial(
    id: id,
    title: title,
    sectionCount: 0,
    progressPercent: 0,
    memoryPercent: 0,
    nextReviewLabel: '',
    status: 'completed',
    uploadedAt: uploadedAt,
    lastStudiedAt: lastStudiedAt,
  );
}
