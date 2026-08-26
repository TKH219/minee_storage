import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/new/states/allocation_state.dart';
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
    container.listen(allocationStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  Future<ProductEntity> oliveOil() => products.getProduct('p1', storeId: 'store-a');

  group('automatic FEFO', () {
    test('splits across lots, earliest expiry first, each at its own cost', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('6');

      final state = container.read(allocationStateProvider);
      expect(state.allocations.map((a) => a.batchId), ['b1', 'b2']);
      expect(state.allocations.first.quantity, d('2'));
      expect(state.allocations.first.unitCost, d('11.50'));
      expect(state.allocations.last.quantity, d('4'));
      expect(state.allocations.last.unitCost, d('12.75'));
    });

    test('says which lot it empties and what remains in the other', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('6');

      final state = container.read(allocationStateProvider);
      expect(state.allocations.first.emptiesLot, isTrue);
      expect(state.allocations.last.remainingAfter, d('2'));
    });

    test('a quantity one lot can cover does not split', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('2');

      expect(container.read(allocationStateProvider).allocations, hasLength(1));
    });

    test('the line total is quantity times sell price', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('6');
      notifier.setSellPrice('1.80');

      expect(container.read(allocationStateProvider).lineTotal, d('10.80'));
    });

    test('the price defaults to the latest purchase price, never to cost', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());

      final state = container.read(allocationStateProvider);
      expect(state.sellPrice, isNotEmpty);
      expect(state.parsedSellPrice, d('12.75'));
    });

    test('the stepper raises and lowers the quantity', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('2');
      await notifier.increment();
      expect(container.read(allocationStateProvider).quantity, '3');

      await notifier.decrement();
      expect(container.read(allocationStateProvider).quantity, '2');
    });

    test('the stepper never goes below one', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('1');
      await notifier.decrement();

      expect(container.read(allocationStateProvider).quantity, '1');
    });
  });

  group('refusals', () {
    test('more than the store holds clears the split and blocks', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('99');

      final state = container.read(allocationStateProvider);
      expect(state.exceedsStock, isTrue);
      expect(state.allocations, isEmpty);
      expect(state.canAdd, isFalse);
      expect(state.totalRemaining, d('8'));
    });

    test('zero blocks and shows nothing', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('0');

      final state = container.read(allocationStateProvider);
      expect(state.allocations, isEmpty);
      expect(state.canAdd, isFalse);
    });

    test('a fraction against a counted unit is refused', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      final counted = (await oliveOil()).copyWith(unit: ProductUnit.piece);
      await notifier.open(counted);
      await notifier.setQuantity('1.5');

      final state = container.read(allocationStateProvider);
      expect(state.fractionRefused, isTrue);
      expect(state.canAdd, isFalse);
    });

    test('a blank sell price blocks', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('2');
      notifier.setSellPrice('');

      expect(container.read(allocationStateProvider).canAdd, isFalse);
    });

    test('a zero sell price blocks', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('2');
      notifier.setSellPrice('0');

      expect(container.read(allocationStateProvider).canAdd, isFalse);
    });

    test('a valid quantity and price is addable', () async {
      final container = containerFor();
      final notifier = container.read(allocationStateProvider.notifier);

      await notifier.open(await oliveOil());
      await notifier.setQuantity('2');
      notifier.setSellPrice('1.80');

      expect(container.read(allocationStateProvider).canAdd, isTrue);
    });
  });

  test('the resolved line carries the split it showed', () async {
    final container = containerFor();
    final notifier = container.read(allocationStateProvider.notifier);

    await notifier.open(await oliveOil());
    await notifier.setQuantity('6');
    notifier.setSellPrice('1.80');

    final line = container.read(allocationStateProvider).toLine()!;
    expect(line.productId, 'p1');
    expect(line.quantity, d('6'));
    expect(line.unitSellPrice, d('1.80'));
    expect(line.allocations, hasLength(2));
    expect(line.lineCost, d('74.00'));
  });

  test('reopening for an existing line restores its quantity and price', () async {
    final container = containerFor();
    final notifier = container.read(allocationStateProvider.notifier);

    await notifier.open(
      await oliveOil(),
      quantity: d('4'),
      sellPrice: d('2.50'),
    );

    final state = container.read(allocationStateProvider);
    expect(state.quantity, '4');
    expect(state.parsedSellPrice, d('2.50'));
    expect(state.allocations, hasLength(2));
  });
}
