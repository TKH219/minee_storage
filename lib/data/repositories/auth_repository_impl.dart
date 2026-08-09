import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/exceptions/supabase_error_mapper.dart';
import 'package:mine_storage/data/data_sources/remote/auth_data_source.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/shared/utils/logger.dart';

class AuthRepositoryImpl {
  AuthRepositoryImpl(this._dataSource);

  final AuthDataSource _dataSource;

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
