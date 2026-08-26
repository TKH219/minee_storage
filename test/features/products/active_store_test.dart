import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';

void main() {
  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('reads the store onboarding settled on', () async {
    final container = await containerWith({
      OnboardingResolver.activeStoreKey: 'store-a',
    });

    expect(container.read(activeStoreProvider), 'store-a');
  });

  test('is null when onboarding never chose one', () async {
    final container = await containerWith({});

    expect(container.read(activeStoreProvider), isNull);
  });

  test('selecting a store replaces the active one and persists it', () async {
    final container = await containerWith({
      OnboardingResolver.activeStoreKey: 'store-a',
    });

    await container.read(activeStoreProvider.notifier).select('store-b');

    expect(container.read(activeStoreProvider), 'store-b');
    expect(
      container.read(sharedPreferencesProvider).getString(
        OnboardingResolver.activeStoreKey,
      ),
      'store-b',
    );
  });

  test('selecting the store already active changes nothing', () async {
    final container = await containerWith({
      OnboardingResolver.activeStoreKey: 'store-a',
    });

    await container.read(activeStoreProvider.notifier).select('store-a');

    expect(container.read(activeStoreProvider), 'store-a');
  });

  test('a store can be chosen when onboarding never settled on one', () async {
    final container = await containerWith({});

    await container.read(activeStoreProvider.notifier).select('store-c');

    expect(container.read(activeStoreProvider), 'store-c');
  });

  group('all-stores scope', () {
    test('starts off, because a single store is the common case', () async {
      final container = await containerWith({});
      expect(container.read(allStoresScopeProvider), isFalse);
    });

    test('can be turned on and off', () async {
      final container = await containerWith({});

      container.read(allStoresScopeProvider.notifier).set(true);
      expect(container.read(allStoresScopeProvider), isTrue);

      container.read(allStoresScopeProvider.notifier).set(false);
      expect(container.read(allStoresScopeProvider), isFalse);
    });

    test('choosing a store leaves the aggregate scope', () async {
      final container = await containerWith({});
      container.read(allStoresScopeProvider.notifier).set(true);

      await container.read(activeStoreProvider.notifier).select('store-b');

      expect(container.read(allStoresScopeProvider), isFalse);
    });
  });
}
