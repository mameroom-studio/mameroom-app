import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/storage_buckets.dart';
import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/upload_job.dart';
import '../../domain/entities/upload_material_draft.dart';
import '../../domain/entities/upload_result.dart';
import 'local_file_bytes_reader.dart';

class UploadRemoteDataSource {
  const UploadRemoteDataSource(this._client);

  final SupabaseClient _client;
  Future<UploadMaterialDraft> loadMaterialDraft(String materialId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User session is required.');
    final row = await _client
        .from(SupabaseTables.studyMaterials)
        .select('id,title,raw_text')
        .eq('id', materialId)
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) throw StateError('Study material was not found.');
    final content = row['raw_text']?.toString().trim() ?? '';
    if (content.isEmpty) throw StateError('PDF_TEXT_EMPTY');
    return UploadMaterialDraft(
      materialId: row['id'].toString(),
      title: row['title']?.toString() ?? '',
      content: content,
    );
  }

  Future<void> updateMaterialDraft({
    required String materialId,
    required String title,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User session is required.');
    final rows = await _client
        .from(SupabaseTables.studyMaterials)
        .update({
          'title': title.trim(),
          'raw_text': content.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', materialId)
        .eq('user_id', user.id)
        .select('id');
    if (rows.isEmpty) throw StateError('Material update was not allowed.');
  }

  Future<UploadResult> createMaterialFromDraft(
    UploadJob job, {
    void Function(UploadTransferStage stage)? onStage,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to upload materials.');
    }

    if (job.sourceType == UploadSourceType.pdf) {
      return _createPdfMaterialFromDraft(
        userId: user.id,
        job: job,
        onStage: onStage,
      );
    }

    onStage?.call(UploadTransferStage.saving);
    final materialId = _newUuidV4();
    final fileHash = await _hashFor(job);
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
      rawTextLength: job.sourceType == UploadSourceType.text
          ? job.textContent?.length
          : null,
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
        'raw_text': job.sourceType == UploadSourceType.text
            ? job.textContent
            : null,
        'structured_text': null,
        'status': 'uploading',
      });
      _logUploadStop(
        'STOP-14 study_material.insert.success',
        job: job,
        materialId: materialId,
        rawTextLength: job.sourceType == UploadSourceType.text
            ? job.textContent?.length
            : null,
        elapsedMs: insertStopwatch.elapsedMilliseconds,
      );
    } catch (error, stackTrace) {
      _logUploadStop(
        'STOP-13 study_material.insert.start',
        job: job,
        materialId: materialId,
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

  Future<UploadResult> _createPdfMaterialFromDraft({
    required String userId,
    required UploadJob job,
    void Function(UploadTransferStage stage)? onStage,
  }) async {
    onStage?.call(UploadTransferStage.saving);
    final materialId = _newUuidV4();
    final fileBytes = await _bytesFor(job);
    final fileHash = sha256.convert(fileBytes).toString();
    final storagePath = [
      userId,
      materialId,
      _storageObjectFileName(materialId, job),
    ].join('/');

    onStage?.call(UploadTransferStage.uploadingPdf);
    final uploadStopwatch = Stopwatch()..start();
    _logUploadStop(
      'PDF-UPLOAD-01 storage.upload.start',
      job: job,
      materialId: materialId,
      storagePath: storagePath,
      bytesLength: fileBytes.length,
      elapsedMs: 0,
    );
    try {
      await _client.storage
          .from(StorageBuckets.pdfUploads)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(
              upsert: false,
              contentType: 'application/pdf',
            ),
          );
      _logUploadStop(
        'PDF-UPLOAD-02 storage.upload.success',
        job: job,
        materialId: materialId,
        storagePath: storagePath,
        bytesLength: fileBytes.length,
        elapsedMs: uploadStopwatch.elapsedMilliseconds,
      );
    } catch (error, stackTrace) {
      _logUploadStop(
        'PDF-UPLOAD-01 storage.upload.start',
        job: job,
        materialId: materialId,
        storagePath: storagePath,
        bytesLength: fileBytes.length,
        elapsedMs: uploadStopwatch.elapsedMilliseconds,
        exception: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    await _client.from(SupabaseTables.studyMaterials).insert({
      'id': materialId,
      'user_id': userId,
      'title': job.displayName,
      'source_type': 'pdf',
      'file_hash': fileHash,
      'storage_path': storagePath,
      'raw_text': null,
      'structured_text': null,
      'status': 'uploading',
    });

    onStage?.call(UploadTransferStage.extractingPdfText);
    await _invokeAnalyzePdf(
      materialId: materialId,
      storagePath: storagePath,
      job: job,
    );

    return UploadResult(
      materialId: materialId,
      storagePath: storagePath,
      fileHash: fileHash,
    );
  }

  Future<void> _invokeAnalyzePdf({
    required String materialId,
    required String storagePath,
    required UploadJob job,
  }) async {
    final stopwatch = Stopwatch()..start();
    _logUploadStop(
      'PDF-ANALYZE-01 function.invoke.start',
      job: job,
      materialId: materialId,
      storagePath: storagePath,
      extractorName: 'analyze-pdf',
      elapsedMs: 0,
    );
    try {
      await _client.functions.invoke(
        'analyze-pdf',
        body: {'materialId': materialId, 'storagePath': storagePath},
      );
      _logUploadStop(
        'PDF-ANALYZE-02 function.invoke.success',
        job: job,
        materialId: materialId,
        storagePath: storagePath,
        extractorName: 'analyze-pdf',
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    } on FunctionException catch (error, stackTrace) {
      _logUploadStop(
        'PDF-ANALYZE-03 function.invoke.failed',
        job: job,
        materialId: materialId,
        storagePath: storagePath,
        extractorName: 'analyze-pdf',
        elapsedMs: stopwatch.elapsedMilliseconds,
        exception: error,
        stackTrace: stackTrace,
      );
      throw StateError(_functionErrorMessage('analyze-pdf', error));
    } catch (error, stackTrace) {
      _logUploadStop(
        'PDF-ANALYZE-03 function.invoke.failed',
        job: job,
        materialId: materialId,
        storagePath: storagePath,
        extractorName: 'analyze-pdf',
        elapsedMs: stopwatch.elapsedMilliseconds,
        exception: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
      storagePath: storagePath,
      bytesLength: fileBytes.length,
      elapsedMs: 0,
    );
    try {
      await _client.storage
          .from(StorageBuckets.materials)
          .uploadBinary(
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
        storagePath: storagePath,
        bytesLength: fileBytes.length,
        elapsedMs: uploadStopwatch.elapsedMilliseconds,
      );
    } catch (error, stackTrace) {
      _logUploadStop(
        'STOP-11 storage.upload.start',
        job: job,
        materialId: materialId,
        storagePath: storagePath,
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
    _logUploadStop('STOP-02 file.bytes.read.start', job: job, elapsedMs: 0);
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

      throw StateError(
        'Selected file bytes are unavailable. Please select the file again.',
      );
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

  void _logUploadStop(
    String stopPoint, {
    required UploadJob job,
    String? materialId,
    String? storagePath,
    int? bytesLength,
    int? rawTextLength,
    int? structuredTextLength,
    String? extractorName,
    int? elapsedMs,
    Object? exception,
    String? exceptionMessage,
    String? reason,
    StackTrace? stackTrace,
  }) {
    final payload = jsonEncode({
      'stopPoint': stopPoint,
      'analysisId': materialId,
      'materialId': materialId,
      'storagePath': storagePath,
      'materialTitle': job.displayName,
      'fileExtension': _extensionFor(job.displayName),
      'fileSize': job.sizeBytes,
      'bytesLength': bytesLength,
      'elapsedMs': elapsedMs,
      'textLength': rawTextLength,
      'rawTextLength': rawTextLength,
      'structuredTextLength': structuredTextLength,
      'extractorName': extractorName,
      'isFlutterWeb': kIsWeb,
      'reason': reason,
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

String _functionErrorMessage(String functionName, FunctionException error) {
  final details = error.details;
  if (details is Map) {
    final code = details['code']?.toString();
    final message =
        details['error']?.toString() ?? details['message']?.toString();
    final suffix = code == null || code.isEmpty ? '' : '$code: ';
    if (message != null && message.isNotEmpty) {
      return '$functionName failed (${error.status}): $suffix$message';
    }
  }
  if (details is String && details.isNotEmpty) {
    return '$functionName failed (${error.status}): $details';
  }
  return '$functionName failed (${error.status}).';
}
