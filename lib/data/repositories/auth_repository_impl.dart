import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/exceptions/supabase_error_mapper.dart';
import 'package:mine_storage/data/data_sources/remote/auth_data_source.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/shared/utils/logger.dart';

class AuthRepositoryImpl {
  AuthRepositoryImpl(this._dataSource);

  final AuthDataSource _dataSource;

  Future<EmailStatus> checkEmail(String email) {
    return _guard(() async {
      final raw = await _dataSource.emailStatus(_normalise(email));
      return switch (raw) {
        'unconfirmed' => EmailStatus.unconfirmed,
        'confirmed' => EmailStatus.confirmed,
        _ => EmailStatus.none,
      };
    });
  }

  Future<void> startSignUp({
    required String email,
    required String password,
    required String shopName,
  }) {
    return _guard(
      () => _dataSource.signUp(
        email: _normalise(email),
        password: password,
        shopName: shopName.trim(),
      ),
    );
  }

  Future<void> resendSignUpCode(String email) =>
      _guard(() => _dataSource.resendSignUpCode(_normalise(email)));

  Future<UserEntity> confirmSignUp({
    required String email,
    required String token,
    required String shopName,
    required bool wasResumed,
  }) {
    return _guard(() async {
      final userId = await _dataSource.verifySignUpCode(
        email: _normalise(email),
        token: token.trim(),
      );

      // The trigger read raw_user_meta_data from the *first* attempt, so a
      // resumed signup would otherwise silently discard the name just typed.
      if (wasResumed) {
        await _dataSource.updateShopName(userId: userId, shopName: shopName.trim());
      }

      final user = await _requireUser(userId);
      return wasResumed ? _withShopName(user, shopName.trim()) : user;
    });
  }

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
          message: 'This account has been deactivated. Please contact us for support.',
        );
      }

      try {
        await _dataSource.touchLastSignedIn(userId);
      } on Object catch (e) {
        logger.w('Failed to stamp last_signed_in_at', error: e);
      }

      return user;
    });
  }

  Future<void> signOut() => _guard(() => _dataSource.signOut());

  Future<UserEntity?> currentUser() {
    return _guard(() async {
      final id = _dataSource.currentUserId;
      if (id == null) return null;
      final row = await _dataSource.fetchUserRow(id);
      return row == null ? null : UserEntity.fromRow(row);
    });
  }

  Stream<bool> get authStateChanges => _dataSource.authStateChanges;

  Future<UserEntity> _requireUser(String userId) async {
    final row = await _dataSource.fetchUserRow(userId);
    if (row == null) {
      throw const ServerException(
        message: 'Your profile could not be loaded. Please try again.',
      );
    }
    return UserEntity.fromRow(row);
  }

  UserEntity _withShopName(UserEntity user, String shopName) => UserEntity(
    id: user.id,
    email: user.email,
    shopName: shopName,
    isDeactivated: user.isDeactivated,
    lastSignedInAt: user.lastSignedInAt,
  );

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
