import 'study_material.dart';

enum MaterialSortOption { newest, recentlyStudied, name, oldest }

class MaterialListQuery {
  const MaterialListQuery({
    this.searchQuery = '',
    this.sortOption = MaterialSortOption.newest,
  });

  final String searchQuery;
  final MaterialSortOption sortOption;

  String get normalizedQuery =>
      searchQuery.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  MaterialListQuery copyWith({
    String? searchQuery,
    MaterialSortOption? sortOption,
  }) => MaterialListQuery(
    searchQuery: searchQuery ?? this.searchQuery,
    sortOption: sortOption ?? this.sortOption,
  );

  List<StudyMaterial> apply(Iterable<StudyMaterial> source) {
    final query = normalizedQuery;
    final result = source
        .where(
          (material) =>
              query.isEmpty ||
              material.title
                  .trim()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    result.sort(_compare);
    return result;
  }

  int _compare(StudyMaterial a, StudyMaterial b) {
    final value = switch (sortOption) {
      MaterialSortOption.newest => _dateDescending(a.uploadedAt, b.uploadedAt),
      MaterialSortOption.recentlyStudied => _dateDescendingNullLast(
        a.lastStudiedAt,
        b.lastStudiedAt,
      ),
      MaterialSortOption.name => _normalizedTitle(
        a,
      ).compareTo(_normalizedTitle(b)),
      MaterialSortOption.oldest => _dateAscending(a.uploadedAt, b.uploadedAt),
    };
    if (value != 0) return value;
    final uploadedTie = _dateDescending(a.uploadedAt, b.uploadedAt);
    return uploadedTie != 0 ? uploadedTie : a.id.compareTo(b.id);
  }

  String _normalizedTitle(StudyMaterial value) =>
      value.title.trim().replaceAll(RegExp(r'\\s+'), ' ').toLowerCase();

  DateTime get _epoch => DateTime.fromMillisecondsSinceEpoch(0);
  int _dateDescending(DateTime? a, DateTime? b) =>
      (b ?? _epoch).compareTo(a ?? _epoch);
  int _dateAscending(DateTime? a, DateTime? b) =>
      (a ?? _epoch).compareTo(b ?? _epoch);
  int _dateDescendingNullLast(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
