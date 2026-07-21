import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_design_widgets.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  static const routePath = '/reset-password';
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _len => _passwordController.text.length >= 8;
  bool get _letter => RegExp(r'[A-Za-z]').hasMatch(_passwordController.text);
  bool get _number => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _special =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(_passwordController.text);
  bool get _match =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmController.text;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: '\uBE44\uBC00\uBC88\uD638 \uC7AC\uC124\uC815',
            subtitle: '',
            showLogoMark: false,
          ),
          const SizedBox(height: 24),
          AuthInputField(
            controller: _passwordController,
            label: '\uC0C8 \uBE44\uBC00\uBC88\uD638',
            obscureText: _obscurePassword,
            showVisibilityToggle: true,
            onVisibilityToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onFieldSubmitted: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AuthInputField(
            controller: _confirmController,
            label: '\uC0C8 \uBE44\uBC00\uBC88\uD638 \uD655\uC778',
            obscureText: _obscureConfirm,
            showVisibilityToggle: true,
            onVisibilityToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            onFieldSubmitted: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          ValidationLine(valid: _len, text: '8\uC790 \uC774\uC0C1'),
          ValidationLine(valid: _letter, text: '\uC601\uBB38 \uD3EC\uD568'),
          ValidationLine(valid: _number, text: '\uC22B\uC790 \uD3EC\uD568'),
          ValidationLine(
            valid: _special,
            text: '\uD2B9\uC218\uBB38\uC790 \uD3EC\uD568',
          ),
          ValidationLine(
            valid: _match,
            text:
                '\uBE44\uBC00\uBC88\uD638\uAC00 \uC77C\uCE58\uD569\uB2C8\uB2E4',
          ),
          const SizedBox(height: 16),
          AuthPrimaryButton(
            label: '\uBE44\uBC00\uBC88\uD638 \uBCC0\uACBD',
            onPressed: _len && _letter && _number && _special && _match
                ? () => context.go(LoginPage.routePath)
                : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
