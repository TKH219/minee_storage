import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/consume_state.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/localization_test_harness.dart';

ProductBatchEntity batch({
  required String id,
  required String code,
  String? expiry,
  String purchased = '2026-08-01',
  String price = '1.00',
  String remaining = '5',
}) {
  return ProductBatchEntity(
    id: id,
    productId: 'p1',
    storeId: 'store-a',
    batchCode: code,
    purchasedAt: DateTime.parse(purchased),
    unitPrice: Decimal.parse(price),
    expiryDate: expiry == null ? null : DateTime.parse(expiry),
    initialQuantity: Decimal.parse('12'),
    remainingQuantity: Decimal.parse(remaining),
    createdAt: DateTime.parse(purchased),
    updatedAt: DateTime.parse(purchased),
  );
}

ProductEntity product(List<ProductBatchEntity> batches, {ProductUnit unit = ProductUnit.kg}) {
  return ProductEntity(
    id: 'p1',
    name: 'Whole Milk 1L',
    unit: unit,
    createdAt: DateTime.parse('2026-07-01'),
    updatedAt: DateTime.parse('2026-07-01'),
    batches: batches,
  );
}

void main() {
  setUp(useLocale);

  ProviderContainer containerWith(_RecordingRepository repository) {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
        activeStoreProvider.overrideWithValue('store-a'),
      ],
    );
    addTearDown(container.dispose);
    container.listen(consumeStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  group('allocation preview', () {
    test('resolves FEFO across lots before anything is committed', () {
      final container = containerWith(_RecordingRepository());
      final notifier = container.read(consumeStateProvider.notifier);

      notifier.open(product([
        batch(id: 'sooner', code: '#B-0001', expiry: '2026-09-01', remaining: '2'),
        batch(id: 'later', code: '#B-0002', expiry: '2026-12-01', remaining: '8'),
      ]));
      notifier.updateQuantity('5');

      final allocations = container.read(consumeStateProvider).allocations;
      expect(allocations.map((a) => a.batchId), ['sooner', 'later']);
      expect(allocations.first.quantity, Decimal.parse('2'));
      expect(allocations.last.quantity, Decimal.parse('3'));
    });

    test('an exact-quantity request draws one lot to zero and stops', () {
      final container = containerWith(_RecordingRepository());
      final notifier = container.read(consumeStateProvider.notifier);

      notifier.open(product([batch(id: 'only', code: '#B-0001', expiry: '2026-09-01', remaining: '5')]));
      notifier.updateQuantity('5');

      final state = container.read(consumeStateProvider);
      expect(state.allocations, hasLength(1));
      expect(state.allocations.single.quantity, Decimal.parse('5'));
      expect(state.canCommit, isTrue);
    });

    test('an expired lot is still drawn first, and warned about', () {
      final container = containerWith(_RecordingRepository());
      final notifier = container.read(consumeStateProvider.notifier);

      notifier.open(
        product([
          batch(id: 'expired', code: '#B-0001', expiry: '2020-01-01', remaining: '3'),
          batch(id: 'fresh', code: '#B-0002', expiry: '2030-01-01', remaining: '9'),
        ]),
        now: DateTime.parse('2026-08-20'),
      );
      notifier.updateQuantity('4');

      final state = container.read(consumeStateProvider);
      expect(state.allocations.first.batchId, 'expired');
      expect(state.drawsFromExpired, isTrue);
      // The warning is not a block.
      expect(state.canCommit, isTrue);
    });
  });

  group('refusal', () {
    test('more than total remaining is refused before any request', () async {
      final repository = _RecordingRepository();
      final container = containerWith(repository);
      final notifier = container.read(consumeStateProvider.notifier);

      notifier.open(product([batch(id: 'only', code: '#B-0001', expiry: '2026-09-01', remaining: '5')]));
      notifier.updateQuantity('9');

      final state = container.read(consumeStateProvider);
      expect(state.exceedsStock, isTrue);
      expect(state.canCommit, isFalse);
      expect(state.allocations, isEmpty);

      await notifier.commit();
      expect(repository.consumeCalls, 0, reason: 'nothing may leave the device');
    });

    test('a fractional quantity on a count unit is refused at input', () {
      final container = containerWith(_RecordingRepository());
      final notifier = container.read(consumeStateProvider.notifier);

      notifier.open(
        product(
          [batch(id: 'only', code: '#B-0001', expiry: '2026-09-01', remaining: '5')],
          unit: ProductUnit.piece,
        ),
      );
      notifier.updateQuantity('2.5');

      final state = container.read(consumeStateProvider);
      expect(state.fractionRefused, isTrue);
      expect(state.canCommit, isFalse);
    });

    test('the same fraction is fine on a measured unit', () {
      final container = containerWith(_RecordingRepository());
      final notifier = container.read(consumeStateProvider.notifier);

      notifier.open(product([batch(id: 'only', code: '#B-0001', expiry: '2026-09-01', remaining: '5')]));
      notifier.updateQuantity('2.5');

      expect(container.read(consumeStateProvider).fractionRefused, isFalse);
      expect(container.read(consumeStateProvider).canCommit, isTrue);
    });

    test('zero and blank commit nothing', () async {
      final repository = _RecordingRepository();
      final container = containerWith(repository);
      final notifier = container.read(consumeStateProvider.notifier);
      notifier.open(product([batch(id: 'only', code: '#B-0001', expiry: '2026-09-01')]));

      notifier.updateQuantity('0');
      expect(container.read(consumeStateProvider).canCommit, isFalse);

      notifier.updateQuantity('');
      expect(container.read(consumeStateProvider).canCommit, isFalse);

      await notifier.commit();
      expect(repository.consumeCalls, 0);
    });
  });

  test('committing sends the resolved allocation, in order', () async {
    final repository = _RecordingRepository();
    final container = containerWith(repository);
    final notifier = container.read(consumeStateProvider.notifier);

    notifier.open(product([
      batch(id: 'sooner', code: '#B-0001', expiry: '2026-09-01', remaining: '2'),
      batch(id: 'later', code: '#B-0002', expiry: '2026-12-01', remaining: '8'),
    ]));
    notifier.updateQuantity('5');
    await notifier.commit();

    expect(repository.consumeCalls, 1);
    expect(repository.lastAllocations!.map((a) => a.batchId), ['sooner', 'later']);
    expect(repository.lastStoreId, 'store-a');
    expect(container.read(consumeStateProvider).didCommit, isTrue);
  });
}

class _RecordingRepository extends FakeProductRepository {
  _RecordingRepository() : super(latency: Duration.zero);

  int consumeCalls = 0;
  List<BatchAllocation>? lastAllocations;
  String? lastStoreId;

  @override
  Future<ProductEntity> consume(
    String productId,
    List<BatchAllocation> allocations, {
    required String storeId,
  }) async {
    consumeCalls++;
    lastAllocations = allocations;
    lastStoreId = storeId;
    return product([batch(id: 'only', code: '#B-0001', expiry: '2026-09-01', remaining: '0')]);
  }
}
