import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';

Decimal d(String value) => Decimal.parse(value);

void main() {
  late FakeProductRepository products;
  late FakeSaleRepository sales;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
    sales = FakeSaleRepository(products, latency: Duration.zero);
  });

  Future<SaleDraft> draftForOliveOil(String quantity, {String price = '20.00'}) async {
    final product = await products.getProduct('p1', storeId: 'store-a');
    final allocations = await sales.previewAllocation(
      productId: 'p1',
      storeId: 'store-a',
      quantity: d(quantity),
    );
    return SaleDraft(
      lines: [
        SaleDraftLine(
          productId: product.id,
          productName: product.name,
          unit: product.unit,
          quantity: d(quantity),
          unitSellPrice: d(price),
          allocations: allocations,
        ),
      ],
    );
  }

  group('previewAllocation', () {
    test('splits FEFO and snapshots each lot at its own cost', () async {
      final allocations = await sales.previewAllocation(
        productId: 'p1',
        storeId: 'store-a',
        quantity: d('4'),
      );

      expect(allocations.map((a) => a.batchId), ['b1', 'b2']);
      expect(allocations.first.quantity, d('2'));
      expect(allocations.first.unitCost, d('11.50'));
      expect(allocations.first.remainingAfter, Decimal.zero);
      expect(allocations.first.emptiesLot, isTrue);
      expect(allocations.last.quantity, d('2'));
      expect(allocations.last.unitCost, d('12.75'));
      expect(allocations.last.remainingAfter, d('4'));
    });

    test('carries each lot\'s code and expiry so the sheet can name them', () async {
      final allocations = await sales.previewAllocation(
        productId: 'p1',
        storeId: 'store-a',
        quantity: d('2'),
      );

      expect(allocations.single.batchCode, '#B-0001');
      expect(allocations.single.expiryDate, isNotNull);
    });

    test('refuses to preview more than the store holds', () async {
      await expectLater(
        () => sales.previewAllocation(
          productId: 'p1',
          storeId: 'store-a',
          quantity: d('99'),
        ),
        throwsA(isA<InsufficientStockException>()),
      );
    });

    test('deducts nothing', () async {
      await sales.previewAllocation(
        productId: 'p1',
        storeId: 'store-a',
        quantity: d('4'),
      );
      final product = await products.getProduct('p1', storeId: 'store-a');
      expect(product.totalRemaining, d('8'));
    });
  });

  group('confirm', () {
    test('a draft on its own deducts nothing and records nothing', () async {
      await draftForOliveOil('4');

      final product = await products.getProduct('p1', storeId: 'store-a');
      expect(product.totalRemaining, d('8'));
      expect(await sales.salesFor(storeId: 'store-a'), isEmpty);
    });

    test('deducts once, across exactly the allocated lots', () async {
      final draft = await draftForOliveOil('4');
      final sale = await sales.confirm(draft, storeId: 'store-a');

      final product = await products.getProduct('p1', storeId: 'store-a');
      expect(product.totalRemaining, d('4'));
      expect(
        product.batches.firstWhere((b) => b.id == 'b1').remainingQuantity,
        Decimal.zero,
      );
      expect(product.batches.firstWhere((b) => b.id == 'b2').remainingQuantity, d('4'));
      expect(sale.deductedLotCount, 2);
      expect(sale.storeId, 'store-a');
      expect(sale.totals.buyerTotal, d('80.00'));
      expect(sale.totals.cogs, d('48.50'));
      expect((await sales.salesFor(storeId: 'store-a')).single.id, sale.id);
    });

    test('freezes the draft\'s lines onto the sale', () async {
      final sale = await sales.confirm(await draftForOliveOil('2'), storeId: 'store-a');

      expect(sale.lines.single.productName, 'Olive oil 1L');
      expect(sale.lines.single.quantity, d('2'));
      expect(sale.lines.single.allocations.single.unitCost, d('11.50'));
    });

    test('a second sale deducts again — confirming is not idempotent', () async {
      await sales.confirm(await draftForOliveOil('2'), storeId: 'store-a');
      await sales.confirm(await draftForOliveOil('2'), storeId: 'store-a');

      final product = await products.getProduct('p1', storeId: 'store-a');
      expect(product.totalRemaining, d('4'));
      expect(await sales.salesFor(storeId: 'store-a'), hasLength(2));
    });

    test('a confirm that outruns stock deducts nothing at all', () async {
      final draft = await draftForOliveOil('4');
      await products.consume(
        'p1',
        [BatchAllocation(batchId: 'b1', quantity: d('2'))],
        storeId: 'store-a',
      );

      await expectLater(
        () => sales.confirm(draft, storeId: 'store-a'),
        throwsA(isA<InsufficientStockException>()),
      );

      final product = await products.getProduct('p1', storeId: 'store-a');
      expect(product.batches.firstWhere((b) => b.id == 'b2').remainingQuantity, d('6'));
      expect(await sales.salesFor(storeId: 'store-a'), isEmpty);
    });

    test('a shortfall on the second line leaves the first line undeducted', () async {
      final oil = await draftForOliveOil('2');
      final riceAllocations = await sales.previewAllocation(
        productId: 'p3',
        storeId: 'store-a',
        quantity: d('2'),
      );
      final draft = SaleDraft(
        lines: [
          ...oil.lines,
          SaleDraftLine(
            productId: 'p3',
            productName: 'Basmati rice 5kg',
            unit: ProductUnit.kg,
            quantity: d('2'),
            unitSellPrice: d('12.50'),
            allocations: riceAllocations,
          ),
        ],
      );

      await products.consume(
        'p3',
        [BatchAllocation(batchId: 'b4', quantity: d('2'))],
        storeId: 'store-a',
      );

      await expectLater(
        () => sales.confirm(draft, storeId: 'store-a'),
        throwsA(isA<InsufficientStockException>()),
      );

      final oliveOil = await products.getProduct('p1', storeId: 'store-a');
      expect(oliveOil.totalRemaining, d('8'));
    });

    test('an empty draft is refused', () async {
      await expectLater(
        () => sales.confirm(const SaleDraft(), storeId: 'store-a'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('sale codes are sequential and never reused', () async {
      final first = await sales.confirm(await draftForOliveOil('1'), storeId: 'store-a');
      final second = await sales.confirm(await draftForOliveOil('1'), storeId: 'store-a');

      expect(first.code, '#1042');
      expect(second.code, '#1043');
      expect(first.id, isNot(second.id));
    });

    test('the chosen payment method reaches the sale and moves no figure', () async {
      final draft = (await draftForOliveOil('2')).copyWith(
        paymentMethod: PaymentMethod.card,
      );
      final sale = await sales.confirm(draft, storeId: 'store-a');

      expect(sale.paymentMethod, PaymentMethod.card);
      expect(sale.totals.buyerTotal, draft.totals.buyerTotal);
    });
  });

  group('reads', () {
    test('salesFor is scoped to one store and newest first', () async {
      await sales.confirm(await draftForOliveOil('1'), storeId: 'store-a');
      await sales.confirm(await draftForOliveOil('1'), storeId: 'store-a');

      final recorded = await sales.salesFor(storeId: 'store-a');
      expect(recorded, hasLength(2));
      expect(recorded.first.code, '#1043');
      expect(await sales.salesFor(storeId: 'store-b'), isEmpty);
    });

    test('recentlySoldProductIds is newest first and free of duplicates', () async {
      await sales.confirm(await draftForOliveOil('1'), storeId: 'store-a');
      await sales.confirm(await draftForOliveOil('1'), storeId: 'store-a');

      expect(await sales.recentlySoldProductIds(storeId: 'store-a'), ['p1']);
    });

    test('recentlySoldProductIds honours its limit', () async {
      await sales.confirm(await draftForOliveOil('1'), storeId: 'store-a');
      expect(
        await sales.recentlySoldProductIds(storeId: 'store-a', limit: 0),
        isEmpty,
      );
    });
  });
}
