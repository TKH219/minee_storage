import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/product_detail_state.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

import '../../support/localization_test_harness.dart';

import '../../support/active_store_override.dart';

ProductBatchEntity batch({
  required String id,
  String storeId = 'store-a',
  String code = '#B-0001',
  String? expiry,
  String purchased = '2026-08-01',
  String price = '10.00',
  String remaining = '5',
}) {
  return ProductBatchEntity(
    id: id,
    productId: 'p1',
    storeId: storeId,
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

void main() {
  setUp(useLocale);

  ProviderContainer containerWith(
    _StubRepository repository, {
    String? activeStore = 'store-a',
  }) {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
        activeStoreProvider.overrideWith(() => FixedActiveStore(activeStore)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(productDetailStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  group('derived header figures', () {
    test('sum, nearest expiry and latest price come from the store\'s batches', () async {
      final repository = _StubRepository(
        product: _product([
          batch(id: 'b1', code: '#B-0001', expiry: '2026-09-01', purchased: '2026-08-01',
              price: '1.10', remaining: '2'),
          batch(id: 'b2', code: '#B-0002', expiry: '2026-12-01', purchased: '2026-08-15',
              price: '1.25', remaining: '8'),
        ]),
      );
      final container = containerWith(repository);

      await container.read(productDetailStateProvider.notifier).load('p1');
      final state = container.read(productDetailStateProvider);

      expect(state.product!.totalRemaining, Decimal.parse('10'));
      expect(state.product!.nearestExpiry, DateTime.parse('2026-09-01'));
      expect(state.product!.latestUnitPrice, Decimal.parse('1.25'));
    });

    test('a depleted product keeps its price history but reads as no stock', () async {
      final repository = _StubRepository(
        product: _product([batch(id: 'b1', expiry: '2026-09-01', remaining: '0')]),
      );
      final container = containerWith(repository);

      await container.read(productDetailStateProvider.notifier).load('p1');
      final product = container.read(productDetailStateProvider).product!;

      expect(product.hasStock, isFalse);
      expect(product.nearestExpiry, isNull);
      expect(product.latestUnitPrice, Decimal.parse('10.00'));
      expect(product.statusOn(DateTime.parse('2026-08-20')), ExpiryStatus.none);
    });

    test('stock with nothing dated reads ok, never expired', () async {
      final repository = _StubRepository(
        product: _product([batch(id: 'b1', expiry: null, remaining: '4')]),
      );
      final container = containerWith(repository);

      await container.read(productDetailStateProvider.notifier).load('p1');
      final product = container.read(productDetailStateProvider).product!;

      expect(product.nearestExpiry, isNull);
      expect(product.statusOn(DateTime.parse('2026-08-20')), ExpiryStatus.ok);
    });
  });

  group('lot ordering', () {
    test('earliest expiry first, so the top lot is the one Use will draw', () async {
      final repository = _StubRepository(
        product: _product([
          batch(id: 'later', code: '#B-0002', expiry: '2026-12-01'),
          batch(id: 'sooner', code: '#B-0001', expiry: '2026-09-01'),
        ]),
      );
      final container = containerWith(repository);

      await container.read(productDetailStateProvider.notifier).load('p1');

      expect(
        container.read(productDetailStateProvider).orderedBatches.map((b) => b.id),
        ['sooner', 'later'],
      );
    });

    test('undated lots sort last, behind every dated one', () async {
      final repository = _StubRepository(
        product: _product([
          batch(id: 'undated', code: '#B-0001', expiry: null, purchased: '2026-01-01'),
          batch(id: 'dated', code: '#B-0002', expiry: '2026-12-01'),
        ]),
      );
      final container = containerWith(repository);

      await container.read(productDetailStateProvider.notifier).load('p1');

      expect(
        container.read(productDetailStateProvider).orderedBatches.map((b) => b.id),
        ['dated', 'undated'],
      );
    });

    test('depleted lots stay visible in the history', () async {
      final repository = _StubRepository(
        product: _product([
          batch(id: 'live', code: '#B-0001', expiry: '2026-12-01', remaining: '3'),
          batch(id: 'empty', code: '#B-0002', expiry: '2026-09-01', remaining: '0'),
        ]),
      );
      final container = containerWith(repository);

      await container.read(productDetailStateProvider.notifier).load('p1');

      expect(
        container.read(productDetailStateProvider).orderedBatches.map((b) => b.id),
        containsAll(['live', 'empty']),
      );
    });
  });

  group('other stores', () {
    test('names only the stores other than the one being viewed', () async {
      final repository = _StubRepository(
        product: _product([batch(id: 'b1', expiry: '2026-12-01')]),
        holdings: [
          StoreHolding(
            storeId: 'store-a',
            storeName: 'Shop One',
            remaining: Decimal.parse('10'),
            latestUnitPrice: Decimal.parse('1.25'),
          ),
          StoreHolding(
            storeId: 'store-b',
            storeName: 'Shop Two',
            remaining: Decimal.parse('4'),
            latestUnitPrice: Decimal.parse('9.99'),
          ),
        ],
      );
      final container = containerWith(repository);

      await container.read(productDetailStateProvider.notifier).load('p1');

      final others = container.read(productDetailStateProvider).otherStores;
      expect(others.map((h) => h.storeId), ['store-b']);
    });

    test('a holdings failure does not break the screen it decorates', () async {
      final repository = _StubRepository(
        product: _product([batch(id: 'b1', expiry: '2026-12-01')]),
        holdingsError: Exception('offline'),
      );
      final container = containerWith(repository);

      await container.read(productDetailStateProvider.notifier).load('p1');
      final state = container.read(productDetailStateProvider);

      expect(state.isLoaded, isTrue);
      expect(state.product, isNotNull);
      expect(state.otherStores, isEmpty);
    });
  });

  group('archive and restore', () {
    test('archiving keeps every lot and its cost', () async {
      final repository = _StubRepository(
        product: _product([batch(id: 'b1', expiry: '2026-12-01', price: '1.25')]),
      );
      final container = containerWith(repository);
      final notifier = container.read(productDetailStateProvider.notifier);
      await notifier.load('p1');

      await notifier.archive();
      final product = container.read(productDetailStateProvider).product!;

      expect(product.archived, isTrue);
      expect(product.batches.single.unitPrice, Decimal.parse('1.25'));
    });

    test('restore puts it back without losing history', () async {
      final repository = _StubRepository(
        product: _product([batch(id: 'b1', expiry: '2026-12-01', price: '1.25')]),
      );
      final container = containerWith(repository);
      final notifier = container.read(productDetailStateProvider.notifier);
      await notifier.load('p1');

      await notifier.archive();
      await notifier.restore();
      final product = container.read(productDetailStateProvider).product!;

      expect(product.archived, isFalse);
      expect(product.batches.single.unitPrice, Decimal.parse('1.25'));
    });
  });

  test('refuses to load without an active store', () async {
    final repository = _StubRepository(product: _product([]));
    final container = containerWith(repository, activeStore: null);

    await container.read(productDetailStateProvider.notifier).load('p1');

    expect(
      container.read(productDetailStateProvider).errorMessageKey,
      LocaleKeys.products_noActiveStore,
    );
  });
}

ProductEntity _product(List<ProductBatchEntity> batches, {DateTime? deletedAt}) {
  return ProductEntity(
    id: 'p1',
    name: 'Whole Milk 1L',
    unit: ProductUnit.litre,
    createdAt: DateTime.parse('2026-07-01'),
    updatedAt: DateTime.parse('2026-07-01'),
    deletedAt: deletedAt,
    batches: batches,
  );
}

class _StubRepository extends FakeProductRepository {
  _StubRepository({required this.product, this.holdings, this.holdingsError})
    : super(latency: Duration.zero);

  ProductEntity product;
  final List<StoreHolding>? holdings;
  final Object? holdingsError;

  @override
  Future<ProductEntity> getProduct(String id, {required String storeId}) async => product;

  @override
  Future<List<StoreHolding>> getHoldings(String productId) async {
    if (holdingsError != null) throw holdingsError!;
    return holdings ?? const [];
  }

  @override
  Future<ProductEntity> archiveProduct(String id, {required String storeId}) async {
    product = product.copyWith(deletedAt: DateTime.parse('2026-08-20'));
    return product;
  }

  @override
  Future<ProductEntity> restoreProduct(String id, {required String storeId}) async {
    product = product.copyWith(clearDeletedAt: true);
    return product;
  }
}
