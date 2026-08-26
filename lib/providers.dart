import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/network/dio_builder.dart';
import 'package:mine_storage/core/network/interceptors/unauthorized_interceptor.dart';
import 'package:mine_storage/core/storage/user_state_purger.dart';
import 'package:mine_storage/data/data_sources/remote/store_data_source.dart';
import 'package:mine_storage/data/data_sources/remote/store_data_source_impl.dart';
import 'package:mine_storage/data/repositories/supabase_store_repository_impl.dart';
import 'package:mine_storage/data/data_sources/remote/storage_data_source.dart';
import 'package:mine_storage/data/data_sources/remote/storage_data_source_impl.dart';
import 'package:mine_storage/data/repositories/media_repository_impl.dart';
import 'package:mine_storage/domain/repositories/media_repository.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/core/network/interceptors/supabase_rest_interceptor.dart';
import 'package:mine_storage/data/data_sources/remote/user_profile_data_source.dart';
import 'package:mine_storage/data/data_sources/remote/user_profile_data_source_impl.dart';
import 'package:mine_storage/data/data_sources/remote/store_api.dart';
import 'package:mine_storage/data/data_sources/remote/user_api.dart';
import 'package:mine_storage/data/data_sources/remote/auth_data_source.dart';
import 'package:mine_storage/data/data_sources/remote/auth_data_source_impl.dart';
import 'package:mine_storage/data/data_sources/remote/post_api.dart';
import 'package:mine_storage/data/repositories/auth_repository_impl.dart';
import 'package:mine_storage/data/repositories/post_repository_impl.dart';
import 'package:mine_storage/data/data_sources/remote/product_api.dart';
import 'package:mine_storage/data/data_sources/remote/transaction_api.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/data/repositories/product_repository_impl.dart';
import 'package:mine_storage/data/repositories/transaction_repository_impl.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';
import 'package:mine_storage/domain/repositories/sale_repository.dart';
import 'package:mine_storage/domain/repositories/store_overview_repository.dart';
import 'package:mine_storage/domain/repositories/store_repository.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/domain/repositories/post_repository.dart';
import 'package:mine_storage/app/config/app_features.dart';
import 'package:mine_storage/app/env/env.dart';

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
      // PostgREST and Storage both want `apikey` alongside the bearer.
      SupabaseRestInterceptor(
        anonKey: Env.anonKey,
        accessToken: () =>
            ref.read(supabaseClientProvider).auth.currentSession?.accessToken,
      ),
      // Drops the session straight through GoTrue rather than the repository:
      // the repository reaches back into this Dio for its table calls, and
      // routing through it would make the two mutually dependent.
      UnauthorizedInterceptor(
        onUnauthorized: () => ref.read(supabaseClientProvider).auth.signOut(),
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
  (ref) => AuthRepositoryImpl(
    ref.watch(authDataSourceProvider),
    ref.watch(userProfileDataSourceProvider),
  ),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepositoryImpl(postApi: ref.watch(postApiProvider)),
);

/// The contract's paths live under the Edge Functions, while PostgREST and
/// Storage live at the project root — so the base URL is overridden here rather
/// than on the shared Dio, which [storeApiProvider] and [storageDataSourceProvider]
/// also use.
final functionsBaseUrlProvider = Provider<String>(
  (ref) => '${Env.apiUrl.replaceAll(RegExp(r'/+$'), '')}/functions/v1',
);

final productApiProvider = Provider<ProductApi>(
  (ref) => ProductApi(
    ref.watch(authorizedDioProvider),
    baseUrl: ref.watch(functionsBaseUrlProvider),
  ),
);

/// The only place that knows whether products come from a backend.
///
/// [ProductRepositoryImpl] is complete but has no tables behind it yet, so the
/// in-memory stand-in is what the app actually runs on — see
/// [AppFeatures.fakeProductsEnabled].
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  if (AppFeatures.fakeProductsEnabled) return FakeProductRepository();
  return ProductRepositoryImpl(productApi: ref.watch(productApiProvider));
});

/// Sales run entirely in memory until the transaction ledger lands. It draws
/// stock through [productRepositoryProvider] rather than a copy of its own, so
/// the two can never disagree about what is left.
final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => FakeSaleRepository(ref.watch(productRepositoryProvider)),
);

final transactionApiProvider = Provider<TransactionApi>(
  (ref) => TransactionApi(
    ref.watch(authorizedDioProvider),
    baseUrl: ref.watch(functionsBaseUrlProvider),
  ),
);

/// The ledger, and after this feature the only write path into a lot's
/// remaining quantity.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepositoryImpl(
    transactionApi: ref.watch(transactionApiProvider),
  ),
);

final feePresetRepositoryProvider = Provider<FeePresetRepository>(
  (ref) => FeePresetRepositoryImpl(
    transactionApi: ref.watch(transactionApiProvider),
  ),
);

final onboardingResolverProvider = Provider<OnboardingResolver>(
  (ref) => OnboardingResolver(
    ref.watch(authRepositoryProvider),
    ref.watch(storeRepositoryProvider),
    SharedPreferences.getInstance,
  ),
);

final storageDataSourceProvider = Provider<StorageDataSource>(
  (ref) => StorageDataSourceImpl(
    ref.watch(authorizedDioProvider),
    currentUserId: () => ref.read(supabaseClientProvider).auth.currentUser?.id,
  ),
);

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepositoryImpl(ref.watch(storageDataSourceProvider)),
);

final storeApiProvider = Provider<StoreApi>(
  (ref) => StoreApi(ref.watch(authorizedDioProvider)),
);

final userApiProvider = Provider<UserApi>(
  (ref) => UserApi(ref.watch(authorizedDioProvider)),
);

final userProfileDataSourceProvider = Provider<UserProfileDataSource>(
  (ref) => UserProfileDataSourceImpl(ref.watch(userApiProvider)),
);

final storeDataSourceProvider = Provider<StoreDataSource>(
  (ref) => StoreDataSourceImpl(
    ref.watch(storeApiProvider),
    currentUserId: () => ref.read(supabaseClientProvider).auth.currentUser?.id,
  ),
);

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => SupabaseStoreRepositoryImpl(ref.watch(storeDataSourceProvider)),
);

/// Spans every store the user can act in, which is what the switcher needs and
/// what every other read deliberately refuses to do.
final storeOverviewRepositoryProvider = Provider<StoreOverviewRepository>(
  (ref) => FakeStoreOverviewRepository(
    ref.watch(storeRepositoryProvider),
    ref.watch(productRepositoryProvider),
  ),
);
