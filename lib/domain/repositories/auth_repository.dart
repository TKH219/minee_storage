import 'package:mine_storage/domain/entities/entities.dart';

abstract class AuthRepository {
  /// Signs in and persists the resulting session to secure storage.
  Future<AuthenticationEntity> logIn({
    required String username,
    required String password,
  });

  /// Clears the local session. Best-effort on the server side — local state is
  /// always cleared even if the remote call fails.
  Future<void> logOut();

  Future<AuthenticationEntity?> currentSession();

  Future<bool> isLoggedIn();
}
