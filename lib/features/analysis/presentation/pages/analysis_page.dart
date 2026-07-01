import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../library/presentation/pages/library_page.dart';
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
    final state = ref.watch(analysisControllerProvider);
    final progress = state.asData?.value;
    final currentStatus = progress?.status ?? MaterialAnalysisStatus.uploaded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: [
          TextButton(
            onPressed: () => context.go(LibraryPage.routePath),
            child: const Text('Library'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: widget.materialId == null || widget.materialId!.isEmpty
              ? _MissingMaterialId(onBack: () => context.go(LibraryPage.routePath))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'AI1 concept extraction',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This step extracts up to 50 core concepts. Quiz generation is not part of this flow.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: _progressValue(state, progress),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 16),
                    _StatusList(
                      currentStatus: state.hasError
                          ? MaterialAnalysisStatus.failed
                          : currentStatus,
                    ),
                    const SizedBox(height: 24),
                    _AnalysisMessage(state: state, progress: progress),
                    const Spacer(),
                    FilledButton(
                      onPressed: progress?.isCompleted == true
                          ? () => context.go(LibraryPage.routePath)
                          : null,
                      child: const Text('Back to library'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  double? _progressValue(
    AsyncValue<AnalysisProgress?> state,
    AnalysisProgress? progress,
  ) {
    if (state.isLoading) {
      return null;
    }
    if (state.hasError) {
      return 1;
    }
    return progress?.progress ?? 0.08;
  }
}

class _StatusList extends StatelessWidget {
  const _StatusList({required this.currentStatus});

  static const _ai1Statuses = [
    MaterialAnalysisStatus.uploaded,
    MaterialAnalysisStatus.extracting,
    MaterialAnalysisStatus.analyzing,
    MaterialAnalysisStatus.conceptsCompleted,
    MaterialAnalysisStatus.failed,
  ];

  final MaterialAnalysisStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _ai1Statuses.map((status) {
        final isCurrent = status == currentStatus;
        final isDone = _isDone(status, currentStatus);
        final color = status == MaterialAnalysisStatus.failed && isCurrent
            ? Theme.of(context).colorScheme.error
            : isCurrent || isDone
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isDone
                ? Icons.check_circle
                : isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
            color: color,
          ),
          title: Text(status.label),
          subtitle: Text(status.value),
          dense: true,
        );
      }).toList(growable: false),
    );
  }

  bool _isDone(
    MaterialAnalysisStatus status,
    MaterialAnalysisStatus currentStatus,
  ) {
    if (currentStatus == MaterialAnalysisStatus.failed) {
      return false;
    }
    if (currentStatus == MaterialAnalysisStatus.conceptsCompleted ||
        currentStatus == MaterialAnalysisStatus.completed) {
      return status != MaterialAnalysisStatus.failed;
    }
    return status.index < currentStatus.index;
  }
}

class _AnalysisMessage extends StatelessWidget {
  const _AnalysisMessage({required this.state, required this.progress});

  final AsyncValue<AnalysisProgress?> state;
  final AnalysisProgress? progress;

  @override
  Widget build(BuildContext context) {
    if (state.hasError) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            state.error.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
        ),
      );
    }

    final conceptCount = progress?.conceptCount ?? 0;
    final message = progress?.message ?? 'Preparing analysis.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text('Concepts saved: $conceptCount'),
            if (progress?.usedCache == true) const Text('Cache used: same file hash'),
          ],
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          const Text('Material id is missing.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onBack, child: const Text('Back to library')),
        ],
      ),
    );
  }
}