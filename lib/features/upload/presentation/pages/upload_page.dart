import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/colors/app_colors.dart';
import '../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../analysis/presentation/pages/analysis_page.dart';
import '../../domain/entities/upload_job.dart';
import '../providers/upload_controller.dart';

class UploadPage extends ConsumerStatefulWidget {
  const UploadPage({super.key});

  static const routePath = '/upload';

  @override
  ConsumerState<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends ConsumerState<UploadPage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UploadDraftState>(uploadControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.infoMessage;
      if (message == null || message == previous?.errorMessage ||
          message == previous?.infoMessage) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      ref.read(uploadControllerProvider.notifier).clearMessages();
    });

    final draft = ref.watch(uploadControllerProvider);
    final selectedJob = draft.selectedJob;
    final isUploading = draft.isUploading;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload material')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Add study material',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose a local file or paste text to create a study material.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PickActions(
              isEnabled: !isUploading,
              onPickPdf: () => ref.read(uploadControllerProvider.notifier).pickPdf(),
              onPickImage: () => ref.read(uploadControllerProvider.notifier).pickImage(),
              onCapturePhoto: () => ref
                  .read(uploadControllerProvider.notifier)
                  .capturePhoto(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Paste text',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _textController,
              enabled: !isUploading,
              minLines: 5,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Paste notes, terms, or textbook excerpts here.',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(uploadControllerProvider.notifier).setTextContent(value);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Review before upload',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (selectedJob == null)
              const _NoSelectionPanel()
            else
              _ConfirmPanel(
                job: selectedJob,
                isUploading: isUploading,
                onClear: () {
                  _textController.clear();
                  ref.read(uploadControllerProvider.notifier).clearSelection();
                },
                onConfirm: () async {
                  final result = await ref
                      .read(uploadControllerProvider.notifier)
                      .confirmDraft();
                  if (result == null || !context.mounted) {
                    return;
                  }

                  context.go(
                    '${AnalysisPage.routePath}?materialId=${result.materialId}',
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PickActions extends StatelessWidget {
  const _PickActions({
    required this.isEnabled,
    required this.onPickPdf,
    required this.onPickImage,
    required this.onCapturePhoto,
  });

  final bool isEnabled;
  final VoidCallback onPickPdf;
  final VoidCallback onPickImage;
  final VoidCallback onCapturePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEnabled ? onPickPdf : null,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEnabled ? onPickImage : null,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Image'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isEnabled ? onCapturePhoto : null,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Take photo'),
          ),
        ),
      ],
    );
  }
}

class _NoSelectionPanel extends StatelessWidget {
  const _NoSelectionPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.upload_file, size: 40),
            SizedBox(height: AppSpacing.sm),
            Text('No material selected.'),
            SizedBox(height: AppSpacing.xs),
            Text('Select a file, take a photo, or paste text.'),
          ],
        ),
      ),
    );
  }
}

class _ConfirmPanel extends StatelessWidget {
  const _ConfirmPanel({
    required this.job,
    required this.isUploading,
    required this.onClear,
    required this.onConfirm,
  });

  final UploadJob job;
  final bool isUploading;
  final VoidCallback onClear;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_iconFor(job.sourceType)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_labelFor(job.sourceType)} - ${job.sizeLabel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isUploading ? null : onClear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: isUploading ? null : onConfirm,
                    child: isUploading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(UploadSourceType sourceType) {
    return switch (sourceType) {
      UploadSourceType.pdf => Icons.picture_as_pdf,
      UploadSourceType.image => Icons.image_outlined,
      UploadSourceType.camera => Icons.photo_camera_outlined,
      UploadSourceType.text => Icons.notes,
    };
  }

  String _labelFor(UploadSourceType sourceType) {
    return switch (sourceType) {
      UploadSourceType.pdf => 'PDF',
      UploadSourceType.image => 'Image',
      UploadSourceType.camera => 'Photo',
      UploadSourceType.text => 'Text',
    };
  }
}