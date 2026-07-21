import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../../../shared/widgets/mameroom_shell.dart'
    hide MameroomPrimaryButton;
import '../../../analysis/presentation/pages/analysis_page.dart';
import '../../domain/entities/upload_job.dart';
import '../../domain/entities/upload_result.dart';
import '../providers/upload_controller.dart';

enum MaterialInputMode {
  manual('manual', '직접 생성'),
  txt('txt', '텍스트 불러오기'),
  pdf('pdf', 'PDF 불러오기');

  const MaterialInputMode(this.value, this.label);
  final String value;
  final String label;

  static MaterialInputMode? fromValue(String? value) {
    for (final mode in values) {
      if (mode.value == value) return mode;
    }
    return null;
  }
}

class UploadPage extends ConsumerStatefulWidget {
  const UploadPage({this.initialMode, super.key});

  static const routePath = '/upload';
  final MaterialInputMode? initialMode;

  @override
  ConsumerState<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends ConsumerState<UploadPage> {
  static const _maxTitleLength = 120;
  static const _minContentLength = 80;
  static const _maxContentLength = 200000;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  MaterialInputMode? _mode;
  bool _dirty = false;
  bool _pdfContentReady = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _titleController.addListener(_markDirty);
    _contentController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty &&
        (_titleController.text.isNotEmpty ||
            _contentController.text.isNotEmpty)) {
      setState(() => _dirty = true);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_markDirty)
      ..dispose();
    _contentController
      ..removeListener(_markDirty)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UploadDraftState>(uploadControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.infoMessage;
      if (message == null ||
          message == previous?.errorMessage ||
          message == previous?.infoMessage) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      ref.read(uploadControllerProvider.notifier).clearMessages();
    });

    final state = ref.watch(uploadControllerProvider);
    final colors = context.mameroom;
    final mode = _mode;

    return PopScope(
      canPop: !_dirty && !state.isUploading,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || state.isUploading) return;
        if (await _confirmDiscard() && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: colors.paper,
        appBar: AppBar(
          title: Text(mode?.label ?? '학습자료 등록'),
          leading: IconButton(
            key: const ValueKey('material-draft-back'),
            tooltip: '뒤로가기',
            onPressed: state.isUploading ? null : _requestBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: MameroomShell(
          showSparkles: false,
          padding: EdgeInsets.zero,
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    key: const ValueKey('material-registration-scroll'),
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth < 360
                          ? MameroomSpacing.sm
                          : MameroomSpacing.md,
                      MameroomSpacing.sm,
                      constraints.maxWidth < 360
                          ? MameroomSpacing.sm
                          : MameroomSpacing.md,
                      MediaQuery.viewInsetsOf(context).bottom +
                          MameroomSpacing.xl,
                    ),
                    children: [
                      if (mode == null)
                        _ModeChooser(onSelected: _selectMode)
                      else ...[
                        _Intro(mode: mode),
                        const SizedBox(height: MameroomSpacing.md),
                        if (mode == MaterialInputMode.pdf)
                          const _PdfRequirements(),
                        if (mode != MaterialInputMode.manual)
                          _FileSection(
                            mode: mode,
                            job: state.selectedJob,
                            enabled: !state.isUploading,
                            onPick: mode == MaterialInputMode.txt
                                ? _pickTxt
                                : _pickPdf,
                          ),
                        if (mode != MaterialInputMode.manual)
                          const SizedBox(height: MameroomSpacing.md),
                        if (mode == MaterialInputMode.pdf && state.isUploading)
                          _ProcessingSteps(stage: state.processingStage),
                        if (_showEditor(state))
                          _DraftEditor(
                            titleController: _titleController,
                            contentController: _contentController,
                            maxTitleLength: _maxTitleLength,
                            maxContentLength: _maxContentLength,
                            contentReadOnly: false,
                          ),
                        if (_showEditor(state)) ...[
                          const SizedBox(height: MameroomSpacing.md),
                          const _PrivacyNotice(),
                          const SizedBox(height: MameroomSpacing.md),
                          _GenerateButton(
                            enabled: _canGenerate(state),
                            isLoading: state.isUploading,
                            disabledReason: _disabledReason(state),
                            onPressed: _generate,
                          ),
                        ] else if (mode == MaterialInputMode.pdf &&
                            state.selectedJob != null &&
                            !state.isUploading) ...[
                          _GenerateButton(
                            key: const ValueKey('extract-pdf-button'),
                            enabled: true,
                            isLoading: false,
                            disabledReason: null,
                            label: '내용 가져오기',
                            onPressed: _preparePdf,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _showEditor(UploadDraftState state) =>
      _mode == MaterialInputMode.manual ||
      _mode == MaterialInputMode.txt && state.selectedJob != null ||
      _mode == MaterialInputMode.pdf && _pdfContentReady;

  bool _canGenerate(UploadDraftState state) {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    return !state.isUploading &&
        title.isNotEmpty &&
        title.length <= _maxTitleLength &&
        content.length >= _minContentLength &&
        content.length <= _maxContentLength;
  }

  String? _disabledReason(UploadDraftState state) {
    if (state.isUploading) return '현재 요청을 처리하고 있어요.';
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) return '자료 제목을 입력해 주세요.';
    if (title.length > _maxTitleLength) return '자료 제목이 너무 깁니다.';
    if (content.length < _minContentLength) {
      return '학습 내용을 최소 $_minContentLength자 입력해 주세요.';
    }
    if (content.length > _maxContentLength) return '학습 내용이 최대 글자 수를 초과했습니다.';
    return null;
  }

  void _selectMode(MaterialInputMode mode) {
    ref.read(uploadControllerProvider.notifier).clearSelection();
    setState(() {
      _mode = mode;
      _dirty = false;
      _pdfContentReady = false;
      _titleController.clear();
      _contentController.clear();
    });
  }

  Future<void> _pickTxt() async {
    await ref.read(uploadControllerProvider.notifier).pickTxt();
    final job = ref.read(uploadControllerProvider).selectedJob;
    if (job?.sourceType != UploadSourceType.text) return;
    _titleController.text = job!.displayName;
    _contentController.text = job.textContent ?? '';
    setState(() => _dirty = true);
  }

  Future<void> _pickPdf() async {
    await ref.read(uploadControllerProvider.notifier).pickPdf();
    final job = ref.read(uploadControllerProvider).selectedJob;
    if (job?.sourceType != UploadSourceType.pdf) return;
    _titleController.text = _withoutExtension(job!.displayName);
    _contentController.clear();
    setState(() {
      _dirty = true;
      _pdfContentReady = false;
    });
  }

  Future<void> _preparePdf() async {
    final draft = await ref
        .read(uploadControllerProvider.notifier)
        .preparePdfForReview();
    if (draft == null || !mounted) return;
    _titleController.text = _withoutExtension(draft.title);
    _contentController.text = draft.content;
    setState(() {
      _pdfContentReady = true;
      _dirty = true;
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      'PDF 텍스트 추출이 완료되었습니다. 내용을 확인해 주세요.',
      TextDirection.ltr,
    );
  }

  Future<void> _generate() async {
    if (!_canGenerate(ref.read(uploadControllerProvider))) return;
    final controller = ref.read(uploadControllerProvider.notifier);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final UploadResult? result = _mode == MaterialInputMode.pdf
        ? await controller.savePreparedPdf(title: title, content: content)
        : await controller.createTextMaterial(title: title, content: content);
    if (result == null || !mounted) return;
    _dirty = false;
    context.go('${AnalysisPage.routePath}?materialId=${result.materialId}');
  }

  Future<void> _requestBack() async {
    if (!_dirty || await _confirmDiscard()) {
      if (mounted) context.pop();
    }
  }

  Future<bool> _confirmDiscard() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('작성을 그만둘까요?'),
          content: const Text('입력한 내용이 저장되지 않을 수 있어요.'),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('계속 작성'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('나가기'),
            ),
          ],
        ),
      ) ??
      false;

  String _withoutExtension(String value) => value
      .replaceFirst(RegExp(r'\.(pdf|txt)$', caseSensitive: false), '')
      .trim();
}

class _ModeChooser extends StatelessWidget {
  const _ModeChooser({required this.onSelected});
  final ValueChanged<MaterialInputMode> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('등록 방식을 선택해 주세요', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: MameroomSpacing.sm),
      _ModeTile(
        mode: MaterialInputMode.manual,
        icon: Icons.edit_note_rounded,
        description: '학습할 내용을 직접 입력해 문제를 만들어요',
        onTap: onSelected,
      ),
      _ModeTile(
        mode: MaterialInputMode.txt,
        icon: Icons.description_outlined,
        description: 'TXT 파일에서 학습 내용을 가져와요',
        onTap: onSelected,
      ),
      _ModeTile(
        mode: MaterialInputMode.pdf,
        icon: Icons.picture_as_pdf_outlined,
        description: '텍스트로 작성된 PDF에서 내용을 가져와요',
        onTap: onSelected,
      ),
    ],
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.icon,
    required this.description,
    required this.onTap,
  });
  final MaterialInputMode mode;
  final IconData icon;
  final String description;
  final ValueChanged<MaterialInputMode> onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${mode.label}, $description',
    child: Padding(
      padding: const EdgeInsets.only(bottom: MameroomSpacing.xs),
      child: MameroomInteractiveCard(
        onTap: () => onTap(mode),
        child: Row(
          children: [
            Semantics(
              excludeSemantics: true,
              child: Icon(icon, color: context.mameroom.primary, size: 28),
            ),
            const SizedBox(width: MameroomSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: MameroomSpacing.xxs),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.mameroom.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _Intro extends StatelessWidget {
  const _Intro({required this.mode});
  final MaterialInputMode mode;

  @override
  Widget build(BuildContext context) => Text(switch (mode) {
    MaterialInputMode.manual => '입력한 학습 내용을 AI가 분석해 문제로 만들어요.',
    MaterialInputMode.txt => 'TXT 내용을 불러온 뒤 문제 생성 전에 직접 확인하고 수정할 수 있어요.',
    MaterialInputMode.pdf => '지원 조건을 확인하고 PDF에서 가져온 내용을 검토한 뒤 문제를 만들어요.',
  }, style: Theme.of(context).textTheme.bodyLarge);
}

class _PdfRequirements extends StatelessWidget {
  const _PdfRequirements();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MameroomSpacing.md),
    child: MameroomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('PDF 지원 조건'),
          SizedBox(height: MameroomSpacing.xs),
          Text('• 텍스트를 선택할 수 있는 PDF만 지원합니다.'),
          Text('• 스캔된 PDF, 사진 및 손글씨는 지원하지 않습니다.'),
          Text('• 암호가 설정된 PDF는 처리하지 못할 수 있습니다.'),
          Text('• 선택한 PDF는 텍스트 추출을 위해 서버로 전송됩니다.'),
        ],
      ),
    ),
  );
}

