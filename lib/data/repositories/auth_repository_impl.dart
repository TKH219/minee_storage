import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/data_sources/local/user_local_data_source.dart';
import 'package:mine_storage/data/data_sources/remote/auth_api.dart';
import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/shared/utils/logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.authApi,
    required this.authorizedAuthApi,
    required this.userLocalDataSource,
  });

  final AuthApi authApi;
  final AuthorizedAuthApi authorizedAuthApi;
  final UserLocalDataSource userLocalDataSource;

  @override
  Future<AuthenticationEntity> logIn({
    required String username,
    required String password,
  }) async {
    final response = await authApi.login(
      LoginRequest(username: username, password: password),
    );

    final payload = response.data;
    if (payload == null) {
      throw const ServerException(message: 'Login succeeded but returned no session.');
    }

    final entity = payload.toEntity();
    await userLocalDataSource.saveAuthenticationEntity(entity);
    return entity;
  }

  @override
  Future<void> logOut() async {
    try {
      await authorizedAuthApi.logout();
    } on Object catch (e) {
      // Never trap the user in a signed-in state because the server is down.
      logger.w('Remote logout failed, clearing local session anyway', error: e);
    } finally {
      await userLocalDataSource.logout();
    }
  }

  @override
  Future<AuthenticationEntity?> currentSession() => userLocalDataSource.getAppAuth();

  @override
  Future<bool> isLoggedIn() => userLocalDataSource.hasSession();
}
