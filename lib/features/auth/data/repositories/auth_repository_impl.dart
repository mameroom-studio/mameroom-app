import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({this.remoteDataSource});

  final AuthRemoteDataSource? remoteDataSource;

  @override
  AppUser? get currentUser {
    final user = remoteDataSource?.currentUser;
    if (user == null) {
      return null;
    }

    return AppUserModel.fromSupabaseUser(user);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    final dataSource = remoteDataSource;
    if (dataSource == null) {
      return Stream<AppUser?>.value(null);
    }

    return dataSource.authStateChanges.map((state) {
      final user = state.session?.user;
      if (user == null) {
        return null;
      }

      return AppUserModel.fromSupabaseUser(user);
    });
  }

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _requireDataSource.signInWithEmail(
      email: email,
      password: password,
    );
    final user = response.session?.user ?? response.user;
    if (user == null) {
      return null;
    }

    return AppUserModel.fromSupabaseUser(user);
  }

  @override
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final response = await _requireDataSource.signUpWithEmail(
      email: email,
      password: password,
      data: data,
    );
    final user = response.session?.user;
    if (user == null) {
      return null;
    }

    return AppUserModel.fromSupabaseUser(user);
  }

  @override
  Future<void> signOut() {
    return _requireDataSource.signOut();
  }

  AuthRemoteDataSource get _requireDataSource {
    final dataSource = remoteDataSource;
    if (dataSource == null) {
      throw StateError('Supabase is not configured. Check .env values.');
    }

    return dataSource;
  }
}
