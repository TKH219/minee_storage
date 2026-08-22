import 'package:shared_preferences/shared_preferences.dart';
import '../support/fake_store_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/features/splash/states/splash_state.dart';
import 'package:mine_storage/providers.dart';

import '../support/auth_test_harness.dart';
import '../support/fake_auth_repository.dart';

import '../support/localization_test_harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUp(useLocale);

  ProviderContainer containerWith(AuthRepository repository, GoRouter router) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(stores: [storeFixture()]),
        ),
        routerProvider.overrideWithValue(router),
      ],
    );
    // The provider is auto-dispose; in the app the page listens for its whole
    // life. Without a listener here it is collected across the resolver's
    // async gaps and the navigation never lands.
    container.listen(splashStateProvider, (_, _) {});
    return container;
  }

  test('routes to the dashboard when a session is fully onboarded', () async {
    final router = buildTestRouter();
    final container = containerWith(
      FakeAuthRepository(
        user: const UserEntity(id: 'uid-1', email: 'a@b.com', fullName: 'S'),
      ),
      router,
    );
    addTearDown(container.dispose);

    await container.read(splashStateProvider.notifier).bootstrap();

    expect(currentPath(router), '/dashboard');
  });

  test('routes to sign-in when there is no session', () async {
    final router = buildTestRouter();
    final container = containerWith(FakeAuthRepository(user: null), router);
    addTearDown(container.dispose);

    await container.read(splashStateProvider.notifier).bootstrap();

    expect(currentPath(router), '/sign-in');
  });
}
