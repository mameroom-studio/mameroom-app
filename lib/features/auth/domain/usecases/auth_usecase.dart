import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class AuthUseCase {
  const AuthUseCase(this.repository);

  final AuthRepository repository;

  AppUser? get currentUser => repository.currentUser;

  Stream<AppUser?> get authStateChanges => repository.authStateChanges;

  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) {
    return repository.signInWithEmail(email: email, password: password);
  }

  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return repository.signUpWithEmail(email: email, password: password);
  }

  Future<void> signOut() {
    return repository.signOut();
  }
}