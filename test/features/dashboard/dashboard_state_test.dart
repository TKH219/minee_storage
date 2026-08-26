import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/dashboard/states/dashboard_state.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/fake_store_repository.dart';

Decimal d(String value) => Decimal.parse(value);

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);
final today = DateTime(2026, 8, 19);

void main() {
  late FakeProductRepository products;
  late FakeSaleRepository sales;
  late FakeStoreRepository stores;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
    sales = FakeSaleRepository(products, latency: Duration.zero);
    stores = FakeStoreRepository(
      stores: [
        storeFixture(id: 'store-a', name: 'Northside · Main', currencyId: 'cur-usd'),
      ],
      currencyList: const [usd],
    );
  });

  ProviderContainer containerFor({String? activeStore = 'store-a'}) {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(products),
        saleRepositoryProvider.overrideWithValue(sales),
        storeRepositoryProvider.overrideWithValue(stores),
        storeOverviewRepositoryProvider.overrideWithValue(
          FakeStoreOverviewRepository(stores, products),
        ),
        activeStoreProvider.overrideWith(() => FixedActiveStore(activeStore)),
        nowProvider.overrideWithValue(() => today),
      ],
    );
    addTearDown(container.dispose);
    container.listen(dashboardStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  SaleDraft draft(String price) => SaleDraft(
    lines: [
      SaleDraftLine(
        productId: 'p3',
        productName: 'Basmati rice 5kg',
        unit: ProductUnit.kg,
        quantity: Decimal.one,
        unitSellPrice: d(price),
        allocations: [
          SaleAllocation(
            batchId: 'b4',
            batchCode: '#B-0001',
            quantity: Decimal.one,
            unitCost: d('9.00'),
          ),
        ],
      ),
    ],
  );

  test('starts out untouched', () {
    final state = containerFor().read(dashboardStateProvider);
    expect(state.isInit, isTrue);
    expect(state.summary, isNull);
  });

  test('a store holding stock loads its name, currency, figures and alerts', () async {
    final container = containerFor();
    await container.read(dashboardStateProvider.notifier).load();

    final state = container.read(dashboardStateProvider);
    expect(state.isLoaded, isTrue);
    expect(state.isEmpty, isFalse);
    expect(state.storeName, 'Northside · Main');
    expect(state.currency.code, 'USD');
    expect(state.role, StoreRole.owner);
    expect(state.summary, isNotNull);
    expect(state.today, today);
    expect(state.alerts, isNotEmpty);
  });

  test('a store with no products is empty rather than a wall of zeroes', () async {
    products = FakeProductRepository(latency: Duration.zero, seedStoreId: 'store-z');
    sales = FakeSaleRepository(products, latency: Duration.zero);

    final container = containerFor();
    await container.read(dashboardStateProvider.notifier).load();

    final state = container.read(dashboardStateProvider);
    expect(state.isLoaded, isTrue);
    expect(state.isEmpty, isTrue);
    expect(state.summary, isNull);
    expect(state.alerts, isEmpty);
  });

  test('figures come from the sales recorded, not from a constant', () async {
    sales.recordAt(draft('20.00'), storeId: 'store-a', at: today);

    final container = containerFor();
    await container.read(dashboardStateProvider.notifier).load();

    final summary = container.read(dashboardStateProvider).summary!;
    expect(summary.revenue, d('20.00'));
    expect(summary.salesCount, 1);
  });

  test('refresh picks up a sale recorded after the first load', () async {
    final container = containerFor();
    await container.read(dashboardStateProvider.notifier).load();
    expect(container.read(dashboardStateProvider).summary!.salesCount, 0);

    sales.recordAt(draft('30.00'), storeId: 'store-a', at: today);
    await container.read(dashboardStateProvider.notifier).refresh();

    final summary = container.read(dashboardStateProvider).summary!;
    expect(summary.salesCount, 1);
    expect(summary.revenue, d('30.00'));
  });

  test('refresh does not blank the screen while it reloads', () async {
    final container = containerFor();
    await container.read(dashboardStateProvider.notifier).load();

    final future = container.read(dashboardStateProvider.notifier).refresh();
    expect(container.read(dashboardStateProvider).isLoading, isFalse);
    await future;
  });

  test('without an active store it refuses rather than guessing one', () async {
    final container = containerFor(activeStore: null);
    await container.read(dashboardStateProvider.notifier).load();

    final state = container.read(dashboardStateProvider);
    expect(state.isError, isTrue);
    expect(state.errorMessageKey, LocaleKeys.products_noActiveStore);
    expect(state.showFullScreenError, isTrue);
  });

  test('a repository failure surfaces as a full-screen error', () async {
    stores.error = Exception('offline');

    final container = containerFor();
    await container.read(dashboardStateProvider.notifier).load();

    final state = container.read(dashboardStateProvider);
    expect(state.isError, isTrue);
    expect(state.showFullScreenError, isTrue);
  });

  test('a store missing from the roster still loads rather than crashing', () async {
    final container = containerFor(activeStore: 'store-unknown');
    await container.read(dashboardStateProvider.notifier).load();

    final state = container.read(dashboardStateProvider);
    expect(state.isLoaded, isTrue);
    expect(state.storeName, isEmpty);
    expect(state.currency.code, Currency.vnd.code);
  });

  test('alerts describe the catalogue as of the day the dashboard is showing', () async {
    final container = containerFor();
    await container.read(dashboardStateProvider.notifier).load();

    final alerts = container.read(dashboardStateProvider).alerts;
    expect(alerts.map((alert) => alert.kind), [AttentionAlertKind.expiringSoon]);
    expect(alerts.single.valueAtCost, greaterThan(Decimal.zero));
  });

  test('the alert block is derived, not stored — a later date changes it', () async {
    final later = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(products),
        saleRepositoryProvider.overrideWithValue(sales),
        storeRepositoryProvider.overrideWithValue(stores),
        storeOverviewRepositoryProvider.overrideWithValue(
          FakeStoreOverviewRepository(stores, products),
        ),
        activeStoreProvider.overrideWith(() => FixedActiveStore('store-a')),
        nowProvider.overrideWithValue(() => today.add(const Duration(days: 400))),
      ],
    );
    addTearDown(later.dispose);
    later.listen(dashboardStateProvider, (_, _) {}, fireImmediately: true);

    await later.read(dashboardStateProvider.notifier).load();

    expect(
      later.read(dashboardStateProvider).alerts.map((alert) => alert.kind),
      contains(AttentionAlertKind.expired),
    );
  });
}
