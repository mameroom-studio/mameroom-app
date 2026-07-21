import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/upload_job.dart';
import '../../domain/entities/upload_material_draft.dart';
import '../../domain/entities/upload_result.dart';
import 'upload_providers.dart';

class UploadDraftState {
  const UploadDraftState({
    this.selectedJob,
    this.uploadResult,
    this.errorMessage,
    this.infoMessage,
    this.isUploading = false,
    this.processingStage,
  });

  final UploadJob? selectedJob;
  final UploadResult? uploadResult;
  final String? errorMessage;
  final String? infoMessage;
  final bool isUploading;
  final UploadTransferStage? processingStage;

  UploadDraftState copyWith({
    UploadJob? selectedJob,
    UploadResult? uploadResult,
    String? errorMessage,
    String? infoMessage,
    bool? isUploading,
    UploadTransferStage? processingStage,
    bool clearSelectedJob = false,
    bool clearUploadResult = false,
    bool clearMessages = false,
  }) {
    return UploadDraftState(
      selectedJob: clearSelectedJob ? null : selectedJob ?? this.selectedJob,
      uploadResult: clearUploadResult
          ? null
          : uploadResult ?? this.uploadResult,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearMessages ? null : infoMessage ?? this.infoMessage,
      isUploading: isUploading ?? this.isUploading,
      processingStage: processingStage ?? this.processingStage,
    );
  }
}

final uploadControllerProvider =
    StateNotifierProvider<UploadController, UploadDraftState>((ref) {
      return UploadController(ref);
    });

class UploadController extends StateNotifier<UploadDraftState> {
  UploadController(this._ref) : super(const UploadDraftState());

