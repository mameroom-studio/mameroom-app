import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_design_widgets.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  static const routePath = '/forgot-password';
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthDesignScaffold(
      leading: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: '\uB4A4\uB85C\uAC00\uAE30',
          onPressed: () => context.go(LoginPage.routePath),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: '\uBE44\uBC00\uBC88\uD638 \uCC3E\uAE30',
              subtitle: '',
              showLogoMark: false,
            ),
            const SizedBox(height: 24),
            const Text(
              '\uAC00\uC785\uD55C \uC774\uBA54\uC77C\uC744 \uC785\uB825\uD558\uBA74\n\uBE44\uBC00\uBC88\uD638 \uC7AC\uC124\uC815 \uB9C1\uD06C\uB97C \uBCF4\uB0B4\uB4DC\uB824\uC694.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AuthInputField(
              controller: _emailController,
              label: '\uC774\uBA54\uC77C',
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v ?? '').contains('@')
                  ? null
                  : '\uC774\uBA54\uC77C\uC744 \uD655\uC778\uD574\uC8FC\uC138\uC694.',
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: '\uB9C1\uD06C \uBCF4\uB0B4\uAE30',
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                context.go(ResetPasswordPage.routePath);
              },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go(LoginPage.routePath),
              child: const Text(
                '\uB85C\uADF8\uC778\uC73C\uB85C \uB3CC\uC544\uAC00\uAE30',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
