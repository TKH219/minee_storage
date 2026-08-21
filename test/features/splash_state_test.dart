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
  setUp(useLocale);

  ProviderContainer containerWith(AuthRepository repository, GoRouter router) {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        routerProvider.overrideWithValue(router),
      ],
    );
  }

  test('routes to home when a session exists', () async {
    final router = buildTestRouter();
    final container = containerWith(
      FakeAuthRepository(
        user: const UserEntity(id: 'uid-1', email: 'a@b.com', fullName: 'S'),
      ),
      router,
    );
    addTearDown(container.dispose);

    await container.read(splashStateProvider.notifier).bootstrap();

    expect(currentPath(router), '/home');
  });

  test('routes to sign-in when there is no session', () async {
    final router = buildTestRouter();
    final container = containerWith(FakeAuthRepository(user: null), router);
    addTearDown(container.dispose);

    await container.read(splashStateProvider.notifier).bootstrap();

    expect(currentPath(router), '/sign-in');
  });
}
