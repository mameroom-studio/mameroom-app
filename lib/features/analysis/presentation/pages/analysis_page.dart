import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../quiz/presentation/pages/quiz_page.dart';
import '../../domain/entities/analysis_progress.dart';
import '../providers/analysis_providers.dart';

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({required this.materialId, super.key});

  static const routePath = '/analysis';

  final String? materialId;

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  @override
  void initState() {
    super.initState();
    final materialId = widget.materialId;
    if (materialId != null && materialId.isNotEmpty) {
      Future.microtask(() {
        ref.read(analysisControllerProvider.notifier).start(materialId: materialId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AnalysisProgress?>>(analysisControllerProvider, (previous, next) {
      final progress = next.asData?.value;
      if (progress?.status == MaterialAnalysisStatus.completed &&
          widget.materialId != null &&
          widget.materialId!.isNotEmpty) {
        context.go('${QuizPage.routePath}?materialId=${widget.materialId}');
      }
    });

    final state = ref.watch(analysisControllerProvider);
    final progress = state.asData?.value;
    final errorKind = _analysisErrorKind(state.error);
    final currentStatus = progress?.status ?? MaterialAnalysisStatus.uploaded;
    final displayStatus = state.hasError && errorKind != _AnalysisErrorKind.duplicate ? MaterialAnalysisStatus.failed : currentStatus;

    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: widget.materialId == null || widget.materialId!.isEmpty
          ? _MissingMaterialId(onBack: () => context.go(LibraryPage.routePath))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _AnalysisHeader(onLibrary: () => context.go(LibraryPage.routePath)),
                const SizedBox(height: 24),
                _HeroAnalysisCard(
                  state: state,
                  progress: progress,
                  progressValue: _progressValue(state, progress),
                ),
                const SizedBox(height: 18),
                _StatusTimeline(currentStatus: displayStatus),
                const SizedBox(height: 18),
                _AnalysisMessage(
                  state: state,
                  progress: progress,
                  onOpenLibrary: () => context.go(LibraryPage.routePath),
                ),
                const SizedBox(height: 24),
                _BottomAction(
                  progress: progress,
                  isDuplicateUpload: errorKind == _AnalysisErrorKind.duplicate,
                  onLibrary: () => context.go(LibraryPage.routePath),
                  onQuiz: () {
                    if (widget.materialId != null && widget.materialId!.isNotEmpty) {
                      context.go('${QuizPage.routePath}?materialId=${widget.materialId}');
                    }
                  },
                ),
              ],
            ),
    );
  }

  _AnalysisErrorKind _analysisErrorKind(Object? error) {
    final message = error?.toString() ?? '';
    return _classifyAnalysisError(message);
  }

  double? _progressValue(AsyncValue<AnalysisProgress?> state, AnalysisProgress? progress) {
    if (state.isLoading) {
      return null;
    }
    if (state.hasError) {
      return 1;
    }
    return progress?.progress ?? 0.08;
  }
}

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({required this.onLibrary});

  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        const PixelSeed(size: 38),
        const SizedBox(width: 10),
        Expanded(child: Text('Analysis', style: Theme.of(context).textTheme.titleLarge)),
        TextButton.icon(
          onPressed: onLibrary,
          icon: Icon(Icons.home_outlined, color: colors.primary, size: 18),
          label: const Text('Library'),
        ),
      ],
    );
  }
}

class _HeroAnalysisCard extends StatelessWidget {
  const _HeroAnalysisCard({required this.state, required this.progress, required this.progressValue});

  final AsyncValue<AnalysisProgress?> state;
  final AnalysisProgress? progress;
  final double? progressValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    final percent = ((progressValue ?? progress?.progress ?? 0.08).clamp(0, 1) * 100).round();
    final isIndeterminate = state.isLoading && progress == null;

