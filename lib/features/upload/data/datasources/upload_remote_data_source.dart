import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/storage_buckets.dart';
import '../../../../shared/supabase/supabase_tables.dart';
import '../../domain/entities/upload_job.dart';
import '../../domain/entities/upload_result.dart';
import 'local_file_bytes_reader.dart';

class UploadRemoteDataSource {
  const UploadRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<UploadResult> createMaterialFromDraft(UploadJob job) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required to upload materials.');
    }

    final materialId = _newUuidV4();
    final fileHash = await _hashFor(job);
    final storagePath = await _uploadOriginalFileIfNeeded(
      userId: user.id,
      materialId: materialId,
      job: job,
    );

    await _client.from(SupabaseTables.studyMaterials).insert({
      'id': materialId,
      'user_id': user.id,
      'title': job.displayName,
      'source_type': _sourceTypeValue(job.sourceType),
      'file_hash': fileHash,
      'storage_path': storagePath,
      'raw_text': job.sourceType == UploadSourceType.text ? job.textContent : null,
      'status': 'uploaded',
    });

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

    await _client.storage.from(StorageBuckets.materials).uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _contentTypeFor(job),
          ),
        );

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
    final bytes = job.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return bytes;
    }

    final path = job.path;
    if (path != null && path.isNotEmpty) {
      return readLocalFileBytes(path);
    }

    throw StateError('Selected file bytes are unavailable. Please select the file again.');
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
