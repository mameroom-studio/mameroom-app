import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
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
      if (message == null || message == previous?.errorMessage || message == previous?.infoMessage) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      ref.read(uploadControllerProvider.notifier).clearMessages();
    });

    final draft = ref.watch(uploadControllerProvider);
    final selectedJob = draft.selectedJob;
    final isUploading = draft.isUploading;
    final colors = context.mameroom;

    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          _UploadHeader(onBack: () => context.pop()),
          const SizedBox(height: 24),
          Text('공부 자료 추가', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'PDF 또는 이미지를 선택하거나 텍스트를 붙여넣어 학습 자료를 만들어요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 22),
          _UploadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const PixelSeed(size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('파일 선택', style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _PickActions(
                  isEnabled: !isUploading,
                  onPickPdf: () => ref.read(uploadControllerProvider.notifier).pickPdf(),
                  onPickImage: () => ref.read(uploadControllerProvider.notifier).pickImage(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('텍스트 붙여넣기', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _UploadCard(
            padding: EdgeInsets.zero,
            child: TextField(
              controller: _textController,
              enabled: !isUploading,
              minLines: 6,
              maxLines: 9,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '노트, 용어, 교재 내용을 여기에 붙여넣으세요.',
                filled: true,
                fillColor: colors.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colors.primary, width: 1.4),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              onChanged: (value) {
                ref.read(uploadControllerProvider.notifier).setTextContent(value);
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('업로드 전 확인', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
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
                final result = await ref.read(uploadControllerProvider.notifier).confirmDraft();
                if (result == null || !context.mounted) {
                  return;
                }

                context.go('${AnalysisPage.routePath}?materialId=${result.materialId}');
              },
            ),
        ],
      ),
    );
  }
}

class _UploadHeader extends StatelessWidget {
  const _UploadHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: '뒤로가기',
          onPressed: onBack,
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.mameroom.primary),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text('Upload material', style: Theme.of(context).textTheme.titleLarge)),
      ],
    );
  }
}

class _PickActions extends StatelessWidget {
  const _PickActions({
    required this.isEnabled,
    required this.onPickPdf,
    required this.onPickImage,
  });

  final bool isEnabled;
  final VoidCallback onPickPdf;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 340;
        final pdfButton = _PickButton(
          onPressed: isEnabled ? onPickPdf : null,
          icon: Icons.picture_as_pdf_outlined,
          label: 'PDF',
        );
        final imageButton = _PickButton(
          onPressed: isEnabled ? onPickImage : null,
          icon: Icons.image_outlined,
          label: 'Image',
        );

        if (useSingleColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              pdfButton,
              const SizedBox(height: 10),
              imageButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: pdfButton),
            const SizedBox(width: 10),
            Expanded(child: imageButton),
          ],
        );
      },
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.paper,
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(icon, color: colors.primary),
        label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}

class _NoSelectionPanel extends StatelessWidget {
  const _NoSelectionPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _UploadCard(
      child: Column(
        children: [
          const PixelSeed(size: 54),
          const SizedBox(height: 14),
          Text('아직 선택된 자료가 없어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'PDF, 이미지 또는 붙여넣은 텍스트를 선택해주세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
        ],
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
    final colors = context.mameroom;
    return _UploadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryMist.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(job.sourceType), color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_labelFor(job.sourceType)} · ${job.sizeLabel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: isUploading ? null : onClear,
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Clear'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: isUploading ? null : onConfirm,
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: isUploading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(UploadSourceType sourceType) {
    return switch (sourceType) {
      UploadSourceType.pdf => Icons.picture_as_pdf_outlined,
      UploadSourceType.image => Icons.image_outlined,
      UploadSourceType.camera => Icons.image_outlined,
      UploadSourceType.text => Icons.notes_outlined,
    };
  }

  String _labelFor(UploadSourceType sourceType) {
    return switch (sourceType) {
      UploadSourceType.pdf => 'PDF',
      UploadSourceType.image => 'Image',
      UploadSourceType.camera => 'Image',
      UploadSourceType.text => 'Text',
    };
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
