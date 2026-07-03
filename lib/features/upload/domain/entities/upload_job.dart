import 'dart:typed_data';

enum UploadSourceType {
  pdf,
  image,
  camera,
  text,
}

class UploadJob {
  const UploadJob({
    required this.id,
    required this.sourceType,
    required this.displayName,
    required this.sizeBytes,
    this.path,
    this.bytes,
    this.textContent,
  });

  final String id;
  final UploadSourceType sourceType;
  final String displayName;
  final int sizeBytes;
  final String? path;
  final Uint8List? bytes;
  final String? textContent;

  String get sizeLabel {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}