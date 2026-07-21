import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/env.dart';
import '../features/analysis/presentation/pages/analysis_page.dart';
import '../features/achievements/presentation/pages/achievement_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/gamification/presentation/pages/room_page.dart';
import '../features/gamification/presentation/pages/shop_page.dart';
import '../features/friends/presentation/pages/friend_room_page.dart';
import '../features/friends/presentation/pages/friend_search_page.dart';
import '../features/home/presentation/pages/home_shell_page.dart';
import '../features/home/presentation/pages/learning_report_page.dart';
import '../features/home/presentation/pages/privacy_policy_page.dart';
import '../features/home/presentation/pages/terms_of_service_page.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/memory_seed/presentation/pages/arboretum_page.dart';
import '../features/notifications/presentation/pages/mameroom_notification_page.dart';
import '../features/notifications/presentation/pages/mameroom_notification_settings_page.dart';
import '../features/notices/presentation/notice_detail_page.dart';
import '../features/notices/presentation/notice_list_page.dart';
import '../features/onboarding/presentation/pages/creating_room_page.dart';
import '../features/onboarding/presentation/pages/email_verification_page.dart';
import '../features/onboarding/presentation/pages/memory_seed_selection_page.dart';
import '../features/onboarding/presentation/pages/welcome_page.dart';
import '../features/premium/presentation/pages/mameroom_paywall_page.dart';
import '../features/profile/presentation/edit_profile_page.dart';
import '../features/promotions/presentation/promotion_code_page.dart';
import '../features/settings/presentation/open_source_license_page.dart';
import '../features/settings/presentation/version_info_page.dart';
import '../features/support/presentation/support_page.dart';
import '../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../features/quiz/domain/entities/quiz_result_snapshot.dart';
import '../features/quiz/presentation/pages/quiz_page.dart';
import '../features/quiz/presentation/pages/quiz_result_page.dart';
import '../features/review/presentation/pages/review_page.dart';
import '../features/wrong_note/presentation/pages/wrong_note_page.dart';
import '../features/upload/presentation/pages/upload_page.dart';
import 'pages/splash_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);

  return GoRouter(
    initialLocation: SplashPage.routePath,
    redirect: (context, state) {
      if (currentUser.isLoading || hasSeenOnboarding.isLoading) {
        return state.matchedLocation == SplashPage.routePath
            ? null
            : SplashPage.routePath;
      }

      final isAuthenticated = currentUser.asData?.value != null;
      final onboardingSeen =
          !Env.shouldShowOnboarding ||
          (hasSeenOnboarding.asData?.value ?? false);
      final publicRoutes = <String>{
        SplashPage.routePath,
        WelcomePage.routePath,
        LoginPage.routePath,
        SignupPage.routePath,
        ForgotPasswordPage.routePath,
        ResetPasswordPage.routePath,
        EmailVerificationPage.routePath,
        TermsOfServicePage.routePath,
        PrivacyPolicyPage.routePath,
        MemorySeedSelectionPage.routePath,
        CreatingRoomPage.routePath,
      };
      final location = state.matchedLocation;
      final isPublicRoute = publicRoutes.contains(location);
      final isOnboardingReplay =
          Env.shouldShowOnboarding &&
          location == WelcomePage.routePath &&
          state.uri.queryParameters['replay'] == 'true';

      if (!isAuthenticated) {
        if (location == SplashPage.routePath) {
          return onboardingSeen ? LoginPage.routePath : WelcomePage.routePath;
        }
        if (location == WelcomePage.routePath &&
            onboardingSeen &&
            !isOnboardingReplay) {
          return LoginPage.routePath;
        }
        return isPublicRoute ? null : LoginPage.routePath;
      }

      if (!onboardingSeen) {
        return location == WelcomePage.routePath ? null : WelcomePage.routePath;
      }

      if (isOnboardingReplay) {
        return null;
      }

      if (location == SplashPage.routePath ||
          location == WelcomePage.routePath ||
          location == LoginPage.routePath ||
          location == SignupPage.routePath ||
          location == EmailVerificationPage.routePath) {
        return HomeShellPage.homeRoutePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: SplashPage.routePath,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: WelcomePage.routePath,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: LoginPage.routePath,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: SignupPage.routePath,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: ForgotPasswordPage.routePath,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: ResetPasswordPage.routePath,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: EmailVerificationPage.routePath,
        builder: (context, state) =>
            EmailVerificationPage(email: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: MemorySeedSelectionPage.routePath,
        builder: (context, state) => const MemorySeedSelectionPage(),
      ),
      GoRoute(
        path: CreatingRoomPage.routePath,
        builder: (context, state) => const CreatingRoomPage(),
      ),
      GoRoute(
        path: HomeShellPage.homeRoutePath,
        builder: (context, state) => const HomeTabRoute(),
      ),
      GoRoute(
        path: HomeShellPage.studyRoutePath,
        builder: (context, state) => const StudyTabRoute(),
      ),
      GoRoute(
        path: HomeShellPage.rankRoutePath,
        builder: (context, state) => const RankTabRoute(),
      ),
      GoRoute(
        path: HomeShellPage.myInfoRoutePath,
        builder: (context, state) => const MyInfoTabRoute(),
      ),
      GoRoute(
        path: LibraryPage.routePath,
        builder: (context, state) => const StudyTabRoute(),
      ),
      GoRoute(
        path: LearningReportPage.routePath,
        builder: (context, state) => const LearningReportPage(),
      ),
      GoRoute(
        path: AchievementPage.routePath,
        builder: (context, state) => const AchievementPage(),
      ),
      GoRoute(
        path: '${AchievementDetailPage.routePrefix}/:code',
        builder: (context, state) =>
            AchievementDetailPage(code: state.pathParameters['code'] ?? ''),
      ),
      GoRoute(
        path: TermsOfServicePage.routePath,
        builder: (context, state) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: PrivacyPolicyPage.routePath,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: MameroomPaywallPage.routePath,
        builder: (context, state) => MameroomPaywallPage(
          entryPoint: paywallEntryPointFromString(
            state.uri.queryParameters['entry'],
          ),
          initialPreviewStatus: premiumStatusFromString(
            state.uri.queryParameters['status'],
          ),
        ),
      ),
      GoRoute(
        path: MameroomNotificationPage.routePath,
        builder: (context, state) => const MameroomNotificationPage(),
      ),
      GoRoute(
        path: MameroomNotificationSettingsPage.routePath,
        builder: (context, state) => const MameroomNotificationSettingsPage(),
      ),
      GoRoute(
        path: PromotionCodePage.routePath,
        builder: (context, state) => const PromotionCodePage(),
      ),
      GoRoute(
        path: NoticeListPage.routePath,
        builder: (context, state) => const NoticeListPage(),
      ),
      GoRoute(
        path: NoticeDetailPage.routePath,
        builder: (context, state) =>
            NoticeDetailPage(noticeId: state.pathParameters['noticeId'] ?? ''),
      ),
      GoRoute(
        path: VersionInfoPage.routePath,
        builder: (context, state) => const VersionInfoPage(),
      ),
      GoRoute(
        path: OpenSourceLicensePage.routePath,
        builder: (context, state) => const OpenSourceLicensePage(),
      ),
      GoRoute(
        path: SupportPage.routePath,
        builder: (context, state) => const SupportPage(),
      ),
      GoRoute(
        path: SupportDetailPage.routePath,
        builder: (context, state) => SupportDetailPage(
          inquiryId: state.pathParameters['inquiryId'] ?? '',
        ),
      ),
      GoRoute(
        path: EditProfilePage.routePath,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: UploadPage.routePath,
        builder: (context, state) => UploadPage(
          initialMode: MaterialInputMode.fromValue(
            state.uri.queryParameters['source'],
          ),
        ),
      ),
      GoRoute(
        path: AnalysisPage.routePath,
        builder: (context, state) =>
            AnalysisPage(materialId: state.uri.queryParameters['materialId']),
      ),
      GoRoute(
        path: QuizPage.routePath,
        builder: (context, state) => QuizPage(
          materialId: state.uri.queryParameters['materialId'],
          unlearnedOnly: state.uri.queryParameters['unlearnedOnly'] == 'true',
        ),
      ),
      GoRoute(
        path: QuizResultPage.routePath,
        builder: (context, state) => QuizResultPage(
          snapshot: state.extra is QuizResultSnapshot
              ? state.extra! as QuizResultSnapshot
              : null,
        ),
      ),
      GoRoute(
        path: FriendSearchPage.routePath,
        builder: (context, state) => const FriendSearchPage(),
      ),
      GoRoute(
        path: FriendRoomPage.routePath,
        builder: (context, state) => FriendRoomPage(
          friendId: state.pathParameters['friendId'] ?? '',
          nicknameHint: state.uri.queryParameters['nickname'] ?? '',
        ),
      ),
      GoRoute(
        path: ReviewPage.routePath,
        builder: (context, state) => const ReviewPage(),
      ),
      GoRoute(
        path: WrongNotePage.routePath,
        builder: (context, state) => const WrongNotePage(),
      ),
      GoRoute(
        path: RoomPage.routePath,
        builder: (context, state) => const RoomPage(),
      ),
      GoRoute(
        path: ShopPage.routePath,
        builder: (context, state) => const ShopPage(),
      ),
      GoRoute(
        path: ArboretumPage.routePath,
        builder: (context, state) => const ArboretumPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
});
