import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analysis/presentation/pages/analysis_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/gamification/presentation/pages/room_page.dart';
import '../features/gamification/presentation/pages/shop_page.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/quiz/presentation/pages/quiz_page.dart';
import '../features/quiz/presentation/pages/quiz_result_page.dart';
import '../features/review/presentation/pages/review_page.dart';
import '../features/upload/presentation/pages/upload_page.dart';
import 'pages/splash_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: SplashPage.routePath,
    redirect: (context, state) {
      if (currentUser.isLoading) {
        return state.matchedLocation == SplashPage.routePath
            ? null
            : SplashPage.routePath;
      }

      final isAuthenticated = currentUser.asData?.value != null;
      final isOnSplash = state.matchedLocation == SplashPage.routePath;
      final isOnLogin = state.matchedLocation == LoginPage.routePath;

      if (!isAuthenticated) {
        return isOnLogin ? null : LoginPage.routePath;
      }

      if (isOnSplash || isOnLogin) {
        return LibraryPage.routePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: SplashPage.routePath,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: LoginPage.routePath,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: LibraryPage.routePath,
        builder: (context, state) => const LibraryPage(),
      ),
      GoRoute(
        path: UploadPage.routePath,
        builder: (context, state) => const UploadPage(),
      ),
      GoRoute(
        path: AnalysisPage.routePath,
        builder: (context, state) => AnalysisPage(
          materialId: state.uri.queryParameters['materialId'],
        ),
      ),
      GoRoute(
        path: QuizPage.routePath,
        builder: (context, state) => QuizPage(
          materialId: state.uri.queryParameters['materialId'],
        ),
      ),
      GoRoute(
        path: QuizResultPage.routePath,
        builder: (context, state) => const QuizResultPage(),
      ),
      GoRoute(
        path: ReviewPage.routePath,
        builder: (context, state) => const ReviewPage(),
      ),
      GoRoute(
        path: RoomPage.routePath,
        builder: (context, state) => const RoomPage(),
      ),
      GoRoute(
        path: ShopPage.routePath,
        builder: (context, state) => const ShopPage(),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Page not found')),
    ),
  );
});