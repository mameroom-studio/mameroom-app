import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../../shared/supabase/storage_buckets.dart';
import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/upload_job.dart';
import '../../domain/entities/upload_result.dart';
import 'local_file_bytes_reader.dart';

class UploadRemoteDataSource {
  const UploadRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const int _minimumPdfTextLength = 300;

  Future<UploadResult> createMaterialFromDraft(UploadJob job) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to upload materials.');
    }

    final materialId = _newUuidV4();
    final fileHash = await _hashFor(job);
    final extractedText = await _extractPdfTextIfPossible(job);
    final storagePath = await _uploadOriginalFileIfNeeded(
      userId: user.id,
      materialId: materialId,
      job: job,
    );

    final insertStopwatch = Stopwatch()..start();
    _logUploadStop(
      'STOP-13 study_material.insert.start',
      job: job,
      materialId: materialId,
      rawTextLength: extractedText?.rawText.length,
      structuredTextLength: extractedText?.structuredText.length,
      elapsedMs: 0,
    );
    try {
      await _client.from(SupabaseTables.studyMaterials).insert({
        'id': materialId,
        'user_id': user.id,
        'title': job.displayName,
        'source_type': _sourceTypeValue(job.sourceType),
        'file_hash': fileHash,
        'storage_path': storagePath,
        'raw_text': extractedText?.rawText ??
            (job.sourceType == UploadSourceType.text ? job.textContent : null),
        'structured_text': extractedText?.structuredText,
        'status': 'uploaded',
      });
      _logUploadStop(
        'STOP-14 study_material.insert.success',
        job: job,
        materialId: materialId,
        rawTextLength: extractedText?.rawText.length,
        structuredTextLength: extractedText?.structuredText.length,
        elapsedMs: insertStopwatch.elapsedMilliseconds,
      );
    } catch (error, stackTrace) {
      _logUploadStop(
        'STOP-13 study_material.insert.start',
        job: job,
        materialId: materialId,
        rawTextLength: extractedText?.rawText.length,
        structuredTextLength: extractedText?.structuredText.length,
        elapsedMs: insertStopwatch.elapsedMilliseconds,
        exception: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    return UploadResult(
      materialId: materialId,
      storagePath: storagePath,
      fileHash: fileHash,
    );
  }

  Future<String?> _uploadOriginalFileIfNeeded({
    required String userId,
    required String materialId,
    required UploadJob job,
  }) async {
    if (job.sourceType == UploadSourceType.text) {
      return null;
    }

    final fileBytes = await _bytesFor(job);
    final storagePath = [
      userId,
      materialId,
      _storageObjectFileName(materialId, job),
    ].join('/');

    final uploadStopwatch = Stopwatch()..start();
    _logUploadStop(
      'STOP-11 storage.upload.start',
      job: job,
      materialId: materialId,
      bytesLength: fileBytes.length,
      elapsedMs: 0,
    );
    try {
      await _client.storage.from(StorageBuckets.materials).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _contentTypeFor(job),
            ),
          );
      _logUploadStop(
        'STOP-12 storage.upload.success',
        job: job,
        materialId: materialId,
        bytesLength: fileBytes.length,
        elapsedMs: uploadStopwatch.elapsedMilliseconds,
      );
    } catch (error, stackTrace) {
      _logUploadStop(
        'STOP-11 storage.upload.start',
        job: job,
        materialId: materialId,
        bytesLength: fileBytes.length,
        elapsedMs: uploadStopwatch.elapsedMilliseconds,
        exception: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    return storagePath;
  }

  Future<String> _hashFor(UploadJob job) async {
    if (job.sourceType == UploadSourceType.text) {
      return sha256.convert(utf8.encode(job.textContent ?? '')).toString();
    }

    final fileBytes = await _bytesFor(job);
    return sha256.convert(fileBytes).toString();
  }

  Future<Uint8List> _bytesFor(UploadJob job) async {
    final stopwatch = Stopwatch()..start();
    _logUploadStop(
      'STOP-02 file.bytes.read.start',
      job: job,
      elapsedMs: 0,
    );
    try {
      final bytes = job.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        _logUploadStop(
          'STOP-03 file.bytes.read.success',
          job: job,
          bytesLength: bytes.length,
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
        return bytes;
      }

      final path = job.path;
      if (path != null && path.isNotEmpty) {
        final fileBytes = await readLocalFileBytes(path);
        _logUploadStop(
          'STOP-03 file.bytes.read.success',
          job: job,
          bytesLength: fileBytes.length,
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
        return fileBytes;
      }

      throw StateError('Selected file bytes are unavailable. Please select the file again.');
    } catch (error, stackTrace) {
      _logUploadStop(
        'STOP-02 file.bytes.read.start',
        job: job,
        elapsedMs: stopwatch.elapsedMilliseconds,
        exception: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<_ExtractedPdfText?> _extractPdfTextIfPossible(UploadJob job) async {
    if (job.sourceType != UploadSourceType.pdf) {
      return null;
    }

    _logUploadStop(
      'STOP-04 pdf.extract.start',
      job: job,
      extractorName: 'syncfusion_flutter_pdf',
      elapsedMs: 0,
    );
    if (kIsWeb) {
      // Syncfusion text extraction is synchronous and can freeze Flutter Web's UI thread.
      _logUploadStop(
        'STOP-04 pdf.extract.start',
        job: job,
        extractorName: 'syncfusion_flutter_pdf',
        elapsedMs: 0,
        exceptionMessage: 'skipped on Flutter Web to avoid synchronous UI-thread freeze',
      );
      return null;
    }

    try {
      final fileBytes = await _bytesFor(job);
      final documentStopwatch = Stopwatch()..start();
      _logUploadStop(
        'STOP-05 pdf.document.create.start',
        job: job,
        bytesLength: fileBytes.length,
        extractorName: 'syncfusion_flutter_pdf_isolate',
        elapsedMs: 0,
      );
      _logUploadStop(
        'STOP-07 pdf.text.extract.start',
        job: job,
        bytesLength: fileBytes.length,
        extractorName: 'syncfusion_flutter_pdf_isolate',
        elapsedMs: 0,
      );

      late final Map<String, Object?> extraction;
      try {
        extraction = await compute(_extractPdfTextFromBytesInBackground, fileBytes)
            .timeout(const Duration(seconds: 45));
      } catch (error, stackTrace) {
        _logUploadStop(
          'STOP-07 pdf.text.extract.start',
          job: job,
          bytesLength: fileBytes.length,
          extractorName: 'syncfusion_flutter_pdf_isolate',
          elapsedMs: documentStopwatch.elapsedMilliseconds,
          exception: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }

      final text = extraction['text'] as String? ?? '';
      final documentMs = extraction['documentMs'] as int? ?? documentStopwatch.elapsedMilliseconds;
      final textMs = extraction['textMs'] as int? ?? documentStopwatch.elapsedMilliseconds;
      _logUploadStop(
        'STOP-06 pdf.document.create.success',
        job: job,
        bytesLength: fileBytes.length,
        extractorName: 'syncfusion_flutter_pdf_isolate',
        elapsedMs: documentMs,
      );
      _logUploadStop(
        'STOP-08 pdf.text.extract.success',
        job: job,
        bytesLength: fileBytes.length,
        rawTextLength: text.length,
        extractorName: 'syncfusion_flutter_pdf_isolate',
        elapsedMs: textMs,
      );

      if (text.length < _minimumPdfTextLength) {
        return null;
      }

      final structuredStopwatch = Stopwatch()..start();
      _logUploadStop(
        'STOP-09 structured_text.build.start',
        job: job,
        rawTextLength: text.length,
        extractorName: 'syncfusion_flutter_pdf_isolate',
        elapsedMs: 0,
      );
      try {
        final structuredText = _structuredTextForPdf(
          title: job.displayName,
          text: text,
        );
        _logUploadStop(
          'STOP-10 structured_text.build.success',
          job: job,
          rawTextLength: text.length,
          structuredTextLength: structuredText.length,
          extractorName: 'syncfusion_flutter_pdf_isolate',
          elapsedMs: structuredStopwatch.elapsedMilliseconds,
        );
        return _ExtractedPdfText(
          rawText: text,
          structuredText: structuredText,
        );
      } catch (error, stackTrace) {
        _logUploadStop(
          'STOP-09 structured_text.build.start',
          job: job,
          rawTextLength: text.length,
          extractorName: 'syncfusion_flutter_pdf_isolate',
          elapsedMs: structuredStopwatch.elapsedMilliseconds,
          exception: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    } catch (error, stackTrace) {
      _logUploadStop(
        'STOP-04 pdf.extract.start',
        job: job,
        extractorName: 'syncfusion_flutter_pdf',
        exception: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _structuredTextForPdf({
    required String title,
    required String text,
  }) {
    return 'Title: $title\nSource type: pdf\n\n[Page 1]\n$text';
  }
void _logUploadStop(
    String stopPoint, {
    required UploadJob job,
    String? materialId,
    int? bytesLength,
    int? rawTextLength,
    int? structuredTextLength,
    String? extractorName,
    int? elapsedMs,
    Object? exception,
    String? exceptionMessage,
    StackTrace? stackTrace,
  }) {
    final payload = jsonEncode({
      'stopPoint': stopPoint,
      'materialId': materialId,
      'materialTitle': job.displayName,
      'fileExtension': _extensionFor(job.displayName),
      'fileSize': job.sizeBytes,
      'bytesLength': bytesLength,
      'elapsedMs': elapsedMs,
      'rawTextLength': rawTextLength,
      'structuredTextLength': structuredTextLength,
      'extractorName': extractorName,
      'isFlutterWeb': kIsWeb,
      'exceptionMessage': exceptionMessage ?? exception?.toString(),
      'stackTrace': stackTrace?.toString(),

    });

    debugPrint('[upload-flow] $payload');
  }

  String _extensionFor(String name) {
    final parts = name.toLowerCase().split('.');
    return parts.length < 2 ? '' : parts.last;
  }

  String _sourceTypeValue(UploadSourceType sourceType) {
    return switch (sourceType) {
      UploadSourceType.pdf => 'pdf',
      UploadSourceType.image => 'image',
      UploadSourceType.camera => 'camera',
      UploadSourceType.text => 'text',
    };
  }

  String _contentTypeFor(UploadJob job) {
    final name = job.displayName.toLowerCase();
    if (job.sourceType == UploadSourceType.pdf || name.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (name.endsWith('.png')) {
      return 'image/png';
    }
    if (name.endsWith('.webp')) {
      return 'image/webp';
    }
    if (name.endsWith('.heic')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  String _storageObjectFileName(String materialId, UploadJob job) {
    final extension = _safeExtensionFor(job);
    return extension.isEmpty ? materialId : '$materialId.$extension';
  }

  String _safeExtensionFor(UploadJob job) {
    final extension = job.displayName
        .trim()
        .toLowerCase()
        .split('.')
        .lastWhere((part) => part.isNotEmpty, orElse: () => '');

    if (RegExp(r'^[a-z0-9]+$').hasMatch(extension)) {
      return extension;
    }

    return switch (job.sourceType) {
      UploadSourceType.pdf => 'pdf',
      UploadSourceType.image || UploadSourceType.camera => 'jpg',
      UploadSourceType.text => '',
    };
  }

  String _newUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final chars = bytes.map(hex).join();
    return '${chars.substring(0, 8)}-'
        '${chars.substring(8, 12)}-'
        '${chars.substring(12, 16)}-'
        '${chars.substring(16, 20)}-'
        '${chars.substring(20)}';
  }
}

class _ExtractedPdfText {
  const _ExtractedPdfText({
    required this.rawText,
    required this.structuredText,
  });

  final String rawText;
  final String structuredText;
}
Map<String, Object?> _extractPdfTextFromBytesInBackground(Uint8List inputBytes) {
  final documentStopwatch = Stopwatch()..start();
  final document = PdfDocument(inputBytes: inputBytes);
  final documentMs = documentStopwatch.elapsedMilliseconds;
  try {
    final textStopwatch = Stopwatch()..start();
    final text = _normalizePdfTextForUpload(PdfTextExtractor(document).extractText());
    return <String, Object?>{
      'text': text,
      'documentMs': documentMs,
      'textMs': textStopwatch.elapsedMilliseconds,
    };
  } finally {
    document.dispose();
  }
}

String _normalizePdfTextForUpload(String value) {
  return value
      .replaceAll('\u0000', '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\s+\n'), '\n')
      .replaceAll(RegExp(r'\n\s+'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
