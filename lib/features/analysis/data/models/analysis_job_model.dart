import '../../domain/entities/analysis_job.dart';

class AnalysisJobModel extends AnalysisJob {
  const AnalysisJobModel({required super.id});

  factory AnalysisJobModel.fromJson(Map<String, dynamic> json) {
    return AnalysisJobModel(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id};
}