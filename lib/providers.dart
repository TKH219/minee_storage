import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/network/dio_builder.dart';
import 'package:mine_storage/core/network/interceptors/auth_interceptor.dart';
import 'package:mine_storage/core/network/interceptors/unauthorized_interceptor.dart';
import 'package:mine_storage/core/storage/user_state_purger.dart';
import 'package:mine_storage/data/data_sources/remote/auth_data_source.dart';
import 'package:mine_storage/data/data_sources/remote/auth_data_source_impl.dart';
import 'package:mine_storage/data/data_sources/remote/post_api.dart';
import 'package:mine_storage/data/repositories/auth_repository_impl.dart';
import 'package:mine_storage/data/repositories/post_repository_impl.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/domain/repositories/post_repository.dart';
import 'package:mine_storage/.env/env.dart';
import 'package:mine_storage/shared/ui/app_snack.dart';

export 'package:mine_storage/shared/ui/app_snack.dart' show snackbarKey;

final userStatePurgerProvider = Provider<UserStatePurger>((ref) => UserStatePurger());

/// Supabase
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Watches the session, and is the one place a lost session is acted on.
///
/// Every way a session can end lands here — an explicit sign-out, a 401 from
/// the REST API, or a token refresh failing in the background with nothing in
/// flight — so the purge is written once and cannot be forgotten.
///
/// It routes back to splash rather than straight to sign-in: splash is the only
/// session gate, so sending the user through it keeps that rule in one place.
final authStateListenableProvider = Provider<ValueNotifier<bool>>((ref) {
  final notifier = ValueNotifier<bool>(
    ref.read(supabaseClientProvider).auth.currentSession != null,
  );
  final subscription = ref.watch(authRepositoryProvider).authStateChanges.listen((loggedIn) {
    notifier.value = loggedIn;
    if (!loggedIn) {
      ref.read(userStatePurgerProvider).purge();
      ref.read(routerProvider).goNamed(AppRoutes.splashName);
    }
  });

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
        onUnauthorized: () => ref.read(authRepositoryProvider).signOut(),
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
