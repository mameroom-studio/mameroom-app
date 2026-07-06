import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../domain/entities/memory_seed.dart';
import '../providers/memory_seed_providers.dart';

class ArboretumPage extends ConsumerWidget {
  const ArboretumPage({super.key});

  static const routePath = '/arboretum';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedsState = ref.watch(completedMemorySeedsProvider);
    final colors = context.mameroom;

    return MameroomShell(
      showSparkles: false,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: seedsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(completedMemorySeedsProvider),
          ),
          data: (seeds) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: '내 방',
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primary),
                  ),
                  Expanded(
                    child: Text(
                      'Memory Arboretum',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              if (seeds.isEmpty)
                const _EmptyState()
              else
                ...seeds.map((seed) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SeedCollectionCard(seed: seed),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeedCollectionCard extends StatelessWidget {
  const _SeedCollectionCard({required this.seed});

  final MemorySeed seed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.primaryMist.withValues(alpha: 0.45),
              border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: PixelSeed(size: 48)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seed.seedTypeLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _MetaLine(label: 'seed_type', value: seed.seedType),
                _MetaLine(label: 'growth_stage', value: seed.growthStage),
                _MetaLine(label: 'completed_at', value: _formatDate(seed.completedAt)),
                _MetaLine(label: 'asset_key', value: seed.assetKey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 94,
            child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.muted)),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PixelSeed(size: 62),
          const SizedBox(height: 16),
          Text('완성된 기억씨앗이 아직 없어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '퀴즈를 마치고 씨앗이 완성되면 이곳에 컬렉션으로 모입니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PixelSeed(size: 58),
            const SizedBox(height: 16),
            Text('정원을 불러오지 못했어요', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
