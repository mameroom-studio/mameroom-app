import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/presentation/modals/mameroom_modals.dart';
import '../../../core/presentation/states/mameroom_state_view.dart';
import '../../../shared/design_system/tokens/mameroom_colors.dart';
import '../../../shared/design_system/tokens/mameroom_radius.dart';
import '../../../shared/design_system/tokens/mameroom_spacing.dart';
import '../domain/support_inquiry.dart';
import 'support_providers.dart';

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});
  static const routePath = '/settings/support';

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('문의하기'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: '문의 작성'),
          Tab(text: '문의 내역'),
        ],
      ),
    ),
    body: SafeArea(
      child: TabBarView(
        controller: _tabs,
        children: [
          _SupportForm(onShowHistory: () => _tabs.animateTo(1)),
          const _SupportHistory(),
        ],
      ),
    ),
  );
}

class _SupportForm extends ConsumerStatefulWidget {
  const _SupportForm({required this.onShowHistory});
  final VoidCallback onShowHistory;

  @override
  ConsumerState<_SupportForm> createState() => _SupportFormState();
}

class _SupportFormState extends ConsumerState<_SupportForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  SupportCategory? _category;
  bool _submitting = false;
  bool _submitted = false;

  bool get _dirty =>
      _category != null ||
      _title.text.trim().isNotEmpty ||
      _content.text.trim().isNotEmpty;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty || _submitted,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _confirmLeave();
    },
    child: LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(MameroomSpacing.md),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text(
                  '궁금한 점이나 불편한 사항을 알려 주세요.\n'
                  '확인 후 문의 내역을 통해 답변드리겠습니다.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MameroomSpacing.lg),
                DropdownButtonFormField<SupportCategory>(
                  key: const ValueKey('support-category'),
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: '문의 카테고리'),
                  items: [
                    for (final category in SupportCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _category = value),
                  validator: (value) => value == null ? '카테고리를 선택해 주세요.' : null,
                ),
                if (_category == SupportCategory.bugReport) ...[
                  const SizedBox(height: MameroomSpacing.sm),
                  const Text(
                    '어떤 화면에서 문제가 발생했나요?\n'
                    '어떤 동작을 했을 때 발생했나요?\n'
                    '같은 문제가 반복해서 발생하나요?',
                  ),
                ],
                const SizedBox(height: MameroomSpacing.md),
                TextFormField(
                  key: const ValueKey('support-title'),
                  controller: _title,
                  enabled: !_submitting,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '문의 제목',
                    hintText: '5자 이상 입력해 주세요',
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    return length < 5 || length > 80
                        ? '제목은 5~80자로 입력해 주세요.'
                        : null;
                  },
                ),
                const SizedBox(height: MameroomSpacing.sm),
                TextFormField(
                  key: const ValueKey('support-content'),
                  controller: _content,
                  enabled: !_submitting,
                  minLines: 7,
                  maxLines: 14,
                  maxLength: 2000,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: '문의 내용',
                    alignLabelWithHint: true,
                    hintText: '문제 상황과 발생 순서를 자세히 적어 주세요',
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    return length < 10 || length > 2000
                        ? '문의 내용은 10~2,000자로 입력해 주세요.'
                        : null;
                  },
                ),
                const SizedBox(height: MameroomSpacing.sm),
                const _InfoPanel(
                  text:
                      '파일 첨부는 지원하지 않습니다.\n'
                      '오류가 발생했다면 이용한 기능과 발생 순서를 자세히 적어 주세요.',
                ),
                const SizedBox(height: MameroomSpacing.sm),
                const _InfoPanel(
                  text: '문의 처리를 위해 앱 버전과 기기 환경 정보가 함께 전달될 수 있습니다.',
                ),
                const SizedBox(height: MameroomSpacing.lg),
                FilledButton(
                  key: const ValueKey('support-submit'),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('문의 보내기'),
                ),
                TextButton(
                  onPressed: widget.onShowHistory,
                  child: const Text('내 문의 내역'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    final environment = SupportEnvironment(
      appVersion: info.version,
      buildNumber: info.buildNumber,
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      locale: PlatformDispatcher.instance.locale.toLanguageTag(),
      currentRoute: GoRouterState.of(context).uri.toString(),
    );
    final result = await ref
        .read(supportRepositoryProvider)
        .create(
          category: _category!,
          title: _title.text,
          content: _content.text,
          environment: environment,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result != CreateSupportResultCode.success) {
      await MameroomPopupService.showInfo(
        context,
        title: '문의 접수 안내',
        message: result.userMessage,
      );
      return;
    }
    _submitted = true;
    _title.clear();
    _content.clear();
    setState(() => _category = null);
    ref.invalidate(supportInquiriesProvider);
    final showHistory = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('문의가 접수되었습니다'),
        content: const Text('문의 내역에서 처리 상태와 답변을 확인할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('확인'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('문의 내역 보기'),
          ),
        ],
      ),
    );
    _submitted = false;
    if (showHistory == true) widget.onShowHistory();
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('작성 중인 내용이 있습니다'),
        content: const Text('페이지를 나가면 입력한 내용이 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 작성'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }
}

