import '../../domain/entities/study_material.dart';

class StudyMaterialModel extends StudyMaterial {
  const StudyMaterialModel({
    required super.id,
    required super.title,
    required super.sectionCount,
    required super.progressPercent,
    required super.memoryPercent,
    required super.nextReviewLabel,
  });

  factory StudyMaterialModel.fromJson(Map<String, dynamic> json) {
    return StudyMaterialModel(
      id: json['id'] as String,
      title: json['title'] as String,
      sectionCount: json['section_count'] as int,
      progressPercent: json['progress_percent'] as int,
      memoryPercent: json['memory_percent'] as int,
      nextReviewLabel: json['next_review_label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'section_count': sectionCount,
        'progress_percent': progressPercent,
        'memory_percent': memoryPercent,
        'next_review_label': nextReviewLabel,
      };
}