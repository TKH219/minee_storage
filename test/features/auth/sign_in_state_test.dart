import 'package:shared_preferences/shared_preferences.dart';
import '../../support/fake_store_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/features/auth/sign_in/states/sign_in_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';

import '../../support/localization_test_harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUp(useLocale);

  test('canSubmit requires both fields', () {
    final router = buildTestRouter();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(stores: [storeFixture()]),
        ),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    container.listen(signInStateProvider, (_, _) {});
    final notifier = container.read(signInStateProvider.notifier);

    expect(container.read(signInStateProvider).canSubmit, isFalse);

    notifier.updateEmail('a@b.com');
    expect(container.read(signInStateProvider).canSubmit, isFalse);

    notifier.updatePassword('secret');
    expect(container.read(signInStateProvider).canSubmit, isTrue);
  });

  test('a successful sign-in lands on the shell', () async {
    final router = buildTestRouter();
    final repository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(stores: [storeFixture()]),
        ),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    container.listen(signInStateProvider, (_, _) {});
    final notifier = container.read(signInStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret');

    await notifier.signIn();

    expect(repository.calls, contains('signIn:a@b.com'));
    expect(currentPath(router), '/dashboard');
  });

  test('a failed sign-in stays put and records the error', () async {
    final router = buildTestRouter();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            error: const UnauthorizedException(
              message: 'Incorrect email or password.',
            ),
          ),
        ),
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(stores: [storeFixture()]),
        ),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    container.listen(signInStateProvider, (_, _) {});
    final notifier = container.read(signInStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('wrong');

    await notifier.signIn();

    expect(currentPath(router), '/');
    expect(container.read(signInStateProvider).isError, isTrue);
    expect(
      // the exception carries the backend's own prose, so it wins over the key
      container.read(signInStateProvider).errorMessage,
      'Incorrect email or password.',
    );
  });

  test('wrong credentials place the error below the password field', () async {
    final router = buildTestRouter();
    final repository = FakeAuthRepository(error: const InvalidCredentialsException());
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(stores: [storeFixture()]),
        ),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    container.listen(signInStateProvider, (_, _) {});
    final notifier = container.read(signInStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret');

    await notifier.signIn();

    expect(container.read(signInStateProvider).errorPlacement,
        AuthErrorPlacement.belowPassword);
  });

  test('a deactivated account places the error above the email field', () async {
    final router = buildTestRouter();
    final repository = FakeAuthRepository(
      error: const ForbiddenException(message: 'deactivated'),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(stores: [storeFixture()]),
        ),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    container.listen(signInStateProvider, (_, _) {});
    final notifier = container.read(signInStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret');

    await notifier.signIn();

    expect(container.read(signInStateProvider).errorPlacement,
        AuthErrorPlacement.aboveEmail);
  });

  test('editing either field clears the error surface', () async {
    final router = buildTestRouter();
    final repository = FakeAuthRepository(error: const InvalidCredentialsException());
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(stores: [storeFixture()]),
        ),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    container.listen(signInStateProvider, (_, _) {});
    final notifier = container.read(signInStateProvider.notifier)
      ..updateEmail('a@b.com')
      ..updatePassword('secret');
    await notifier.signIn();
    expect(container.read(signInStateProvider).errorPlacement, isNot(AuthErrorPlacement.none));

    notifier.updatePassword('secret2');
    expect(container.read(signInStateProvider).errorPlacement, AuthErrorPlacement.none);
  });
}
