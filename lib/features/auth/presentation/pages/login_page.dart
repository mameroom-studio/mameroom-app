import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/pages/home_shell_page.dart';
import '../../../onboarding/presentation/pages/email_verification_page.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_design_widgets.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

const _email = '\uC774\uBA54\uC77C';
const _password = '\uBE44\uBC00\uBC88\uD638';
const _login = '\uB85C\uADF8\uC778';
const _remember = '\uB85C\uADF8\uC778 \uC0C1\uD0DC \uC720\uC9C0';
const _forgot = '\uBE44\uBC00\uBC88\uD638 \uCC3E\uAE30';
const _google = 'Google\uB85C \uACC4\uC18D\uD558\uAE30';
const _apple = 'Apple\uB85C \uACC4\uC18D\uD558\uAE30';
const _noAccount =
    '\uC544\uC9C1 \uACC4\uC815\uC774 \uC5C6\uC73C\uC2E0\uAC00\uC694?';
const _signup = '\uD68C\uC6D0\uAC00\uC785';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      ref.read(authControllerProvider.notifier).clearMessages();
    });
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return AuthDesignScaffold(
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const AuthHeader(),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _emailController,
                enabled: !isLoading,
                label: _email,
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              AuthInputField(
                controller: _passwordController,
                enabled: !isLoading,
                label: _password,
                hint:
                    '\uBE44\uBC00\uBC88\uD638\uB97C \uC785\uB825\uD574\uC8FC\uC138\uC694',
                obscureText: _obscurePassword,
                showVisibilityToggle: true,
                onVisibilityToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: _validatePassword,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: isLoading
                        ? null
                        : (value) =>
                              setState(() => _rememberMe = value ?? true),
                  ),
                  Expanded(
                    child: Text(
                      _remember,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go(ForgotPasswordPage.routePath),
                    child: const Text(_forgot),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AuthPrimaryButton(
                label: _login,
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              const AuthDivider(),
              const SizedBox(height: 14),
              AuthSocialButton(
                label: _google,
                mark: 'G',
                onPressed: isLoading ? null : _showSocialPending,
              ),
              const SizedBox(height: 8),
              AuthSocialButton(
                label: _apple,
                mark: '\uF8FF',
                onPressed: isLoading ? null : _showSocialPending,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _noAccount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go(SignupPage.routePath),
                    child: const Text(_signup),
                  ),
                ],
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.go(
                        Uri(path: EmailVerificationPage.routePath).toString(),
                      ),
                child: const Text(
                  '\uC774\uBA54\uC77C \uC778\uC99D \uD654\uBA74\uC73C\uB85C',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return '\uC774\uBA54\uC77C\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }
    if (!email.contains('@')) {
      return '\uC62C\uBC14\uB978 \uC774\uBA54\uC77C\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }
    return null;
  }

  String? _validatePassword(String? value) => (value ?? '').length < 6
      ? '\uBE44\uBC00\uBC88\uD638\uB294 6\uC790 \uC774\uC0C1\uC774\uC5B4\uC57C \uD569\uB2C8\uB2E4.'
      : null;
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted || result != AuthSubmitResult.signedIn) {
        return;
      }
      context.go(HomeShellPage.homeRoutePath);
    } catch (_) {}
  }

  void _showSocialPending() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'OAuth \uC5F0\uB3D9\uC740 \uAE30\uC874 \uB85C\uC9C1\uC744 \uC720\uC9C0\uD569\uB2C8\uB2E4.',
        ),
      ),
    );
  }
}
