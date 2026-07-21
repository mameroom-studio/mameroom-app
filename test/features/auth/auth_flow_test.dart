import 'package:ai_memory_coach/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:ai_memory_coach/features/auth/presentation/pages/login_page.dart';
import 'package:ai_memory_coach/features/auth/presentation/pages/reset_password_page.dart';
import 'package:ai_memory_coach/features/auth/presentation/pages/signup_page.dart';
import 'package:ai_memory_coach/features/onboarding/presentation/pages/email_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  testWidgets('login renders auth design fields and toggles password', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const LoginPage()));
    expect(find.text('MAMEROOM'), findsOneWidget);
    expect(find.text('\uC774\uBA54\uC77C'), findsOneWidget);
    expect(find.text('\uBE44\uBC00\uBC88\uD638'), findsOneWidget);
    expect(find.text('Google\uB85C \uACC4\uC18D\uD558\uAE30'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('signup renders agreement and submit button', (tester) async {
    await tester.pumpWidget(_wrap(const SignupPage()));
    expect(find.text('\uD68C\uC6D0\uAC00\uC785'), findsWidgets);
    expect(find.text('\uB2C9\uB124\uC784'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(3));
    expect(find.text('[필수] 만 14세 이상입니다.'), findsOneWidget);
    expect(find.text('[필수] 이용약관에 동의합니다.'), findsOneWidget);
    expect(find.text('[필수] 개인정보처리방침에 동의합니다.'), findsOneWidget);
  });

  testWidgets('verification renders mail copy', (tester) async {
    await tester.pumpWidget(
      _wrap(const EmailVerificationPage(email: 'example@email.com')),
    );
    expect(
      find.text('\uC778\uC99D \uBA54\uC77C\uC744 \uBCF4\uB0C8\uC5B4\uC694!'),
      findsOneWidget,
    );
    expect(find.textContaining('example@email.com'), findsOneWidget);
  });

  testWidgets('forgot password renders email field', (tester) async {
    await tester.pumpWidget(_wrap(const ForgotPasswordPage()));
    expect(find.text('\uBE44\uBC00\uBC88\uD638 \uCC3E\uAE30'), findsOneWidget);
    expect(find.text('\uB9C1\uD06C \uBCF4\uB0B4\uAE30'), findsOneWidget);
  });

  testWidgets('reset password validates rules after input', (tester) async {
    await tester.pumpWidget(_wrap(const ResetPasswordPage()));
    await tester.enterText(find.byType(TextFormField).first, 'Pass123!');
    await tester.enterText(find.byType(TextFormField).last, 'Pass123!');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('\uBE44\uBC00\uBC88\uD638 \uBCC0\uACBD'), findsOneWidget);
    expect(
      find.text(
        '\uBE44\uBC00\uBC88\uD638\uAC00 \uC77C\uCE58\uD569\uB2C8\uB2E4',
      ),
      findsOneWidget,
    );
  });
}