  final Ref _ref;
  static const int maxFileSizeBytes = 25 * 1024 * 1024;
  static const int maxTextLength = 200000;

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
  };

  Future<void> pickTxt() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null) return;
      if (_extensionOf(file.name) != 'txt') {
        _setError('TXT 파일만 선택할 수 있어요.');
        return;
      }
      if (file.size <= 0) {
        _setError('이 TXT 파일에는 학습할 내용이 없습니다.');
        return;
      }
      if (file.size > maxFileSizeBytes) {
        _setError('파일 크기는 25MB 이하여야 합니다.');
        return;
      }
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _setError('TXT 파일의 내용을 읽을 수 없습니다. UTF-8 형식인지 확인해 주세요.');
        return;
      }
      String content;
      try {
        content = utf8.decode(bytes, allowMalformed: false);
      } on FormatException {
        _setError('TXT 파일의 내용을 읽을 수 없습니다. UTF-8 형식인지 확인해 주세요.');
        return;
      }
      if (content.startsWith('\uFEFF')) content = content.substring(1);
      content = content.trim();
      if (content.isEmpty) {
        _setError('이 TXT 파일에는 학습할 내용이 없습니다.');
        return;
      }
      if (content.length > maxTextLength) {
        _setError('학습 내용은 200,000자 이하여야 합니다.');
        return;
      }
      final title = file.name
          .replaceFirst(RegExp(r'\.txt$', caseSensitive: false), '')
          .trim();
      state = UploadDraftState(
        selectedJob: UploadJob(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sourceType: UploadSourceType.text,
          displayName: title.isEmpty ? '텍스트 자료' : title,
          sizeBytes: file.size,
          textContent: content,
        ),
        infoMessage: 'TXT 내용을 불러왔어요. 문제 생성 전에 확인해 주세요.',
      );
    } catch (_) {
      _setError('TXT 파일의 내용을 읽을 수 없습니다. UTF-8 형식인지 확인해 주세요.');
    }
  }

  Future<void> pickPdf() async {
    final stopwatch = Stopwatch()..start();
    _logPickerStop(
      'PICK-01 pdf.pick.start',
      sourceType: UploadSourceType.pdf,
      elapsedMs: 0,
    );
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb,
      );

      final file = result?.files.single;
      if (file == null) {
        _logPickerStop(
          'PICK-02 pdf.pick.cancelled',
          sourceType: UploadSourceType.pdf,
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
        return;
      }

      final extension = _extensionOf(file.name);
      if (extension != 'pdf') {
        _setError('Only PDF files are supported.');
        return;
      }

      if (!_isValidSize(file.size)) {
        _setError('File size must be 25 MB or smaller.');
        return;
      }

      if (kIsWeb && (file.bytes == null || file.bytes!.isEmpty)) {
        _setError(
          'Could not read the selected PDF in this browser. Please select it again.',
        );
        _logPickerStop(
          'PICK-03 pdf.pick.failed',
          sourceType: UploadSourceType.pdf,
          fileName: file.name,
          fileSize: file.size,
          elapsedMs: stopwatch.elapsedMilliseconds,
          exception: StateError('Web PDF bytes are empty.'),
        );
        return;
      }

      _logPickerStop(
        'PICK-04 pdf.pick.success',
        sourceType: UploadSourceType.pdf,
        fileName: file.name,
        fileSize: file.size,
        bytesLength: file.bytes?.length,
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
      state = UploadDraftState(
        selectedJob: UploadJob(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sourceType: UploadSourceType.pdf,
          displayName: file.name,
          sizeBytes: file.size,
          path: file.path,
          bytes: file.bytes,
        ),
      );
    } catch (error, stackTrace) {
      _logPickerStop(
        'PICK-03 pdf.pick.failed',
        sourceType: UploadSourceType.pdf,
        elapsedMs: stopwatch.elapsedMilliseconds,
        exception: error,
        stackTrace: stackTrace,
      );
      _setError(_messageFor(error));
    }
  }

  Future<void> pickImage() async {
    final stopwatch = Stopwatch()..start();
    _logPickerStop(
      'PICK-01 image.pick.start',
      sourceType: UploadSourceType.image,
      elapsedMs: 0,
    );
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
      );

      final file = result?.files.single;
      if (file == null) {
        _logPickerStop(
          'PICK-02 image.pick.cancelled',
          sourceType: UploadSourceType.image,
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
        return;
      }

      final extension = _extensionOf(file.name);
      if (!_imageExtensions.contains(extension)) {
        _setError('Only image files are supported.');
        return;
      }

      if (!_isValidSize(file.size)) {
        _setError('File size must be 25 MB or smaller.');
        return;
      }

      if (kIsWeb && (file.bytes == null || file.bytes!.isEmpty)) {
        _setError(
          'Could not read the selected image in this browser. Please select it again.',
        );
        _logPickerStop(
          'PICK-03 image.pick.failed',
          sourceType: UploadSourceType.image,
          fileName: file.name,
          fileSize: file.size,
          elapsedMs: stopwatch.elapsedMilliseconds,
          exception: StateError('Web image bytes are empty.'),
        );
        return;
      }

      _logPickerStop(
        'PICK-04 image.pick.success',
        sourceType: UploadSourceType.image,
        fileName: file.name,
        fileSize: file.size,
        bytesLength: file.bytes?.length,
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
      state = UploadDraftState(
        selectedJob: UploadJob(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sourceType: UploadSourceType.image,
          displayName: file.name,
          sizeBytes: file.size,
          path: file.path,
          bytes: file.bytes,
        ),
      );
    } catch (error, stackTrace) {
      _logPickerStop(
        'PICK-03 image.pick.failed',
        sourceType: UploadSourceType.image,
        elapsedMs: stopwatch.elapsedMilliseconds,
        exception: error,
        stackTrace: stackTrace,
      );
      _setError(_messageFor(error));
    }
  }

  Future<void> capturePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) {
      return;
    }

    final imageBytes = await image.readAsBytes();
    final length = imageBytes.length;
    final extension = _extensionOf(image.name);
    if (!_imageExtensions.contains(extension)) {
      _setError('Only image files are supported.');
      return;
    }

    if (!_isValidSize(length)) {
      _setError('File size must be 25 MB or smaller.');
      return;
    }

    state = UploadDraftState(
      selectedJob: UploadJob(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sourceType: UploadSourceType.camera,
        displayName: image.name.isEmpty ? 'Camera photo' : image.name,
        sizeBytes: length,
        path: image.path,
        bytes: imageBytes,
      ),
    );
  }

  void setTextContent(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      state = state.copyWith(clearSelectedJob: true, clearMessages: true);
      return;
    }

    if (text.length > maxTextLength) {
      _setError('Text must be 200,000 characters or fewer.');
      return;
    }

    state = UploadDraftState(
      selectedJob: UploadJob(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sourceType: UploadSourceType.text,
        displayName: 'Pasted text',
        sizeBytes: text.length,
        textContent: text,
      ),
    );
  }

  Future<UploadMaterialDraft?> preparePdfForReview() async {
    final result = await confirmDraft();
    if (result == null) return null;
    try {
      return await _ref
          .read(uploadUseCaseProvider)
          .loadMaterialDraft(result.materialId);
    } catch (error) {
      _setError(_messageFor(error));
      return null;
    }
  }

  Future<UploadResult?> createTextMaterial({
    required String title,
    required String content,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    state = UploadDraftState(
      selectedJob: UploadJob(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sourceType: UploadSourceType.text,
        displayName: cleanTitle,
        sizeBytes: utf8.encode(cleanContent).length,
        textContent: cleanContent,
      ),
    );
    return confirmDraft();
  }

  Future<UploadResult?> savePreparedPdf({
    required String title,
    required String content,
  }) async {
    final result = state.uploadResult;
    if (result == null || state.isUploading) return null;
    state = state.copyWith(isUploading: true, clearMessages: true);
    try {
      await _ref
          .read(uploadUseCaseProvider)
          .updateMaterialDraft(
            materialId: result.materialId,
            title: title,
            content: content,
          );
      state = state.copyWith(isUploading: false);
      return result;
    } catch (error) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: _messageFor(error),
      );
      return null;
    }
  }

  void clearSelection() {
    state = const UploadDraftState();
  }

  Future<UploadResult?> confirmDraft() async {
    final job = state.selectedJob;
    if (job == null) {
      _setError('Select a study material first.');
      return null;
    }

    final uploadStopwatch = Stopwatch()..start();
    _logUploadStop('STOP-01 upload.button.clicked', job: job, elapsedMs: 0);

    state = state.copyWith(
      isUploading: true,
      clearMessages: true,
      clearUploadResult: true,
    );

    try {
      final result = await _ref
          .read(uploadUseCaseProvider)
          .createMaterialFromDraft(
            job,
            onStage: (stage) => state = state.copyWith(processingStage: stage),
          );
      _logUploadStop(
        'STOP-17 upload.complete',
        job: job,
        materialId: result.materialId,
        elapsedMs: uploadStopwatch.elapsedMilliseconds,
      );
      state = UploadDraftState(
        selectedJob: job,
        uploadResult: result,
        infoMessage: 'Upload complete. Preparing analysis screen.',
      );
      return result;
    } catch (error, stackTrace) {
      _logUploadStop(
        'STOP-17 upload.complete',
        job: job,
        elapsedMs: uploadStopwatch.elapsedMilliseconds,
        exception: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isUploading: false,
        errorMessage: _messageFor(error),
      );
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }

  void _logPickerStop(
    String stopPoint, {
    required UploadSourceType sourceType,
    String? fileName,
    int? fileSize,
    int? bytesLength,
    int? elapsedMs,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final payload = jsonEncode({
      'stopPoint': stopPoint,
      'materialTitle': null,
      'fileExtension': fileName == null ? null : _extensionOf(fileName),
      'fileSize': fileSize,
      'bytesLength': bytesLength,
      'elapsedMs': elapsedMs,
      'sourceType': sourceType.name,
      'isFlutterWeb': kIsWeb,
      'exceptionMessage': exception?.runtimeType.toString(),
      'stackTrace': null,
    });

    debugPrint('[upload-flow] $payload');
  }

  void _logUploadStop(
    String stopPoint, {
    required UploadJob job,
    String? materialId,
    int? elapsedMs,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final payload = jsonEncode({
      'stopPoint': stopPoint,
      'materialId': materialId,
      'materialTitle': null,
      'fileExtension': _extensionOf(job.displayName),
      'fileSize': job.sizeBytes,
      'bytesLength': job.bytes?.length,
      'elapsedMs': elapsedMs,
      'rawTextLength': null,
      'structuredTextLength': null,
      'extractorName': null,
      'isFlutterWeb': kIsWeb,
      'exceptionMessage': exception?.runtimeType.toString(),
      'stackTrace': null,
    });

    debugPrint('[upload-flow] $payload');
  }

  bool _isValidSize(int sizeBytes) {
    return sizeBytes > 0 && sizeBytes <= maxFileSizeBytes;
  }

  String _extensionOf(String name) {
    final parts = name.toLowerCase().split('.');
    return parts.length < 2 ? '' : parts.last;
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  String _messageFor(Object error) {
    final message = error.toString();
    if (message.contains('Supabase is not configured')) {
      return 'Check SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in .env.';
    }
    if (message.contains('User session is required')) {
      return 'Sign in again before uploading.';
    }
    if (message.contains('FilePicker') || message.contains('file_picker')) {
      return 'Could not open the file picker. Please try again.';
    }
    if (message.contains('Web PDF bytes are empty')) {
      return 'Could not read the selected PDF in this browser. Please select it again.';
    }
    if (message.contains('PDF_TEXT_EXTRACTION_FAILED')) {
      return 'PDF 텍스트 레이어를 추출하지 못했습니다. 다른 PDF로 다시 시도해 주세요.';
    }
    if (message.contains('PDF_TEXT_TOO_SHORT_OR_SCANNED') ||
        message.contains('PDF_TEXT_EMPTY')) {
      return 'PDF 내용이 비어 있거나 텍스트를 추출할 수 없는 문서입니다. 다른 문서를 업로드해 주세요.';
    }
    if (message.contains('Selected file bytes are unavailable') ||
        message.contains('Selected file path is missing')) {
      return 'Could not read the selected file. Please select it again.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}
