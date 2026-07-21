import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/widgets/auth_design_widgets.dart';

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key, this.email});
  static const routePath = '/email-verification';
  final String? email;
  @override
  Widget build(BuildContext context) {
    final shown = email ?? 'example@email.com';
    return AuthDesignScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const AuthHeader(
            title: '\uC774\uBA54\uC77C \uC778\uC99D',
            subtitle: '',
            showLogoMark: false,
          ),
          const SizedBox(height: 16),
          const AuthIllustration(icon: Icons.mark_email_unread_outlined),
          const SizedBox(height: 16),
          Text(
            '\uC778\uC99D \uBA54\uC77C\uC744 \uBCF4\uB0C8\uC5B4\uC694!',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            '$shown\uC73C\uB85C\n\uC778\uC99D \uBA54\uC77C\uC744 \uBC1C\uC1A1\uD588\uC5B4\uC694.\n\uBA54\uC77C\uD568\uC744 \uD655\uC778\uD558\uACE0 \uC778\uC99D\uC744 \uC644\uB8CC\uD574\uC8FC\uC138\uC694.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AuthPrimaryButton(
            label: '\uC774\uBA54\uC77C \uD655\uC778\uD558\uAE30',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '\uBA54\uC77C \uC571\uC5D0\uC11C \uC778\uC99D \uD6C4 \uB85C\uADF8\uC778\uD574\uC8FC\uC138\uC694.',
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go(LoginPage.routePath),
            child: const Text(
              '\uB85C\uADF8\uC778\uC73C\uB85C \uB3CC\uC544\uAC00\uAE30',
            ),
          ),
          const Text('\uC7AC\uBC1C\uC1A1 (59s)', textAlign: TextAlign.center),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
