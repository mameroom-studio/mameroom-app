import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/mameroom_theme_extension.dart';
import '../../../../shared/widgets/mameroom_shell.dart';
import '../../../../shared/widgets/pixel_placeholders.dart';
import '../../../auth/presentation/pages/signup_page.dart';

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key, this.email});

  static const routePath = '/email-verification';

  final String? email;

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _maskEmail(email ?? 'mame****@gmail.com');
    final colors = context.mameroom;

    return MameroomShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.mail_outline, size: 76, color: colors.primarySoft),
              const Padding(
                padding: EdgeInsets.only(top: 58),
                child: PixelSeed(size: 48),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            '이메일 인증이 필요해요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '첫 가입 이메일로 인증 메일을 보냈어요.\n메일함을 확인하고 인증을 완료해주세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.paper,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(maskedEmail, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 18),
          MameroomPrimaryButton(
            label: '이메일 앱 열기',
            icon: Icons.open_in_new,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('메일 앱에서 인증 후 로그인해주세요.')),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            child: const Text('다시 보내기 (00:58)'),
          ),
          TextButton(
            onPressed: () => context.go(SignupPage.routePath),
            child: const Text('이메일 주소 변경'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  String _maskEmail(String value) {
    final parts = value.split('@');
    if (parts.length != 2 || parts.first.length < 2) {
      return value;
    }
    return '${parts.first.substring(0, 2)}****@${parts.last}';
  }
}

