import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/new/states/product_picker_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';

Decimal d(String value) => Decimal.parse(value);

void main() {
  late FakeProductRepository products;
  late FakeSaleRepository sales;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
    sales = FakeSaleRepository(products, latency: Duration.zero);
  });

  ProviderContainer containerFor() {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(products),
        saleRepositoryProvider.overrideWithValue(sales),
        activeStoreProvider.overrideWith(() => FixedActiveStore('store-a')),
      ],
    );
    addTearDown(container.dispose);
    container.listen(productPickerStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  test('opens on the full list with nothing typed', () async {
    final container = containerFor();
    await container.read(productPickerStateProvider.notifier).load();

    final state = container.read(productPickerStateProvider);
    expect(state.isLoaded, isTrue);
    expect(state.query, isEmpty);
    expect(state.allProducts, hasLength(3));
    expect(state.recentlySold, isEmpty);
  });

  test('puts recently sold on top, and not twice', () async {
    final product = await products.getProduct('p3', storeId: 'store-a');
    final allocations = await sales.previewAllocation(
      productId: 'p3',
      storeId: 'store-a',
      quantity: Decimal.one,
    );
    await sales.confirm(
      SaleDraft(
        lines: [
          SaleDraftLine(
            productId: product.id,
            productName: product.name,
            unit: product.unit,
            quantity: Decimal.one,
            unitSellPrice: d('12.50'),
            allocations: allocations,
          ),
        ],
      ),
      storeId: 'store-a',
    );

    final container = containerFor();
    await container.read(productPickerStateProvider.notifier).load();

    final state = container.read(productPickerStateProvider);
    expect(state.recentlySold.map((each) => each.id), ['p3']);
    expect(
      state.allProducts.where((each) => each.id == 'p3'),
      hasLength(1),
      reason: 'a recently sold product still belongs in the full list once',
    );
  });

  test('searching filters by name, case-insensitively', () async {
    final container = containerFor();
    final notifier = container.read(productPickerStateProvider.notifier);
    await notifier.load();

    await notifier.search('MILK');

    final state = container.read(productPickerStateProvider);
    expect(state.query, 'MILK');
    expect(state.allProducts.map((each) => each.name), ['Whole milk 1L']);
  });

  test('clearing the search restores the full list', () async {
    final container = containerFor();
    final notifier = container.read(productPickerStateProvider.notifier);
    await notifier.load();

    await notifier.search('milk');
    await notifier.search('');

    expect(container.read(productPickerStateProvider).allProducts, hasLength(3));
  });

  test('a search with no matches is empty rather than an error', () async {
    final container = containerFor();
    final notifier = container.read(productPickerStateProvider.notifier);
    await notifier.load();

    await notifier.search('zzzz');

    final state = container.read(productPickerStateProvider);
    expect(state.isLoaded, isTrue);
    expect(state.allProducts, isEmpty);
    expect(state.hasQuery, isTrue);
  });

  group('out of stock', () {
    test('a product holding nothing cannot be picked', () async {
      await products.applyLedgerDeltas(
        'p3',
        [BatchAllocation(batchId: 'b4', quantity: d('2'))],
        storeId: 'store-a',
      );

      final container = containerFor();
      await container.read(productPickerStateProvider.notifier).load();

      final state = container.read(productPickerStateProvider);
      final rice = state.allProducts.firstWhere((each) => each.id == 'p3');
      expect(rice.totalRemaining, Decimal.zero);
      expect(state.canPick(rice), isFalse);
    });

    test('but it stays visible, so the seller learns it exists', () async {
      await products.applyLedgerDeltas(
        'p3',
        [BatchAllocation(batchId: 'b4', quantity: d('2'))],
        storeId: 'store-a',
      );

      final container = containerFor();
      await container.read(productPickerStateProvider.notifier).load();

      expect(
        container.read(productPickerStateProvider).allProducts.map((e) => e.id),
        contains('p3'),
      );
    });

    test('a product holding stock can be picked', () async {
      final container = containerFor();
      await container.read(productPickerStateProvider.notifier).load();

      final state = container.read(productPickerStateProvider);
      expect(state.canPick(state.allProducts.first), isTrue);
    });
  });

  test('archived products never appear', () async {
    await products.archiveProduct('p3', storeId: 'store-a');

    final container = containerFor();
    await container.read(productPickerStateProvider.notifier).load();

    expect(
      container.read(productPickerStateProvider).allProducts.map((e) => e.id),
      isNot(contains('p3')),
    );
  });

  test('without an active store it refuses rather than guessing', () async {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(products),
        saleRepositoryProvider.overrideWithValue(sales),
        activeStoreProvider.overrideWith(() => FixedActiveStore(null)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(productPickerStateProvider, (_, _) {}, fireImmediately: true);

    await container.read(productPickerStateProvider.notifier).load();

    expect(container.read(productPickerStateProvider).isError, isTrue);
  });
}
