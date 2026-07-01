import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/app_user.dart';
import 'auth_providers.dart';

enum AuthSubmitResult {
  signedIn,
  signedOut,
  emailConfirmationRequired,
}

class AuthFormState {
  const AuthFormState({
    required this.isLoading,
    this.errorMessage,
    this.infoMessage,
  });

  const AuthFormState.idle()
      : isLoading = false,
        errorMessage = null,
        infoMessage = null;

  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;

  AuthFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    bool clearMessages = false,
  }) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearMessages ? null : infoMessage ?? this.infoMessage,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthFormState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthFormState> {
  AuthController(this._ref) : super(const AuthFormState.idle());

  final Ref _ref;

  Future<AuthSubmitResult> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthFormState(isLoading: true);

    try {
      final AppUser? user = await _ref.read(authUseCaseProvider).signInWithEmail(
            email: email,
            password: password,
          );
      if (user == null) {
        throw StateError('Sign-in did not return a session.');
      }

      state = const AuthFormState.idle();
      return AuthSubmitResult.signedIn;
    } catch (error) {
      state = AuthFormState(
        isLoading: false,
        errorMessage: _messageFor(error),
      );
      rethrow;
    }
  }

  Future<AuthSubmitResult> signUp({
    required String email,
    required String password,
  }) async {
    state = const AuthFormState(isLoading: true);

    try {
      final AppUser? user = await _ref.read(authUseCaseProvider).signUpWithEmail(
            email: email,
            password: password,
          );

      if (user == null) {
        state = const AuthFormState(
          isLoading: false,
          infoMessage: 'Check your email to confirm sign-up.',
        );
        return AuthSubmitResult.emailConfirmationRequired;
      }

      state = const AuthFormState.idle();
      return AuthSubmitResult.signedIn;
    } catch (error) {
      state = AuthFormState(
        isLoading: false,
        errorMessage: _messageFor(error),
      );
      rethrow;
    }
  }

  Future<AuthSubmitResult> signOut() async {
    state = const AuthFormState(isLoading: true);

    try {
      await _ref.read(authUseCaseProvider).signOut();
      state = const AuthFormState.idle();
      return AuthSubmitResult.signedOut;
    } catch (error) {
      state = AuthFormState(
        isLoading: false,
        errorMessage: _messageFor(error),
      );
      rethrow;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }

  String _messageFor(Object error) {
    final message = error.toString();
    if (message.contains('Supabase is not configured')) {
      return 'Check SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in .env.';
    }
    if (message.contains('Sign-in did not return a session')) {
      return 'Sign-in failed. Please try again.';
    }

    return message.replaceFirst('Exception: ', '');
  }
}