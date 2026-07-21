import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/pages/home_shell_page.dart';
import '../../../home/presentation/pages/privacy_policy_page.dart';
import '../../../home/presentation/pages/terms_of_service_page.dart';
import '../../../onboarding/presentation/pages/email_verification_page.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_design_widgets.dart';
import 'login_page.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});
  static const routePath = '/signup';
  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _ageConfirmed = false;
  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthFormState>(authControllerProvider, (p, n) {
      final m = n.errorMessage;
      if (m == null || m == p?.errorMessage) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      ref.read(authControllerProvider.notifier).clearMessages();
    });
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return AuthDesignScaffold(
      leading: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: '\uB4A4\uB85C\uAC00\uAE30',
          onPressed: isLoading ? null : () => context.go(LoginPage.routePath),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                title: '\uD68C\uC6D0\uAC00\uC785',
                subtitle: '',
                showLogoMark: false,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _emailController,
                enabled: !isLoading,
                label: '\uC774\uBA54\uC77C',
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
              ),
              const SizedBox(height: 10),
              AuthInputField(
                controller: _nicknameController,
                enabled: !isLoading,
                label: '\uB2C9\uB124\uC784',
                hint: '\uAE40\uB9C8\uBA54',
                textInputAction: TextInputAction.next,
                validator: _validateNickname,
              ),
              const SizedBox(height: 10),
              AuthInputField(
                controller: _passwordController,
                enabled: !isLoading,
                label: '\uBE44\uBC00\uBC88\uD638',
                obscureText: _obscurePassword,
                showVisibilityToggle: true,
                onVisibilityToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: _validatePassword,
              ),
              const SizedBox(height: 10),
              AuthInputField(
                controller: _confirmController,
                enabled: !isLoading,
                label: '\uBE44\uBC00\uBC88\uD638 \uD655\uC778',
                obscureText: _obscureConfirm,
                showVisibilityToggle: true,
                onVisibilityToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                textInputAction: TextInputAction.done,
                validator: (v) => v != _passwordController.text
                    ? '\uBE44\uBC00\uBC88\uD638\uAC00 \uC77C\uCE58\uD558\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4.'
                    : null,
              ),
              const SizedBox(height: 8),
              _RequiredConsent(
                key: const ValueKey('age-14-consent'),
                value: _ageConfirmed,
                label: '[필수] 만 14세 이상입니다.',
                enabled: !isLoading,
                onChanged: (value) => setState(() => _ageConfirmed = value),
              ),
              _RequiredConsent(
                key: const ValueKey('terms-consent'),
                value: _termsAgreed,
                label: '[필수] 이용약관에 동의합니다.',
                enabled: !isLoading,
                onChanged: (value) => setState(() => _termsAgreed = value),
                onOpenDocument: () =>
                    context.push(TermsOfServicePage.routePath),
              ),
              _RequiredConsent(
                key: const ValueKey('privacy-consent'),
                value: _privacyAgreed,
                label: '[필수] 개인정보처리방침에 동의합니다.',
                enabled: !isLoading,
                onChanged: (value) => setState(() => _privacyAgreed = value),
                onOpenDocument: () => context.push(PrivacyPolicyPage.routePath),
              ),
              const SizedBox(height: 10),
              AuthPrimaryButton(
                label: '\uD68C\uC6D0\uAC00\uC785',
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      '\uC774\uBBF8 \uACC4\uC815\uC774 \uC788\uC73C\uC2E0\uAC00\uC694?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go(LoginPage.routePath),
                    child: const Text('\uB85C\uADF8\uC778'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? v) {
    final e = v?.trim() ?? '';
    if (e.isEmpty) {
      return '\uC774\uBA54\uC77C\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }
    if (!e.contains('@')) {
      return '\uC62C\uBC14\uB978 \uC774\uBA54\uC77C\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }
    return null;
  }

  String? _validateNickname(String? v) {
    final n = v?.trim() ?? '';
    return n.length < 2 || n.length > 10
        ? '\uB2C9\uB124\uC784\uC740 2~10\uC790\uB85C \uC785\uB825\uD574\uC8FC\uC138\uC694.'
        : null;
  }

  String? _validatePassword(String? v) => (v ?? '').length < 8
      ? '\uBE44\uBC00\uBC88\uD638\uB294 8\uC790 \uC774\uC0C1\uC774\uC5B4\uC57C \uD569\uB2C8\uB2E4.'
      : null;
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_ageConfirmed || !_termsAgreed || !_privacyAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('만 14세 이상 확인과 필수 약관에 모두 동의해주세요.')),
      );
      return;
    }
    TextInput.finishAutofillContext();
    final email = _emailController.text.trim();
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: email,
            password: _passwordController.text,
            nickname: _nicknameController.text.trim(),
            age14ConfirmedAt: DateTime.now().toUtc(),
          );
      if (!mounted) {
        return;
      }
      if (result == AuthSubmitResult.emailConfirmationRequired) {
        context.go(
          Uri(
            path: EmailVerificationPage.routePath,
            queryParameters: {'email': email},
          ).toString(),
        );
        return;
      }
      context.go(HomeShellPage.homeRoutePath);
    } catch (_) {}
  }
}

class _RequiredConsent extends StatelessWidget {
  const _RequiredConsent({
    super.key,
    required this.value,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.onOpenDocument,
  });

  final bool value;
  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onOpenDocument;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Checkbox(
        value: value,
        onChanged: enabled ? (next) => onChanged(next ?? false) : null,
      ),
      Expanded(
        child: InkWell(
          onTap: enabled ? () => onChanged(!value) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ),
      if (onOpenDocument != null)
        TextButton(
          onPressed: enabled ? onOpenDocument : null,
          child: const Text('보기'),
        ),
    ],
  );
}
