import '../../domain/entities/upload_job.dart';

class UploadJobModel extends UploadJob {
  const UploadJobModel({
    required super.id,
    required super.sourceType,
    required super.displayName,
    required super.sizeBytes,
    super.path,
    super.textContent,
  });

  factory UploadJobModel.fromJson(Map<String, dynamic> json) {
    return UploadJobModel(
      id: json['id'] as String,
      sourceType: UploadSourceType.values.byName(json['source_type'] as String),
      displayName: json['display_name'] as String,
      sizeBytes: json['size_bytes'] as int,
      path: json['path'] as String?,
      textContent: json['text_content'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_type': sourceType.name,
        'display_name': displayName,
        'size_bytes': sizeBytes,
        'path': path,
        'text_content': textContent,
      };
}