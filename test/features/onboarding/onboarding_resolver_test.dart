import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

OnboardingResolver resolverFor(FakeAuthRepository auth, FakeStoreRepository stores) {
  return OnboardingResolver(auth, stores, SharedPreferences.getInstance);
}

void main() {
  setUp(useLocale);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('no session resolves to sign-in without touching stores', () async {
    final stores = FakeStoreRepository();

    expect(await resolverFor(FakeAuthRepository(), stores).resolve(), AppRoutes.signInName);
    expect(stores.calls, isEmpty);
  });

  test('a blank full name resolves to the profile screen', () async {
    final auth = FakeAuthRepository(user: const UserEntity(id: 'u1', email: 'a@b.c'));
    final stores = FakeStoreRepository();

    expect(
      await resolverFor(auth, stores).resolve(),
      AppRoutes.onboardingProfileName,
    );
    expect(stores.calls, isEmpty);
  });

  test('a named user with no store resolves to create-shop', () async {
    final auth = FakeAuthRepository(
      user: const UserEntity(id: 'u1', email: 'a@b.c', fullName: 'Linh'),
    );

    expect(
      await resolverFor(auth, FakeStoreRepository()).resolve(),
      AppRoutes.createStoreName,
    );
  });

  test('a complete user reaches the dashboard, is stamped, and has an active store', () async {
    final auth = FakeAuthRepository(
      user: const UserEntity(id: 'u1', email: 'a@b.c', fullName: 'Linh'),
    );
    final stores = FakeStoreRepository(stores: [storeFixture(id: 's-9')]);

    expect(await resolverFor(auth, stores).resolve(), AppRoutes.dashboardName);
    expect(auth.calls, contains('completeOnboarding'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(OnboardingResolver.activeStoreKey), 's-9');
  });

  test('an already-stamped user is not stamped again', () async {
    final auth = FakeAuthRepository(
      user: UserEntity(
        id: 'u1',
        email: 'a@b.c',
        fullName: 'Linh',
        onboardingCompletedAt: DateTime.utc(2026, 8, 1),
      ),
    );
    final stores = FakeStoreRepository(stores: [storeFixture(id: 's-9')]);

    await resolverFor(auth, stores).resolve();

    expect(auth.calls, isNot(contains('completeOnboarding')));
  });
}
