import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/services/fefo_allocator.dart';

ProductBatchEntity batch({
  required String id,
  required String expiry,
  String purchased = '2026-08-01',
  String remaining = '5',
  bool isArchived = false,
}) {
  return ProductBatchEntity(
    id: id,
    productId: 'p1',
    purchasedAt: DateTime.parse(purchased),
    unitPrice: Decimal.parse('10.00'),
    expiryDate: DateTime.parse(expiry),
    initialQuantity: Decimal.parse(remaining),
    remainingQuantity: Decimal.parse(remaining),
    createdAt: DateTime.parse(purchased),
    isArchived: isArchived,
  );
}

void main() {
  test('draws entirely from one batch when it covers the request', () {
    final result = FefoAllocator.allocate(
      quantity: Decimal.parse('3'),
      batches: [batch(id: 'b1', expiry: '2026-09-01')],
    );

    expect(result, [
      BatchAllocation(batchId: 'b1', quantity: Decimal.parse('3')),
    ]);
  });

  test('draws from the earliest expiring batch first', () {
    final result = FefoAllocator.allocate(
      quantity: Decimal.parse('2'),
      batches: [
        batch(id: 'later', expiry: '2026-12-01'),
        batch(id: 'sooner', expiry: '2026-09-01'),
      ],
    );

    expect(result.single.batchId, 'sooner');
  });

  test('spans batches in expiry order when one is not enough', () {
    final result = FefoAllocator.allocate(
      quantity: Decimal.parse('7'),
      batches: [
        batch(id: 'later', expiry: '2026-12-01', remaining: '5'),
        batch(id: 'sooner', expiry: '2026-09-01', remaining: '5'),
      ],
    );

    expect(result, [
      BatchAllocation(batchId: 'sooner', quantity: Decimal.parse('5')),
      BatchAllocation(batchId: 'later', quantity: Decimal.parse('2')),
    ]);
  });

  test('consumes exactly to the boundary without a trailing zero allocation', () {
    final result = FefoAllocator.allocate(
      quantity: Decimal.parse('10'),
      batches: [
        batch(id: 'b1', expiry: '2026-09-01', remaining: '5'),
        batch(id: 'b2', expiry: '2026-10-01', remaining: '5'),
      ],
    );

    expect(result, hasLength(2));
    expect(result.last.quantity, Decimal.parse('5'));
  });

  test('breaks an expiry tie with the older purchase date', () {
    final result = FefoAllocator.allocate(
      quantity: Decimal.parse('1'),
      batches: [
        batch(id: 'newer', expiry: '2026-09-01', purchased: '2026-08-05'),
        batch(id: 'older', expiry: '2026-09-01', purchased: '2026-07-05'),
      ],
    );

    expect(result.single.batchId, 'older');
  });

  test('allocates already expired batches first', () {
    final result = FefoAllocator.allocate(
      quantity: Decimal.parse('1'),
      batches: [
        batch(id: 'fresh', expiry: '2026-12-01'),
        batch(id: 'expired', expiry: '2020-01-01'),
      ],
    );

    expect(result.single.batchId, 'expired');
  });

  test('skips depleted batches', () {
    final result = FefoAllocator.allocate(
      quantity: Decimal.parse('1'),
      batches: [
        batch(id: 'empty', expiry: '2026-08-01', remaining: '0'),
        batch(id: 'stocked', expiry: '2026-12-01', remaining: '4'),
      ],
    );

    expect(result.single.batchId, 'stocked');
  });

  test('skips archived batches', () {
    final result = FefoAllocator.allocate(
      quantity: Decimal.parse('1'),
      batches: [
        batch(id: 'archived', expiry: '2026-08-01', isArchived: true),
        batch(id: 'live', expiry: '2026-12-01'),
      ],
    );

    expect(result.single.batchId, 'live');
  });

  test('subtracts decimals exactly across batches', () {
    final result = FefoAllocator.allocate(
      quantity: Decimal.parse('0.3'),
      batches: [
        batch(id: 'b1', expiry: '2026-09-01', remaining: '0.1'),
        batch(id: 'b2', expiry: '2026-10-01', remaining: '0.5'),
      ],
    );

    expect(result, [
      BatchAllocation(batchId: 'b1', quantity: Decimal.parse('0.1')),
      BatchAllocation(batchId: 'b2', quantity: Decimal.parse('0.2')),
    ]);
    expect(result.last.quantity.toString(), '0.2');
  });

  test('throws InsufficientStockException when the request exceeds stock', () {
    expect(
      () => FefoAllocator.allocate(
        quantity: Decimal.parse('9'),
        batches: [batch(id: 'b1', expiry: '2026-09-01', remaining: '5')],
      ),
      throwsA(isA<InsufficientStockException>()),
    );
  });

  test('reports requested and available on insufficient stock', () {
    try {
      FefoAllocator.allocate(
        quantity: Decimal.parse('9'),
        batches: [batch(id: 'b1', expiry: '2026-09-01', remaining: '5')],
      );
      fail('expected InsufficientStockException');
    } on InsufficientStockException catch (e) {
      expect(e.requested, Decimal.parse('9'));
      expect(e.available, Decimal.parse('5'));
    }
  });

  test('throws InsufficientStockException when there are no batches at all', () {
    expect(
      () => FefoAllocator.allocate(quantity: Decimal.one, batches: const []),
      throwsA(isA<InsufficientStockException>()),
    );
  });

  test('rejects a zero request', () {
    expect(
      () => FefoAllocator.allocate(
        quantity: Decimal.zero,
        batches: [batch(id: 'b1', expiry: '2026-09-01')],
      ),
      throwsArgumentError,
    );
  });

  test('rejects a negative request', () {
    expect(
      () => FefoAllocator.allocate(
        quantity: -Decimal.one,
        batches: [batch(id: 'b1', expiry: '2026-09-01')],
      ),
      throwsArgumentError,
    );
  });
}
