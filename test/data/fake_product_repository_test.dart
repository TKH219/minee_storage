import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('exposes the distinct categories in use', () async {
    final repository = FakeProductRepository();

    expect(await repository.getCategories(), contains('Pantry'));
  });
}
