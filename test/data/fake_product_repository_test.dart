import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  test('seeds products so the app has something to render', () async {
    final repository = FakeProductRepository();

    final page = await repository.getProducts(storeId: 'store-a', filter: const ProductFilter(), page: 1);

    expect(page.items, isNotEmpty);
  });

  test('filters by name, case-insensitively', () async {
    final repository = FakeProductRepository();

    final page = await repository.getProducts(
      storeId: 'store-a',
      filter: const ProductFilter(query: 'OLIVE'),
      page: 1,
    );

    expect(page.items, isNotEmpty);
    expect(page.items.every((p) => p.name.toLowerCase().contains('olive')), isTrue);
  });

  test('hides archived products from the default list and shows them under archived', () async {
    final repository = FakeProductRepository();
    final first =
        (await repository.getProducts(storeId: 'store-a', filter: const ProductFilter(), page: 1)).items.first;

    await repository.archiveProduct(first.id, storeId: 'store-a');

    final defaultPage =
        await repository.getProducts(storeId: 'store-a', filter: const ProductFilter(), page: 1);
    final archivedPage = await repository.getProducts(
      storeId: 'store-a',
      filter: const ProductFilter(quickFilter: ProductQuickFilter.archived),
      page: 1,
    );

    expect(defaultPage.items.map((p) => p.id), isNot(contains(first.id)));
    expect(archivedPage.items.map((p) => p.id), contains(first.id));
  });

  test('restores an archived product back into the default list', () async {
    final repository = FakeProductRepository();
    final first =
        (await repository.getProducts(storeId: 'store-a', filter: const ProductFilter(), page: 1)).items.first;

    await repository.archiveProduct(first.id, storeId: 'store-a');
    await repository.restoreProduct(first.id, storeId: 'store-a');

    final page = await repository.getProducts(storeId: 'store-a', filter: const ProductFilter(), page: 1);
    expect(page.items.map((p) => p.id), contains(first.id));
  });

  test('finds a seeded product by barcode and misses on an unknown one', () async {
    final repository = FakeProductRepository();
    final seeded = (await repository.getProducts(storeId: 'store-a', filter: const ProductFilter(), page: 1))
        .items
        .firstWhere((p) => p.barcode != null);

    expect(
      (await repository.findByBarcode(seeded.barcode!, storeId: 'store-a'))?.id,
      seeded.id,
    );
    expect(await repository.findByBarcode('0000000000000', storeId: 'store-a'), isNull);
  });

  test('consume deducts from the allocated batches', () async {
    final repository = FakeProductRepository();
    final product = (await repository.getProducts(storeId: 'store-a', filter: const ProductFilter(), page: 1))
        .items
        .firstWhere((p) => p.availableBatches.isNotEmpty);
    final batch = product.availableBatches.first;
    final before = batch.remainingQuantity;

    final updated = await repository.consume(
      product.id,
      [BatchAllocation(batchId: batch.id, quantity: Decimal.one)],
      storeId: 'store-a',
    );

    final after = updated.batches.firstWhere((b) => b.id == batch.id).remainingQuantity;
    expect(after, before - Decimal.one);
  });

  test('adding a batch increases total remaining', () async {
    final repository = FakeProductRepository();
    final product =
        (await repository.getProducts(storeId: 'store-a', filter: const ProductFilter(), page: 1)).items.first;
    final before = product.totalRemaining;

    final updated = await repository.addBatch(
      product.id,
      BatchDraft(
        storeId: 'store-a',
        purchasedAt: DateTime.utc(2026, 8, 1),
        unitPrice: Decimal.parse('3.00'),
        expiryDate: DateTime.utc(2026, 12, 1),
        initialQuantity: Decimal.parse('4'),
      ),
    );

    expect(updated.totalRemaining, before + Decimal.parse('4'));
  });

  group('editing a lot moves what is left only by the received delta', () {
    Future<(FakeProductRepository, ProductEntity, ProductBatchEntity)> stocked() async {
      final repository = FakeProductRepository();
      final seeded =
          (await repository.getProducts(storeId: 'store-a', filter: const ProductFilter(), page: 1))
              .items
              .first;
      final withLot = await repository.addBatch(
        seeded.id,
        BatchDraft(
          storeId: 'store-a',
          purchasedAt: DateTime.utc(2026, 8, 1),
          unitPrice: Decimal.parse('3.00'),
          initialQuantity: Decimal.parse('20'),
        ),
      );
      final batch = withLot.batches.last;
      final consumed = await repository.consume(
        seeded.id,
        [BatchAllocation(batchId: batch.id, quantity: Decimal.parse('5'))],
        storeId: 'store-a',
      );
      return (repository, seeded, consumed.batches.firstWhere((b) => b.id == batch.id));
    }

    BatchDraft draftOf(String quantity) => BatchDraft(
      storeId: 'store-a',
      purchasedAt: DateTime.utc(2026, 8, 1),
      unitPrice: Decimal.parse('3.00'),
      initialQuantity: Decimal.parse(quantity),
    );

    test('raising the received quantity raises what is left by the same amount', () async {
      final (repository, product, batch) = await stocked();
      expect(batch.remainingQuantity, Decimal.parse('15'));

      final updated = await repository.updateBatch(product.id, batch.id, draftOf('25'));

      final after = updated.batches.firstWhere((b) => b.id == batch.id);
      expect(after.initialQuantity, Decimal.parse('25'));
      expect(after.remainingQuantity, Decimal.parse('20'));
    });

    test('lowering it lowers what is left by the same amount', () async {
      final (repository, product, batch) = await stocked();

      final updated = await repository.updateBatch(product.id, batch.id, draftOf('12'));

      final after = updated.batches.firstWhere((b) => b.id == batch.id);
      expect(after.remainingQuantity, Decimal.parse('7'));
    });

    test('lowering it below what was drawn out is refused, changing nothing', () async {
      final (repository, product, batch) = await stocked();

      await expectLater(
        repository.updateBatch(product.id, batch.id, draftOf('3')),
        throwsA(isA<QuantityBelowDrawnException>()
            .having((e) => e.drawn, 'drawn', Decimal.parse('5'))
            .having((e) => e.received, 'received', Decimal.parse('3'))),
      );

      final reread = await repository.getProduct(product.id, storeId: 'store-a');
      final after = reread.batches.firstWhere((b) => b.id == batch.id);
      expect(after.initialQuantity, Decimal.parse('20'));
      expect(after.remainingQuantity, Decimal.parse('15'));
    });

    test('editing everything but the quantity leaves what is left alone', () async {
      final (repository, product, batch) = await stocked();

      final updated = await repository.updateBatch(
        product.id,
        batch.id,
        BatchDraft(
          storeId: 'store-a',
          purchasedAt: DateTime.utc(2026, 8, 2),
          unitPrice: Decimal.parse('4.00'),
          initialQuantity: Decimal.parse('20'),
          supplier: 'Dairy Co',
        ),
      );

      final after = updated.batches.firstWhere((b) => b.id == batch.id);
      expect(after.unitPrice, Decimal.parse('4.00'));
      expect(after.supplier, 'Dairy Co');
      expect(after.remainingQuantity, Decimal.parse('15'));
    });
  });

  test('exposes the distinct categories in use', () async {
    final repository = FakeProductRepository();

    expect(await repository.getCategories(), contains('Pantry'));
  });
}
