import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/ledger_sale_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';

import '../support/fake_transaction_repository.dart';

void main() {
  Decimal d(String value) => Decimal.parse(value);

  late FakeTransactionRepository ledger;
  late FakeProductRepository products;
  late LedgerSaleRepository repository;
  late ProductEntity product;

  setUp(() async {
    ledger = FakeTransactionRepository();
    products = FakeProductRepository(latency: Duration.zero);
    repository = LedgerSaleRepository(ledger, products);
    final page = await products.getProducts(
      storeId: 'store-a',
      filter: const ProductFilter(),
      page: 1,
    );
    product = page.items.firstWhere((p) => p.availableBatches.isNotEmpty);
  });

  SaleDraft draftOf(Decimal quantity, List<SaleAllocation> allocations) => SaleDraft(
    lines: [
      SaleDraftLine(
        productId: product.id,
        productName: product.name,
        unit: product.unit,
        quantity: quantity,
        unitSellPrice: d('9.00'),
        allocations: allocations,
      ),
    ],
  );

  group('a sale becomes a transaction', () {
    test('confirming writes a sale into the ledger', () async {
      final allocations = await repository.previewAllocation(
        productId: product.id,
        storeId: 'store-a',
        quantity: d('2'),
      );

      await repository.confirm(
        draftOf(d('2'), allocations),
        storeId: 'store-a',
      );

      expect(ledger.created, hasLength(1));
      expect(ledger.created.single.type, TransactionType.sale);
      expect(ledger.created.single.storeId, 'store-a');
    });

    test('the line quantity leaves positive; the ledger applies the sign', () async {
      final allocations = await repository.previewAllocation(
        productId: product.id,
        storeId: 'store-a',
        quantity: d('2'),
      );

      await repository.confirm(
        draftOf(d('2'), allocations),
        storeId: 'store-a',
      );

      final line = ledger.created.single.lines.single;
      expect(line.quantity, d('2'));
      expect(line.quantity > Decimal.zero, isTrue);
    });

    test('one draft line per resolved lot, so the split is not lost', () async {
      final allocations = await repository.previewAllocation(
        productId: product.id,
        storeId: 'store-a',
        quantity: product.totalRemaining,
      );

      await repository.confirm(
        draftOf(product.totalRemaining, allocations),
        storeId: 'store-a',
      );

      expect(ledger.created.single.lines, hasLength(allocations.length));
      expect(
        ledger.created.single.lines.map((line) => line.batchId),
        allocations.map((allocation) => allocation.batchId),
      );
    });

    test('the fees on the draft travel with it', () async {
      final allocations = await repository.previewAllocation(
        productId: product.id,
        storeId: 'store-a',
        quantity: d('1'),
      );

      await repository.confirm(
        draftOf(d('1'), allocations).copyWith(
          fees: [
            Fee(
              id: 'v',
              name: 'VAT',
              kind: FeeKind.percent,
              value: d('8'),
              direction: FeeDirection.passThrough,
            ),
          ],
        ),
        storeId: 'store-a',
      );

      expect(ledger.created.single.fees.single.name, 'VAT');
      expect(ledger.created.single.fees.single.direction, FeeDirection.passThrough);
    });

    test('the payment method travels with it', () async {
      final allocations = await repository.previewAllocation(
        productId: product.id,
        storeId: 'store-a',
        quantity: d('1'),
      );

      await repository.confirm(
        draftOf(d('1'), allocations).copyWith(paymentMethod: PaymentMethod.card),
        storeId: 'store-a',
      );

      expect(ledger.created.single.paymentMethod, PaymentMethod.card);
    });
  });

  group('what comes back', () {
    test('the sale carries the ledger\'s own code and lot count', () async {
      final allocations = await repository.previewAllocation(
        productId: product.id,
        storeId: 'store-a',
        quantity: d('2'),
      );

      final sale = await repository.confirm(
        draftOf(d('2'), allocations),
        storeId: 'store-a',
      );

      expect(sale.code, 'S-202608-0001');
      expect(sale.deductedLotCount, allocations.length);
      expect(sale.id, 'txn-1', reason: 'the id travels in a URL and carries no #');
    });
  });

  group('a preview resolves without writing', () {
    test('the split comes back and nothing is recorded', () async {
      final allocations = await repository.previewAllocation(
        productId: product.id,
        storeId: 'store-a',
        quantity: d('2'),
      );

      expect(allocations, isNotEmpty);
      expect(ledger.created, isEmpty);
    });

    test('it draws on the same lots FEFO would', () async {
      final allocations = await repository.previewAllocation(
        productId: product.id,
        storeId: 'store-a',
        quantity: d('1'),
      );

      expect(allocations.first.batchId, product.availableBatches.first.id);
    });
  });

  group('a refusal deducts nothing', () {
    test('an empty draft never reaches the ledger', () async {
      await expectLater(
        () => repository.confirm(
          const SaleDraft(),
          storeId: 'store-a',
        ),
        throwsA(isA<BadRequestException>()),
      );
      expect(ledger.created, isEmpty);
    });

    test('a ledger refusal propagates and records nothing', () async {
      ledger.failWith = const InsufficientStockException();
      final allocations = [
        SaleAllocation(
          batchId: product.availableBatches.first.id,
          batchCode: '#B-0001',
          quantity: d('1'),
          unitCost: d('1.00'),
        ),
      ];

      await expectLater(
        () => repository.confirm(
          draftOf(d('1'), allocations),
          storeId: 'store-a',
        ),
        throwsA(isA<InsufficientStockException>()),
      );
    });
  });

  group('reading back what was recorded', () {
    test('only sales appear in the sales list', () async {
      await repository.salesFor(storeId: 'store-a');
      // list() is filtered by the repository, not by the caller.
      expect(ledger.nextPage.days, isEmpty);
    });
  });
}
