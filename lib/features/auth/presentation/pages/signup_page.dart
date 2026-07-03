import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../onboarding/presentation/pages/email_verification_page.dart';
import 'login_page.dart';
import '../providers/auth_controller.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  static const routePath = '/signup';

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _agreed = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthFormState>(authControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message == previous?.errorMessage) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      ref.read(authControllerProvider.notifier).clearMessages();
    });

    final authFormState = ref.watch(authControllerProvider);
    final isLoading = authFormState.isLoading;

    return MameroomShell(
      showSparkles: false,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: '뒤로가기',
                  onPressed: isLoading ? null : () => context.go(LoginPage.routePath),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Text('회원가입', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                '마메룸의 새로운 시작이에요 🌱',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              MameroomTextField(
                controller: _emailController,
                enabled: !isLoading,
                label: '이메일',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return '이메일을 입력해주세요.';
                  }
                  if (!email.contains('@')) {
                    return '올바른 이메일을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              MameroomTextField(
                controller: _passwordController,
                enabled: !isLoading,
                label: '비밀번호 (8자 이상)',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
                validator: (value) => (value ?? '').length < 8 ? '비밀번호는 8자 이상이어야 합니다.' : null,
              ),
              const SizedBox(height: 14),
              MameroomTextField(
                controller: _confirmController,
                enabled: !isLoading,
                label: '비밀번호 확인',
                icon: Icons.visibility_off_outlined,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  tooltip: _obscureConfirm ? '비밀번호 보기' : '비밀번호 숨기기',
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
                validator: (value) => value != _passwordController.text ? '비밀번호가 일치하지 않습니다.' : null,
              ),
              const SizedBox(height: 14),
              MameroomTextField(
                controller: _nicknameController,
                enabled: !isLoading,
                label: '닉네임 (2~10자)',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  final nickname = value?.trim() ?? '';
                  if (nickname.length < 2 || nickname.length > 10) {
                    return '닉네임은 2~10자로 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CheckboxListTile(
                value: _agreed,
                onChanged: isLoading ? null : (value) => setState(() => _agreed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text('이용약관 및 개인정보처리방침에 동의합니다.', style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 18),
              MameroomPrimaryButton(label: '회원가입', isLoading: isLoading, onPressed: _submit),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('이미 계정이 있으신가요?', style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(onPressed: isLoading ? null : () => context.go(LoginPage.routePath), child: const Text('로그인')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('약관에 동의해주세요.')));
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      final result = await ref.read(authControllerProvider.notifier).signUp(email: email, password: password);
      if (!mounted) {
        return;
      }
      if (result == AuthSubmitResult.emailConfirmationRequired) {
        _emailController.clear();
        _passwordController.clear();
        _confirmController.clear();
        _nicknameController.clear();
        setState(() => _agreed = false);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('인증 메일을 발송했습니다.'),
            content: const Text('메일함에서 인증을 완료한 후 로그인해주세요.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
            ],
          ),
        );
        if (mounted) {
          context.go(Uri(path: EmailVerificationPage.routePath, queryParameters: {'email': email}).toString());
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이메일 인증 후 로그인해주세요')));
        }
        return;
      }
      context.go(LibraryPage.routePath);
    } catch (_) {
      // Error state is exposed by authControllerProvider and shown by ref.listen.
    }
  }
}
