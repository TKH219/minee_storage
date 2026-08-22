import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/exceptions/supabase_error_mapper.dart';
import 'package:mine_storage/data/data_sources/remote/auth_data_source.dart';
import 'package:mine_storage/data/data_sources/remote/user_profile_data_source.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/shared/utils/logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource, this._profiles);

  final AuthDataSource _dataSource;
  final UserProfileDataSource _profiles;

  @override
  Future<EmailStatus> checkEmail(String email) {
    return _guard(() async {
      final raw = await _profiles.emailStatus(_normalise(email));
      return switch (raw) {
        'unconfirmed' => EmailStatus.unconfirmed,
        'confirmed' => EmailStatus.confirmed,
        _ => EmailStatus.none,
      };
    });
  }

  @override
  Future<void> startSignUp({required String email, required String password}) {
    return _guard(() => _dataSource.signUp(email: _normalise(email), password: password));
  }

  @override
  Future<void> resendSignUpCode(String email) =>
      _guard(() => _dataSource.resendSignUpCode(_normalise(email)));

  @override
  Future<UserEntity> confirmSignUp({required String email, required String token}) {
    return _guard(() async {
      final userId = await _dataSource.verifySignUpCode(
        email: _normalise(email),
        token: token.trim(),
      );

      return _requireUser(userId);
    });
  }

  @override
  Future<UserEntity> signIn({required String email, required String password}) {
    return _guard(() async {
      final userId = await _dataSource.signInWithPassword(
        email: _normalise(email),
        password: password,
      );

      final user = await _requireUser(userId);

      // Deactivation only marks the row; the Supabase account stays valid and
      // still authenticates, so the refusal has to happen here.
      if (user.isDeactivated) {
        await _dataSource.signOut();
        throw const ForbiddenException(
          message: 'This account has been deactivated. Contact support to get it reopened.',
        );
      }

      try {
        await _profiles.touchLastSignedIn(userId);
      } on Object catch (e) {
        logger.w('Failed to stamp last_signed_in_at', error: e);
      }

      return user;
    });
  }

  @override
  Future<void> startPasswordReset(String email) =>
      _guard(() => _dataSource.sendPasswordResetCode(_normalise(email)));

  @override
  Future<void> verifyPasswordResetCode({
    required String email,
    required String token,
  }) {
    return _guard(
      () => _dataSource.verifyRecoveryCode(
        email: _normalise(email),
        token: token.trim(),
      ),
    );
  }

  @override
  Future<void> setNewPassword(String password) {
    return _guard(() async {
      await _dataSource.updatePassword(password);
      // verifyOTP(recovery) leaves the user signed in. The spec deliberately
      // discards that session and sends them back through sign-in.
      await _dataSource.signOut();
    });
  }

  @override
  Future<void> signOut() => _guard(() => _dataSource.signOut());

  @override
  Future<UserEntity> updateProfile({required String fullName, String? avatarUrl}) {
    return _guard(() async {
      final id = _requireSession();
      await _profiles.updateProfileRow(
        userId: id,
        fullName: fullName.trim(),
        avatarUrl: avatarUrl,
      );
      return _requireUser(id);
    });
  }

  @override
  Future<void> completeOnboarding() {
    return _guard(() => _profiles.stampOnboardingCompleted(_requireSession()));
  }

  @override
  Future<UserEntity?> currentUser() {
    return _guard(() async {
      final id = _dataSource.currentUserId;
      if (id == null) return null;
      final row = await _profiles.fetchUserRow(id);
      return row == null ? null : UserEntity.fromRow(row);
    });
  }

  @override
  Stream<bool> get authStateChanges => _dataSource.authStateChanges;

  String _requireSession() {
    final id = _dataSource.currentUserId;
    if (id == null) {
      throw const UnauthorizedException(
        message: 'Your session has expired. Please sign in again.',
      );
    }
    return id;
  }

  Future<UserEntity> _requireUser(String userId) async {
    final row = await _profiles.fetchUserRow(userId);
    if (row == null) {
      throw const ServerException(
        message: 'Your profile could not be loaded. Please try again.',
      );
    }
    return UserEntity.fromRow(row);
  }

  String _normalise(String email) => email.trim().toLowerCase();

  /// Single boundary where a Supabase failure becomes an [AppException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (e) {
      throw SupabaseErrorMapper.map(e);
    }
  }
}
