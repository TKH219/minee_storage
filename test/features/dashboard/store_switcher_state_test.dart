import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/dashboard/states/store_switcher_state.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/fake_store_repository.dart';

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);
const vnd = Currency(id: 'cur-vnd', code: 'VND', symbol: '₫', decimals: 0);

Store store(String id, String name, String currencyId, StoreRole role) => Store(
  id: id,
  ownerId: 'uid-1',
  name: name,
  currencyId: currencyId,
  role: role,
);

void main() {
  Future<ProviderContainer> containerWith(List<Store> stores) async {
    SharedPreferences.setMockInitialValues({
      OnboardingResolver.activeStoreKey: 'store-a',
    });
    final prefs = await SharedPreferences.getInstance();
    final products = FakeProductRepository(latency: Duration.zero);
    final storeRepository = FakeStoreRepository(
      stores: stores,
      currencyList: const [usd, vnd],
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        productRepositoryProvider.overrideWithValue(products),
        storeRepositoryProvider.overrideWithValue(storeRepository),
        storeOverviewRepositoryProvider.overrideWithValue(
          FakeStoreOverviewRepository(storeRepository, products),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(storeSwitcherStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  final oneStore = [store('store-a', 'Northside · Main', 'cur-usd', StoreRole.owner)];
  final twoUsdStores = [
    store('store-a', 'Northside · Main', 'cur-usd', StoreRole.owner),
    store('store-b', 'Northside · Depot', 'cur-usd', StoreRole.manager),
  ];
  final mixedStores = [
    store('store-a', 'Northside · Main', 'cur-usd', StoreRole.owner),
    store('store-b', 'Northside · Depot', 'cur-usd', StoreRole.manager),
    store('store-c', 'Riverside Kiosk', 'cur-vnd', StoreRole.staff),
  ];

  test('loads every store in the order the repository answered', () async {
    final container = await containerWith(mixedStores);
    await container.read(storeSwitcherStateProvider.notifier).load();

    final state = container.read(storeSwitcherStateProvider);
    expect(state.isLoaded, isTrue);
    expect(
      state.summaries.map((summary) => summary.store.name),
      ['Northside · Main', 'Northside · Depot', 'Riverside Kiosk'],
    );
    expect(state.activeStoreId, 'store-a');
  });

  group('All stores is owner-only', () {
    test('is hidden when the user owns only one store', () async {
      final container = await containerWith(oneStore);
      await container.read(storeSwitcherStateProvider.notifier).load();

      expect(container.read(storeSwitcherStateProvider).canSeeAllStores, isFalse);
    });

    test('is hidden when the user owns none of the stores', () async {
      final container = await containerWith([
        store('store-a', 'Main', 'cur-usd', StoreRole.manager),
        store('store-b', 'Depot', 'cur-usd', StoreRole.staff),
      ]);
      await container.read(storeSwitcherStateProvider.notifier).load();

      expect(container.read(storeSwitcherStateProvider).canSeeAllStores, isFalse);
    });

    test('is shown to an owner holding two or more', () async {
      final container = await containerWith(twoUsdStores);
      await container.read(storeSwitcherStateProvider.notifier).load();

      expect(container.read(storeSwitcherStateProvider).canSeeAllStores, isTrue);
    });
  });

  group('currencies are never summed', () {
    test('a single-currency roster raises no notice', () async {
      final container = await containerWith(twoUsdStores);
      await container.read(storeSwitcherStateProvider.notifier).load();

      expect(container.read(storeSwitcherStateProvider).mixedCurrencyCodes, isEmpty);
    });

    test('a mixed roster names every code it spans, sorted and deduplicated', () async {
      final container = await containerWith(mixedStores);
      await container.read(storeSwitcherStateProvider.notifier).load();

      expect(
        container.read(storeSwitcherStateProvider).mixedCurrencyCodes,
        ['USD', 'VND'],
      );
    });
  });

  group('choosing a scope', () {
    test('selecting a store moves the active store', () async {
      final container = await containerWith(mixedStores);
      await container.read(storeSwitcherStateProvider.notifier).load();

      await container.read(storeSwitcherStateProvider.notifier).select('store-b');

      expect(container.read(activeStoreProvider), 'store-b');
      expect(container.read(allStoresScopeProvider), isFalse);
    });

    test('selecting all stores keeps the store id and sets the scope', () async {
      final container = await containerWith(twoUsdStores);
      await container.read(storeSwitcherStateProvider.notifier).load();

      container.read(storeSwitcherStateProvider.notifier).selectAllStores();

      expect(container.read(allStoresScopeProvider), isTrue);
      expect(container.read(activeStoreProvider), 'store-a');
    });

    test('a non-owner cannot reach the aggregate even by calling it', () async {
      final container = await containerWith([
        store('store-a', 'Main', 'cur-usd', StoreRole.staff),
        store('store-b', 'Depot', 'cur-usd', StoreRole.staff),
      ]);
      await container.read(storeSwitcherStateProvider.notifier).load();

      container.read(storeSwitcherStateProvider.notifier).selectAllStores();

      expect(container.read(allStoresScopeProvider), isFalse);
    });
  });

  test('a failure to load surfaces as an error rather than an empty list', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final products = FakeProductRepository(latency: Duration.zero);
    final storeRepository = FakeStoreRepository(currencyList: const [usd])
      ..error = Exception('offline');

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        productRepositoryProvider.overrideWithValue(products),
        storeRepositoryProvider.overrideWithValue(storeRepository),
        storeOverviewRepositoryProvider.overrideWithValue(
          FakeStoreOverviewRepository(storeRepository, products),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(storeSwitcherStateProvider, (_, _) {}, fireImmediately: true);

    await container.read(storeSwitcherStateProvider.notifier).load();

    expect(container.read(storeSwitcherStateProvider).isError, isTrue);
  });
}
