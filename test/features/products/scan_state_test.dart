import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/scan/states/scan_state.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

import '../../support/localization_test_harness.dart';

import '../../support/active_store_override.dart';

void main() {
  setUp(useLocale);

  ProviderContainer containerWith(
    _ScanRepository repository, {
    String? activeStore = 'store-a',
  }) {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
        activeStoreProvider.overrideWith(() => FixedActiveStore(activeStore)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(scanStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  group('decode', () {
    test('a hit resolves to the product holding that barcode', () async {
      final repository = _ScanRepository(known: {'5012345678900': _milk});
      final container = containerWith(repository);

      await container.read(scanStateProvider.notifier).decoded('5012345678900');

      final state = container.read(scanStateProvider);
      expect(state.outcome, ScanOutcome.hit);
      expect(state.product?.id, 'p1');
      expect(state.barcode, '5012345678900');
    });

    test('a miss keeps the barcode so the form can prefill it', () async {
      final container = containerWith(_ScanRepository());

      await container.read(scanStateProvider.notifier).decoded('0000000000000');

      final state = container.read(scanStateProvider);
      expect(state.outcome, ScanOutcome.miss);
      expect(state.product, isNull);
      expect(state.barcode, '0000000000000');
    });

    test('the same barcode twice does not look up twice', () async {
      final repository = _ScanRepository(known: {'5012345678900': _milk});
      final container = containerWith(repository);
      final notifier = container.read(scanStateProvider.notifier);

      await notifier.decoded('5012345678900');
      await notifier.decoded('5012345678900');

      expect(repository.lookups, 1);
    });

    test('a different barcode is looked up again', () async {
      final repository = _ScanRepository(known: {'5012345678900': _milk});
      final container = containerWith(repository);
      final notifier = container.read(scanStateProvider.notifier);

      await notifier.decoded('5012345678900');
      await notifier.decoded('9999999999999');

      expect(repository.lookups, 2);
      expect(container.read(scanStateProvider).outcome, ScanOutcome.miss);
    });

    test('a blank scan is ignored rather than looked up', () async {
      final repository = _ScanRepository();
      final container = containerWith(repository);

      await container.read(scanStateProvider.notifier).decoded('   ');

      expect(repository.lookups, 0);
      expect(container.read(scanStateProvider).outcome, ScanOutcome.none);
    });
  });

  test('clearing lets the same barcode be scanned again', () async {
    final repository = _ScanRepository(known: {'5012345678900': _milk});
    final container = containerWith(repository);
    final notifier = container.read(scanStateProvider.notifier);

    await notifier.decoded('5012345678900');
    notifier.reset();
    await notifier.decoded('5012345678900');

    expect(repository.lookups, 2);
  });

  test('a lookup failure surfaces rather than reading as a miss', () async {
    final container = containerWith(_ScanRepository(error: Exception('offline')));

    await container.read(scanStateProvider.notifier).decoded('5012345678900');

    final state = container.read(scanStateProvider);
    expect(state.isError, isTrue);
    // A miss would send the user to create a duplicate product.
    expect(state.outcome, ScanOutcome.none);
  });

  test('refuses to scan without an active store', () async {
    final repository = _ScanRepository();
    final container = containerWith(repository, activeStore: null);

    await container.read(scanStateProvider.notifier).decoded('5012345678900');

    expect(
      container.read(scanStateProvider).errorMessageKey,
      LocaleKeys.products_noActiveStore,
    );
    expect(repository.lookups, 0);
  });

  test('permission denial is a state the screen can render, not a dead end', () {
    final container = containerWith(_ScanRepository());

    container.read(scanStateProvider.notifier).cameraDenied();

    expect(container.read(scanStateProvider).permissionDenied, isTrue);
  });
}

final _milk = ProductEntity(
  id: 'p1',
  name: 'Whole Milk 1L',
  unit: ProductUnit.litre,
  barcode: '5012345678900',
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
  batches: [
    ProductBatchEntity(
      id: 'b1',
      productId: 'p1',
      storeId: 'store-a',
      batchCode: '#B-0001',
      purchasedAt: DateTime(2026, 8, 1),
      unitPrice: Decimal.parse('1.10'),
      initialQuantity: Decimal.parse('12'),
      remainingQuantity: Decimal.parse('2'),
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    ),
  ],
);

class _ScanRepository extends FakeProductRepository {
  _ScanRepository({this.known = const {}, this.error})
    : super(latency: Duration.zero);

  final Map<String, ProductEntity> known;
  final Object? error;
  int lookups = 0;

  @override
  Future<ProductEntity?> findByBarcode(String barcode, {required String storeId}) async {
    lookups++;
    if (error != null) throw error!;
    return known[barcode];
  }
}
