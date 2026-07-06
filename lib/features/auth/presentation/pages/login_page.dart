import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../home/presentation/pages/home_shell_page.dart';
import '../../../onboarding/presentation/pages/email_verification_page.dart';
import 'signup_page.dart';
import '../providers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const routePath = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthFormState>(authControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.infoMessage;
      if (message == null ||
          message == previous?.errorMessage ||
          message == previous?.infoMessage) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      ref.read(authControllerProvider.notifier).clearMessages();
    });

    final authFormState = ref.watch(authControllerProvider);
    final isLoading = authFormState.isLoading;
    final colors = context.mameroom;

    return MameroomShell(
      showSparkles: false,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 22),
              const PixelLogo(compact: true),
              const SizedBox(height: 22),
              Text(
                '로그인하고\n나만의 방을 만들어보세요!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              if (!Env.hasSupabaseConfig) ...[
                const _ConfigWarning(),
                const SizedBox(height: 16),
              ],
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
                label: '비밀번호',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: isLoading ? null : (value) => setState(() => _rememberMe = value ?? true),
                  ),
                  Expanded(
                    child: Text('로그인 상태 유지', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  TextButton(onPressed: isLoading ? null : () {}, child: const Text('비밀번호 찾기')),
                ],
              ),
              const SizedBox(height: 10),
              MameroomPrimaryButton(
                label: '로그인',
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('또는', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  Expanded(child: Divider(color: colors.line)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Google 로그인은 이후 단계에서 연결됩니다.')),
                          );
                        },
                  icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                  label: const Text('Google로 로그인'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('계정이 없으신가요?', style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: isLoading ? null : () => context.go(SignupPage.routePath),
                    child: const Text('회원가입'),
                  ),
                ],
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.go(Uri(path: EmailVerificationPage.routePath).toString()),
                child: const Text('이메일 인증 후 로그인해주세요'),
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

    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final result = await controller.signIn(email: email, password: password);
      if (!mounted || result != AuthSubmitResult.signedIn) {
        return;
      }
      context.go(HomeShellPage.homeRoutePath);
    } catch (_) {
      // Error state is exposed by authControllerProvider and shown by ref.listen.
    }
  }
}

class _ConfigWarning extends StatelessWidget {
  const _ConfigWarning();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Supabase 설정을 확인해주세요. .env에 SUPABASE_URL과 SUPABASE_PUBLISHABLE_KEY가 필요합니다.',
          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}

