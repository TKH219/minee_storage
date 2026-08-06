import 'package:dio/dio.dart';

import 'package:mine_storage/data/data_sources/local/user_local_data_source.dart';

/// Attaches the stored bearer token to every outgoing request.
///
/// Endpoints that must stay anonymous (login, refresh) go through the public
/// Dio instance, which does not install this interceptor.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.userLocalDataSource});

  final UserLocalDataSource userLocalDataSource;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final auth = await userLocalDataSource.getAppAuth();
    if (auth != null && auth.accessToken.isNotEmpty) {
      options.headers['Authorization'] = auth.accessTokenHeader;
    }
    handler.next(options);
  }
}