class _SupportHistory extends ConsumerWidget {
  const _SupportHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportInquiriesProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(supportInquiriesProvider.future),
      child: state.when(
        loading: () => ListView(
          children: [
            SizedBox(height: 180),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (_, _) => ListView(
          children: [
            const SizedBox(height: 64),
            MameroomStateView(
              variant: MameroomStateVariant.error,
              title: '문의 내역을 불러오지 못했습니다',
              description: '네트워크 연결을 확인하고 다시 시도해 주세요.',
              primaryButtonText: '다시 시도',
              onPrimaryPressed: () => ref.invalidate(supportInquiriesProvider),
            ),
          ],
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: 64),
                MameroomStateView(
                  variant: MameroomStateVariant.empty,
                  title: '등록된 문의가 없습니다',
                  description: '문의 작성 탭에서 궁금한 내용을 보내 주세요.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(MameroomSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: MameroomSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  minVerticalPadding: MameroomSpacing.md,
                  title: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.category.label} · ${_date(item.createdAt)}'
                    '${item.reply == null ? '' : ' · 답변 완료'}',
                  ),
                  leading: _StatusBadge(status: item.status),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(SupportDetailPage.pathFor(item.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SupportDetailPage extends ConsumerWidget {
  const SupportDetailPage({super.key, required this.inquiryId});
  final String inquiryId;
  static const routePath = '/settings/support/:inquiryId';
  static String pathFor(String id) => '/settings/support/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportInquiryProvider(inquiryId));
    return Scaffold(
      appBar: AppBar(title: const Text('문의 상세')),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => MameroomStateView(
            variant: MameroomStateVariant.error,
            title: '문의를 불러오지 못했습니다',
            description: '잠시 후 다시 시도해 주세요.',
            primaryButtonText: '다시 시도',
            onPrimaryPressed: () =>
                ref.invalidate(supportInquiryProvider(inquiryId)),
          ),
          data: (item) {
            if (item == null) {
              return const MameroomStateView(
                variant: MameroomStateVariant.empty,
                title: '문의를 찾을 수 없습니다',
                description: '문의 내역에서 다시 확인해 주세요.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(MameroomSpacing.md),
              children: [
                Wrap(
                  spacing: MameroomSpacing.sm,
                  runSpacing: MameroomSpacing.xs,
                  children: [
                    _StatusBadge(status: item.status),
                    Chip(label: Text(item.category.label)),
                  ],
                ),
                const SizedBox(height: MameroomSpacing.md),
                Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                Text('접수일 ${_date(item.createdAt)}'),
                const Divider(height: MameroomSpacing.xl),
                SelectableText(item.content),
                const SizedBox(height: MameroomSpacing.xl),
                Text('운영자 답변', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: MameroomSpacing.sm),
                Card(
                  color: MameroomColors.surfaceMuted,
                  child: Padding(
                    padding: const EdgeInsets.all(MameroomSpacing.md),
                    child: item.reply == null
                        ? const Text('답변을 준비하고 있습니다.')
                        : SelectableText(item.reply!.content),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final SupportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SupportStatus.received => MameroomColors.info,
      SupportStatus.inReview => MameroomColors.warning,
      SupportStatus.answered => MameroomColors.success,
      SupportStatus.closed => MameroomColors.textMuted,
    };
    return Semantics(
      label: '문의 상태 ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(MameroomRadius.pill),
        ),
        child: Text(
          status.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(MameroomSpacing.sm),
    decoration: BoxDecoration(
      color: MameroomColors.surfaceMuted,
      borderRadius: BorderRadius.circular(MameroomRadius.medium),
    ),
    child: Text(text),
  );
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')}';
}