class _FileSection extends StatelessWidget {
  const _FileSection({
    required this.mode,
    required this.job,
    required this.enabled,
    required this.onPick,
  });
  final MaterialInputMode mode;
  final UploadJob? job;
  final bool enabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => MameroomCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (job != null) ...[
          Row(
            children: [
              Icon(
                mode == MaterialInputMode.pdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.description_outlined,
                color: context.mameroom.primary,
              ),
              const SizedBox(width: MameroomSpacing.sm),
              Expanded(
                child: Text(
                  job!.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(job!.sizeLabel),
            ],
          ),
          const SizedBox(height: MameroomSpacing.sm),
        ],
        MameroomSecondaryButton(
          label: job == null
              ? mode == MaterialInputMode.pdf
                    ? 'PDF 파일 선택'
                    : 'TXT 파일 선택'
              : '다시 선택',
          onPressed: enabled ? onPick : null,
        ),
        if (mode == MaterialInputMode.txt) ...[
          const SizedBox(height: MameroomSpacing.xs),
          const Text('TXT 파일만 지원합니다. · UTF-8 형식을 권장합니다.'),
        ],
      ],
    ),
  );
}

class _DraftEditor extends StatelessWidget {
  const _DraftEditor({
    required this.titleController,
    required this.contentController,
    required this.maxTitleLength,
    required this.maxContentLength,
    required this.contentReadOnly,
  });
  final TextEditingController titleController;
  final TextEditingController contentController;
  final int maxTitleLength;
  final int maxContentLength;
  final bool contentReadOnly;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const ValueKey('material-title-field'),
        controller: titleController,
        maxLength: maxTitleLength,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: '자료 제목 (필수)',
          hintText: '자료 제목을 입력해 주세요',
        ),
      ),
      const SizedBox(height: MameroomSpacing.sm),
      TextField(
        key: const ValueKey('learning-content-field'),
        controller: contentController,
        readOnly: contentReadOnly,
        minLines: 9,
        maxLines: 18,
        maxLength: maxContentLength,
        decoration: const InputDecoration(
          labelText: '학습 내용',
          alignLabelWithHint: true,
          hintText:
              '공부할 내용을 직접 입력하거나 붙여넣어 주세요.\n'
              '핵심 개념과 설명이 충분할수록 문제를 더 정확하게 만들 수 있어요.',
        ),
      ),
    ],
  );
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) => MameroomCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, color: context.mameroom.warning),
        const SizedBox(width: MameroomSpacing.sm),
        const Expanded(
          child: Text(
            '개인정보나 민감한 내용은 입력하지 마세요. '
            'AI 문제 생성 전에 제목과 학습 내용을 다시 확인해 주세요.',
          ),
        ),
      ],
    ),
  );
}

