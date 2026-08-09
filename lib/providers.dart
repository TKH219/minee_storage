import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/network/dio_builder.dart';
import 'package:mine_storage/core/network/interceptors/auth_interceptor.dart';
import 'package:mine_storage/core/network/interceptors/unauthorized_interceptor.dart';
import 'package:mine_storage/data/data_sources/remote/auth_data_source.dart';
import 'package:mine_storage/data/data_sources/remote/post_api.dart';
import 'package:mine_storage/data/repositories/auth_repository_impl.dart';
import 'package:mine_storage/data/repositories/post_repository_impl.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/domain/repositories/post_repository.dart';
import 'package:mine_storage/.env/env.dart';

/// Global keys
final snackbarKey = GlobalKey<ScaffoldMessengerState>();

/// Supabase
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Bridges the auth stream into the Listenable go_router wants.
final authStateListenableProvider = Provider<ValueNotifier<bool>>((ref) {
  final notifier = ValueNotifier<bool>(
    ref.read(supabaseClientProvider).auth.currentSession != null,
  );
  final subscription = ref
      .watch(authRepositoryProvider)
      .authStateChanges
      .listen((loggedIn) => notifier.value = loggedIn);

  ref.onDispose(() {
    subscription.cancel();
    notifier.dispose();
  });
  return notifier;
});

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
  final dio = buildDio(
    baseUrl: Env.apiUrl,
    interceptors: (dio) => [
      AuthInterceptor(
        accessToken: () =>
            ref.read(supabaseClientProvider).auth.currentSession?.accessToken,
      ),
      UnauthorizedInterceptor(
        onUnauthorized: () async {
          await ref.read(authRepositoryProvider).signOut();
          ref.read(routerProvider).goNamed(AppRoutes.signInName);
        },
      ),
    ],
  );

  ref.onDispose(dio.close);
  return dio;
});

/// Data sources
final authDataSourceProvider = Provider<AuthDataSource>(
  (ref) => AuthDataSourceImpl(ref.watch(supabaseClientProvider)),
);

final postApiProvider = Provider<PostApi>(
  (ref) => PostApi(ref.watch(publicDioProvider)),
);

/// Repositories
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authDataSourceProvider)),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepositoryImpl(postApi: ref.watch(postApiProvider)),
);
