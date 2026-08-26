import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
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

  /// Olive oil holds 2 in lot b1 (cost 11.50) and 6 in lot b2 (cost 12.75).
  Future<AllocationStateNotifier> openFor(
    ProviderContainer container,
    String quantity,
  ) async {
    final notifier = container.read(allocationStateProvider.notifier);
    await notifier.open(await products.getProduct('p1', storeId: 'store-a'));
    await notifier.setQuantity(quantity);
    return notifier;
  }

  group('entering manual mode', () {
    test('seeds the boxes from the automatic split', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');

      notifier.enterManual();

      final state = container.read(allocationStateProvider);
      expect(state.isManual, isTrue);
      expect(state.manualLots.map((lot) => lot.batchId), ['b1', 'b2']);
      expect(state.manualLots.first.quantity, d('2'));
      expect(state.manualLots.last.quantity, d('4'));
      expect(state.canAdd, isTrue);
    });

    test('offers every lot that holds stock, not only the allocated ones', () async {
      final container = containerFor();
      final notifier = await openFor(container, '1');

      notifier.enterManual();

      expect(
        container.read(allocationStateProvider).manualLots.map((lot) => lot.batchId),
        ['b1', 'b2'],
      );
    });

    test('reports each lot\'s own cost and what it holds', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');

      notifier.enterManual();

      final lots = container.read(allocationStateProvider).manualLots;
      expect(lots.first.unitCost, d('11.50'));
      expect(lots.first.available, d('2'));
      expect(lots.last.unitCost, d('12.75'));
      expect(lots.last.available, d('6'));
    });
  });

  group('the split must sum exactly', () {
    test('under-allocating blocks and names what is missing', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');
      notifier.enterManual();

      notifier.setManualQuantity('b1', '1');
      notifier.setManualQuantity('b2', '3');

      final state = container.read(allocationStateProvider);
      expect(state.manualAllocated, d('4'));
      expect(state.manualMissing, d('2'));
      expect(state.manualExcess, Decimal.zero);
      expect(state.manualSumsExactly, isFalse);
      expect(state.canAdd, isFalse);
    });

    test('over-allocating blocks and names the excess', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');
      notifier.enterManual();

      notifier.setManualQuantity('b1', '2');
      notifier.setManualQuantity('b2', '6');

      final state = container.read(allocationStateProvider);
      expect(state.manualAllocated, d('8'));
      expect(state.manualExcess, d('2'));
      expect(state.manualMissing, Decimal.zero);
      expect(state.canAdd, isFalse);
    });

    test('a lot taken beyond what it holds is flagged and blocks', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');
      notifier.enterManual();

      notifier.setManualQuantity('b1', '4');
      notifier.setManualQuantity('b2', '2');

      final state = container.read(allocationStateProvider);
      expect(state.manualAllocated, d('6'));
      expect(state.manualSumsExactly, isTrue);
      expect(state.lotInError('b1'), isTrue);
      expect(state.lotInError('b2'), isFalse);
      expect(
        state.canAdd,
        isFalse,
        reason: 'summing right does not make an impossible lot possible',
      );
    });

    test('a split summing exactly is accepted', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');
      notifier.enterManual();

      notifier.setManualQuantity('b1', '1');
      notifier.setManualQuantity('b2', '5');

      final state = container.read(allocationStateProvider);
      expect(state.manualSumsExactly, isTrue);
      expect(state.canAdd, isTrue);
    });

    test('a blank box counts as nothing rather than breaking the sum', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');
      notifier.enterManual();

      notifier.setManualQuantity('b1', '');
      notifier.setManualQuantity('b2', '6');

      final state = container.read(allocationStateProvider);
      expect(state.manualAllocated, d('6'));
      expect(state.canAdd, isTrue);
    });
  });

  group('the accepted line', () {
    test('carries each lot at its own cost, earliest expiry first', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');
      notifier.enterManual();
      notifier.setManualQuantity('b1', '1');
      notifier.setManualQuantity('b2', '5');
      notifier.setSellPrice('20.00');

      final line = container.read(allocationStateProvider).toLine()!;

      expect(line.allocations.map((a) => a.batchId), ['b1', 'b2']);
      expect(line.allocations.first.quantity, d('1'));
      expect(line.allocations.first.unitCost, d('11.50'));
      expect(line.allocations.last.quantity, d('5'));
      expect(line.allocations.last.unitCost, d('12.75'));
      expect(line.lineCost, d('75.25'));
    });

    test('reports what each lot has left after the draw', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');
      notifier.enterManual();
      notifier.setManualQuantity('b1', '2');
      notifier.setManualQuantity('b2', '4');

      final line = container.read(allocationStateProvider).toLine()!;
      expect(line.allocations.first.remainingAfter, Decimal.zero);
      expect(line.allocations.first.emptiesLot, isTrue);
      expect(line.allocations.last.remainingAfter, d('2'));
    });

    test('drops a lot the seller assigned nothing to', () async {
      final container = containerFor();
      final notifier = await openFor(container, '6');
      notifier.enterManual();
      notifier.setManualQuantity('b1', '0');
      notifier.setManualQuantity('b2', '6');

      final line = container.read(allocationStateProvider).toLine()!;
      expect(line.allocations.map((a) => a.batchId), ['b2']);
    });
  });

  test('leaving manual mode restores the FEFO split', () async {
    final container = containerFor();
    final notifier = await openFor(container, '6');
    notifier.enterManual();
    notifier.setManualQuantity('b1', '1');
    notifier.setManualQuantity('b2', '3');

    await notifier.leaveManual();

    final state = container.read(allocationStateProvider);
    expect(state.isManual, isFalse);
    expect(state.allocations.first.quantity, d('2'));
    expect(state.allocations.last.quantity, d('4'));
    expect(state.canAdd, isTrue);
  });

  test('changing the quantity while manual re-checks the sum', () async {
    final container = containerFor();
    final notifier = await openFor(container, '6');
    notifier.enterManual();
    notifier.setManualQuantity('b1', '2');
    notifier.setManualQuantity('b2', '4');
    expect(container.read(allocationStateProvider).canAdd, isTrue);

    await notifier.setQuantity('7');

    expect(container.read(allocationStateProvider).canAdd, isFalse);
  });
}
