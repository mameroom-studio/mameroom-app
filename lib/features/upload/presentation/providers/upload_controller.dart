import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/upload_job.dart';
import '../../domain/entities/upload_result.dart';
import 'upload_providers.dart';

class UploadDraftState {
  const UploadDraftState({
    this.selectedJob,
    this.uploadResult,
    this.errorMessage,
    this.infoMessage,
    this.isUploading = false,
  });

  final UploadJob? selectedJob;
  final UploadResult? uploadResult;
  final String? errorMessage;
  final String? infoMessage;
  final bool isUploading;

  UploadDraftState copyWith({
    UploadJob? selectedJob,
    UploadResult? uploadResult,
    String? errorMessage,
    String? infoMessage,
    bool? isUploading,
    bool clearSelectedJob = false,
    bool clearUploadResult = false,
    bool clearMessages = false,
  }) {
    return UploadDraftState(
      selectedJob: clearSelectedJob ? null : selectedJob ?? this.selectedJob,
      uploadResult:
          clearUploadResult ? null : uploadResult ?? this.uploadResult,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearMessages ? null : infoMessage ?? this.infoMessage,
      isUploading: isUploading ?? this.isUploading,
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

  Future<void> pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );

    final file = result?.files.single;
    if (file == null) {
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

    state = UploadDraftState(
      selectedJob: UploadJob(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sourceType: UploadSourceType.pdf,
        displayName: file.name,
        sizeBytes: file.size,
        path: file.path,
      ),
    );
  }

  Future<void> pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: false,
    );

    final file = result?.files.single;
    if (file == null) {
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

    state = UploadDraftState(
      selectedJob: UploadJob(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sourceType: UploadSourceType.image,
        displayName: file.name,
        sizeBytes: file.size,
        path: file.path,
      ),
    );
  }

  Future<void> capturePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) {
      return;
    }

    final length = await image.length();
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

  void clearSelection() {
    state = const UploadDraftState();
  }

  Future<UploadResult?> confirmDraft() async {
    final job = state.selectedJob;
    if (job == null) {
      _setError('Select a study material first.');
      return null;
    }

    state = state.copyWith(
      isUploading: true,
      clearMessages: true,
      clearUploadResult: true,
    );

    try {
      final result = await _ref
          .read(uploadUseCaseProvider)
          .createMaterialFromDraft(job);
      state = UploadDraftState(
        selectedJob: job,
        uploadResult: result,
        infoMessage: 'Upload complete. Preparing analysis screen.',
      );
      return result;
    } catch (error) {
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
    return message.replaceFirst('Exception: ', '');
  }
}