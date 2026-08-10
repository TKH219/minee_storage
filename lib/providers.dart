import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/network/dio_builder.dart';
import 'package:mine_storage/core/network/interceptors/auth_interceptor.dart';
import 'package:mine_storage/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:mine_storage/data/data_sources/local/user_local_data_source.dart';
import 'package:mine_storage/data/data_sources/remote/auth_api.dart';
import 'package:mine_storage/data/data_sources/remote/post_api.dart';
import 'package:mine_storage/data/repositories/auth_repository_impl.dart';
import 'package:mine_storage/data/repositories/post_repository_impl.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/domain/repositories/post_repository.dart';
import 'package:mine_storage/.env/env.dart';

/// Global keys
final snackbarKey = GlobalKey<ScaffoldMessengerState>();

/// Network
///
/// Two Dio instances: [publicDioProvider] for anonymous endpoints (login,
/// refresh) and [authorizedDioProvider] for everything that needs a bearer
/// token. Keeping them apart is what stops the refresh call from recursing
/// through its own interceptor.
final publicDioProvider = Provider<Dio>((ref) {
  return buildDio(baseUrl: Env.apiUrl);
});

final authorizedDioProvider = Provider<Dio>((ref) {
  final userLocalDataSource = ref.watch(userLocalDataSourceProvider);

  final dio = buildDio(
    baseUrl: Env.apiUrl,
    interceptors: (dio) => [
      AuthInterceptor(userLocalDataSource: userLocalDataSource),
      RefreshTokenInterceptor(
        dio: dio,
        apiUrl: Env.apiUrl,
        userLocalDataSource: userLocalDataSource,
        onSessionExpired: () async {
          ref.read(routerProvider).goNamed(AppRoutes.loginName);
        },
      ),
    ],
  );

  ref.onDispose(dio.close);
  return dio;
});

/// Data sources
final userLocalDataSourceProvider = Provider<UserLocalDataSource>(
  (ref) => UserLocalDataSource(),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(publicDioProvider)),
);

final authorizedAuthApiProvider = Provider<AuthorizedAuthApi>(
  (ref) => AuthorizedAuthApi(ref.watch(authorizedDioProvider)),
);

final postApiProvider = Provider<PostApi>(
  (ref) => PostApi(ref.watch(publicDioProvider)),
);

/// Repositories
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    authApi: ref.watch(authApiProvider),
    authorizedAuthApi: ref.watch(authorizedAuthApiProvider),
    userLocalDataSource: ref.watch(userLocalDataSourceProvider),
  ),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepositoryImpl(postApi: ref.watch(postApiProvider)),
);