class _ProcessingSteps extends StatelessWidget {
  const _ProcessingSteps({required this.stage});
  final UploadTransferStage? stage;

  @override
  Widget build(BuildContext context) {
    final current = switch (stage) {
      UploadTransferStage.extractingPdfText => 1,
      _ => 0,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: MameroomSpacing.md),
      child: MameroomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('처리 상태', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: MameroomSpacing.sm),
            _Step(label: '파일 업로드 중', done: current > 0, active: current == 0),
            _Step(label: '텍스트 추출 중', done: false, active: current == 1),
            const _Step(label: '내용 확인', done: false, active: false),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done, required this.active});
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: active,
    label:
        '$label, ${done
            ? '완료'
            : active
            ? '진행 중'
            : '대기'}',
    child: ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done
            ? Icons.check_circle_rounded
            : active
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: done || active
            ? context.mameroom.primary
            : context.mameroom.muted,
      ),
      title: Text(label),
      trailing: active
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    ),
  );
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    super.key,
    required this.enabled,
    required this.isLoading,
    required this.disabledReason,
    required this.onPressed,
    this.label = '문제 만들기',
  });
  final bool enabled;
  final bool isLoading;
  final String? disabledReason;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    hint: enabled ? '$label 버튼' : disabledReason,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MameroomPrimaryButton(
          key: const ValueKey('generate-questions-button'),
          label: label,
          isLoading: isLoading,
          onPressed: enabled ? onPressed : null,
        ),
        if (!enabled && disabledReason != null) ...[
          const SizedBox(height: MameroomSpacing.xs),
          Text(
            disabledReason!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.mameroom.muted),
          ),
        ],
      ],
    ),
  );
}