    return _AnalysisCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 학습 콘텐츠 생성 중', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  '핵심 개념을 뽑고 첫 퀴즈를 준비하고 있어요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: isIndeterminate ? null : progressValue,
                    minHeight: 11,
                    color: colors.primary,
                    backgroundColor: colors.primaryMist.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 10),
                Text('$percent% 완료', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: const PixelSeed(size: 72),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.currentStatus});

  static const _statuses = [
    MaterialAnalysisStatus.uploaded,
    MaterialAnalysisStatus.extracting,
    MaterialAnalysisStatus.analyzing,
    MaterialAnalysisStatus.conceptsCompleted,
    MaterialAnalysisStatus.questionsGenerating,
    MaterialAnalysisStatus.completed,
    MaterialAnalysisStatus.failed,
  ];

  final MaterialAnalysisStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('진행 단계', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ..._statuses.map((status) {
            final isCurrent = status == currentStatus;
            final isDone = _isDone(status, currentStatus);
            final isFailed = status == MaterialAnalysisStatus.failed && isCurrent;
            final color = isFailed
                ? Theme.of(context).colorScheme.error
                : isCurrent || isDone
                    ? colors.primary
                    : colors.line;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDone ? color : colors.paper,
                      border: Border.all(color: color, width: isCurrent ? 3 : 2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : _iconFor(status),
                      color: isDone ? Colors.white : color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_koreanLabel(status), style: Theme.of(context).textTheme.titleMedium),
                        Text(status.value, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.muted)),
                      ],
                    ),
                  ),
                  if (isCurrent && !isFailed)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isDone(MaterialAnalysisStatus status, MaterialAnalysisStatus currentStatus) {
    if (currentStatus == MaterialAnalysisStatus.failed) {
      return false;
    }
    if (currentStatus == MaterialAnalysisStatus.conceptsCompleted || currentStatus == MaterialAnalysisStatus.completed) {
      return status != MaterialAnalysisStatus.failed && status.index < currentStatus.index;
    }
    return status.index < currentStatus.index;
  }

  IconData _iconFor(MaterialAnalysisStatus status) {
    return switch (status) {
      MaterialAnalysisStatus.uploaded => Icons.upload_file_outlined,
      MaterialAnalysisStatus.extracting => Icons.text_snippet_outlined,
      MaterialAnalysisStatus.analyzing => Icons.psychology_alt_outlined,
      MaterialAnalysisStatus.conceptsCompleted => Icons.spa_outlined,
      MaterialAnalysisStatus.questionsGenerating => Icons.quiz_outlined,
      MaterialAnalysisStatus.completed => Icons.check_circle_outline,
      MaterialAnalysisStatus.failed => Icons.error_outline,
    };
  }

  String _koreanLabel(MaterialAnalysisStatus status) {
    return switch (status) {
      MaterialAnalysisStatus.uploaded => '자료 업로드 완료',
      MaterialAnalysisStatus.extracting => '텍스트 추출',
      MaterialAnalysisStatus.analyzing => '핵심 개념 분석',
      MaterialAnalysisStatus.conceptsCompleted => '핵심 개념 준비 완료',
      MaterialAnalysisStatus.questionsGenerating => '첫 퀴즈 생성',
      MaterialAnalysisStatus.completed => '학습 준비 완료',
      MaterialAnalysisStatus.failed => '분석 실패',
    };
  }
}

class _AnalysisMessage extends StatelessWidget {
  const _AnalysisMessage({required this.state, required this.progress, required this.onOpenLibrary});

  final AsyncValue<AnalysisProgress?> state;
  final AnalysisProgress? progress;
  final VoidCallback onOpenLibrary;



  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    if (state.hasError) {
      final message = state.error.toString();
      final errorKind = _classifyAnalysisError(message);
      final isDuplicateUpload = errorKind == _AnalysisErrorKind.duplicate;
      final isConceptsEmpty = errorKind == _AnalysisErrorKind.conceptsEmpty;
      return _AnalysisCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isDuplicateUpload ? Icons.info_outline : Icons.error_outline, color: isDuplicateUpload ? colors.primary : Theme.of(context).colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDuplicateUpload
                        ? '이미 업로드된 자료입니다'
                        : isConceptsEmpty
                            ? '문제를 만들 핵심 개념을 찾지 못했어요.'
                            : '분석에 실패했어요',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isDuplicateUpload
                  ? '같은 파일의 분석이 이미 진행 중이거나 완료되었습니다. 라이브러리에서 기존 자료를 이어서 학습할 수 있습니다.'
                  : isConceptsEmpty
                      ? '문서에서 시험 문제로 만들 수 있는 핵심 개념이 충분히 추출되지 않았습니다. 원본 오류: $message'
                      : message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
            if (isDuplicateUpload) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(onPressed: onOpenLibrary, child: const Text('기존 자료 보러가기')),
              ),
            ],
          ],
        ),
      );
    }

    final conceptCount = progress?.conceptCount ?? 0;
    final message = progress?.message ?? '분석을 준비하고 있어요.';
    return _AnalysisCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primaryMist.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.auto_awesome, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  '저장된 개념 $conceptCount개${progress?.usedCache == true ? ' · 캐시 사용' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.progress, required this.isDuplicateUpload, required this.onLibrary, required this.onQuiz});

  final AnalysisProgress? progress;
  final bool isDuplicateUpload;
  final VoidCallback onLibrary;
  final VoidCallback onQuiz;

  @override
  Widget build(BuildContext context) {
    final canStart = progress?.isCompleted == true;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: canStart ? onQuiz : isDuplicateUpload ? onLibrary : null,
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        icon: Icon(canStart ? Icons.play_arrow_rounded : Icons.home_outlined),
        label: Text(canStart ? '퀴즈 시작하기' : '라이브러리로 돌아가기'),
      ),
    );
  }
}

class _MissingMaterialId extends StatelessWidget {
  const _MissingMaterialId({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _AnalysisCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelSeed(size: 58),
              const SizedBox(height: 16),
              Text('자료 ID가 없어요', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(onPressed: onBack, child: const Text('라이브러리로 돌아가기')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(18),
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


enum _AnalysisErrorKind { duplicate, conceptsEmpty, other }

_AnalysisErrorKind _classifyAnalysisError(String message) {
  final upper = message.toUpperCase();
  final lower = message.toLowerCase();
  if (upper.contains('CONCEPTS_EMPTY') || upper.contains('CONCEPTS_INSUFFICIENT')) {
    return _AnalysisErrorKind.conceptsEmpty;
  }
  if (upper.contains('DUPLICATE_MATERIAL') ||
      upper.contains('DUPLICATE_ANALYSIS_IN_PROGRESS') ||
      upper.contains('CACHE_REUSED') ||
      lower.contains('same file hash already has an analysis job')) {
    return _AnalysisErrorKind.duplicate;
  }
  return _AnalysisErrorKind.other;
}
