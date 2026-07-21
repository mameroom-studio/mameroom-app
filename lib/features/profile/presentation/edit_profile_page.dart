import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/modals/mameroom_modals.dart';
import '../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../shared/widgets/mameroom_shell.dart';
import '../domain/profile_edit_snapshot.dart';
import '../domain/profile_failure.dart';
import 'profile_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});
  static const routePath = '/profile/edit';

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _bio = TextEditingController();
  final _goal = TextEditingController();
  ProfileEditSnapshot? _source;
  String? _treeId;
  String? _badgeId;
  bool _saving = false;

  @override
  void dispose() {
    _nickname.dispose();
    _bio.dispose();
    _goal.dispose();
    super.dispose();
  }

  void _hydrate(ProfileEditSnapshot value) {
    if (_source != null) return;
    _source = value;
    _nickname.text = value.nickname;
    _bio.text = value.bio;
    _goal.text = value.todayGoal;
    _treeId = value.featuredTreeId;
    _badgeId = value.featuredBadgeId;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileEditProvider);
    return MameroomShell(
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  _Header(onBack: () => context.pop()),
                  Expanded(
                    child: state.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _LoadError(
                        error: error,
                        onRetry: () => ref.invalidate(profileEditProvider),
                      ),
                      data: (snapshot) {
                        _hydrate(snapshot);
                        return Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: EdgeInsets.fromLTRB(
                                    constraints.maxWidth < 380 ? 14 : 20,
                                    8,
                                    constraints.maxWidth < 380 ? 14 : 20,
                                    120,
                                  ),
                                  children: [
                                    _CharacterPreview(
                                      onTap: () =>
                                          MameroomPopupService.showInfo(
                                            context,
                                            title: '캐릭터 변경',
                                            message: '준비 중인 기능입니다.',
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    _Field(
                                      key: const ValueKey('profile-nickname'),
                                      controller: _nickname,
                                      label: '닉네임',
                                      maxLength: 30,
                                      validator: _validateNickname,
                                    ),
                                    const SizedBox(height: 12),
                                    _Field(
                                      key: const ValueKey('profile-bio'),
                                      controller: _bio,
                                      label: '자기소개',
                                      maxLength: 80,
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 12),
                                    _Field(
                                      key: const ValueKey('profile-goal'),
                                      controller: _goal,
                                      label: '오늘의 목표',
                                      maxLength: 50,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 20),
                                    _ChoiceField(
                                      label: '대표 기억나무',
                                      value: _treeId,
                                      choices: snapshot.trees,
                                      emptyText: '완성한 기억나무가 없습니다.',
                                      onChanged: (value) =>
                                          setState(() => _treeId = value),
                                    ),
                                    const SizedBox(height: 12),
                                    _ChoiceField(
                                      label: '대표 Badge',
                                      value: _badgeId,
                                      choices: snapshot.badges,
                                      emptyText: '획득한 Badge가 없습니다.',
                                      onChanged: (value) =>
                                          setState(() => _badgeId = value),
                                    ),
                                  ],
                                ),
                              ),
                              _Actions(
                                saving: _saving,
                                onCancel: () => context.pop(),
                                onSave: _save,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateNickname(String? raw) {
    final value = (raw ?? '').trim();
    if (value.length < 2 || value.length > 30) {
      return '닉네임은 2~30자로 입력해 주세요.';
    }
    if (!RegExp(r'^[가-힣A-Za-z0-9 ]+$').hasMatch(value)) {
      return '한글, 영문, 숫자, 공백만 사용할 수 있어요.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _source == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .save(
            nickname: _nickname.text,
            bio: _bio.text,
            todayGoal: _goal.text,
            expectedUpdatedAt: _source!.updatedAt,
            featuredTreeId: _treeId,
            featuredBadgeId: _badgeId,
          );
      ref.invalidate(profileEditProvider);
      if (!mounted) return;
      await MameroomPopupService.showSuccess(
        context,
        title: '저장 완료',
        message: '프로필이 저장되었습니다.',
      );
      if (mounted) context.pop(true);
    } on ProfileFailure catch (error) {
      if (mounted) {
        await MameroomPopupService.showError(
          context,
          title: '저장할 수 없어요',
          message: error.userMessage,
        );
      }
    } catch (_) {
      if (mounted) {
        await MameroomPopupService.showError(
          context,
          title: '저장할 수 없어요',
          message: '프로필을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Row(
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        const Expanded(
          child: Text(
            '프로필 수정',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );
}

class _CharacterPreview extends StatelessWidget {
  const _CharacterPreview({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('character-preview'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.mameroom.paper,
        border: Border.all(color: context.mameroom.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 34, child: Icon(Icons.face_rounded, size: 42)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('현재 캐릭터', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('읽기 전용 Preview · 변경 기능 준비 중'),
              ],
            ),
          ),
          Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.label,
    required this.maxLength,
    this.maxLines = 1,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final int maxLength;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLength: maxLength,
    maxLines: maxLines,
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
  );
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.choices,
    required this.emptyText,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<ProfileChoice> choices;
  final String emptyText;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(emptyText),
      );
    }
    return DropdownButtonFormField<String?>(
      initialValue: choices.any((item) => item.id == value) ? value : null,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('선택 안 함')),
        ...choices.map(
          (item) => DropdownMenuItem(
            value: item.id,
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: BoxDecoration(
      color: context.mameroom.paper,
      border: Border(top: BorderSide(color: context.mameroom.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: saving ? null : onCancel,
            child: const Text('취소'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: const ValueKey('profile-save'),
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is ProfileFailure
        ? (error as ProfileFailure).userMessage
        : '프로필을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('profile-retry'),
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
