import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/study_material.dart';

class RecentStudyRecord {
  const RecentStudyRecord({
    required this.title,
    required this.subtitle,
    required this.scoreLabel,
  });

  final String title;
  final String subtitle;
  final String scoreLabel;
}

class LibraryDashboard {
  const LibraryDashboard({
    required this.todayReviewCount,
    required this.totalMemoryPercent,
    required this.materials,
    required this.recentRecords,
  });

  final int todayReviewCount;
  final int totalMemoryPercent;
  final List<StudyMaterial> materials;
  final List<RecentStudyRecord> recentRecords;
}

final useEmptyLibraryMockProvider = Provider<bool>((ref) => false);

final libraryDashboardProvider = Provider<LibraryDashboard>((ref) {
  if (ref.watch(useEmptyLibraryMockProvider)) {
    return const LibraryDashboard(
      todayReviewCount: 0,
      totalMemoryPercent: 0,
      materials: [],
      recentRecords: [],
    );
  }

  return const LibraryDashboard(
    todayReviewCount: 12,
    totalMemoryPercent: 68,
    materials: [
      StudyMaterial(
        id: 'mock-biology',
        title: 'Biology Chapter 3.pdf',
        sectionCount: 6,
        progressPercent: 42,
        memoryPercent: 71,
        nextReviewLabel: 'Today',
      ),
      StudyMaterial(
        id: 'mock-history',
        title: 'Korean History Notes',
        sectionCount: 4,
        progressPercent: 65,
        memoryPercent: 58,
        nextReviewLabel: 'Tomorrow',
      ),
    ],
    recentRecords: [
      RecentStudyRecord(
        title: 'Cell respiration',
        subtitle: 'Biology Chapter 3.pdf',
        scoreLabel: '8/10 correct',
      ),
      RecentStudyRecord(
        title: 'Joseon reforms',
        subtitle: 'Korean History Notes',
        scoreLabel: '6/8 correct',
      ),
    ],
  );
});