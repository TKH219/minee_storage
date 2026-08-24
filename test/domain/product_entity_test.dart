import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

ProductBatchEntity batch({
  String id = 'b1',
  String? expiry = '2026-09-01',
  String purchased = '2026-08-01',
  String price = '10.00',
  String initial = '5',
  String remaining = '5',
  bool isArchived = false,
}) {
  return ProductBatchEntity(
    id: id,
    productId: 'p1',
    purchasedAt: DateTime.parse(purchased),
    unitPrice: Decimal.parse(price),
    expiryDate: expiry == null ? null : DateTime.parse(expiry),
    initialQuantity: Decimal.parse(initial),
    remainingQuantity: Decimal.parse(remaining),
    createdAt: DateTime.parse(purchased),
    isArchived: isArchived,
  );
}

ProductEntity product(List<ProductBatchEntity> batches) {
  return ProductEntity(
    id: 'p1',
    name: 'Olive oil',
    createdAt: DateTime.parse('2026-07-01'),
    updatedAt: DateTime.parse('2026-07-01'),
    batches: batches,
  );
}

void main() {
  group('ProductBatchEntity', () {
    test('totalCost is unit price times initial quantity', () {
      expect(batch(price: '2.50', initial: '4').totalCost, Decimal.parse('10.00'));
    });

    test('hasStock is false once the batch is depleted', () {
      expect(batch(remaining: '0').hasStock, isFalse);
      expect(batch(remaining: '0.001').hasStock, isTrue);
    });
  });

  group('totalRemaining', () {
    test('sums remaining quantity across batches', () {
      final p = product([
        batch(id: 'b1', remaining: '2.5'),
        batch(id: 'b2', remaining: '1.25'),
      ]);

      expect(p.totalRemaining, Decimal.parse('3.75'));
    });

    test('adds decimals exactly, without floating point drift', () {
      final p = product([
        batch(id: 'b1', remaining: '0.1'),
        batch(id: 'b2', remaining: '0.2'),
      ]);

      expect(p.totalRemaining, Decimal.parse('0.3'));
      expect(p.totalRemaining.toString(), '0.3');
    });

    test('ignores archived batches', () {
      final p = product([
        batch(id: 'b1', remaining: '2'),
        batch(id: 'b2', remaining: '9', isArchived: true),
      ]);

      expect(p.totalRemaining, Decimal.parse('2'));
    });

    test('is zero when there are no batches', () {
      expect(product([]).totalRemaining, Decimal.zero);
    });
  });

  group('nearestExpiry', () {
    test('is the earliest expiry among batches that still have stock', () {
      final p = product([
        batch(id: 'b1', expiry: '2026-12-01'),
        batch(id: 'b2', expiry: '2026-09-15'),
        batch(id: 'b3', expiry: '2026-10-01'),
      ]);

      expect(p.nearestExpiry, DateTime.parse('2026-09-15'));
    });

    test('skips depleted batches even when they expire soonest', () {
      final p = product([
        batch(id: 'b1', expiry: '2026-08-10', remaining: '0'),
        batch(id: 'b2', expiry: '2026-11-01', remaining: '3'),
      ]);

      expect(p.nearestExpiry, DateTime.parse('2026-11-01'));
    });

    test('is null when nothing remains', () {
      final p = product([batch(remaining: '0')]);

      expect(p.nearestExpiry, isNull);
    });
  });

  group('latestUnitPrice', () {
    test('is the price of the most recently purchased batch', () {
      final p = product([
        batch(id: 'b1', purchased: '2026-07-01', price: '8.00'),
        batch(id: 'b2', purchased: '2026-08-01', price: '9.50'),
        batch(id: 'b3', purchased: '2026-07-15', price: '8.75'),
      ]);

      expect(p.latestUnitPrice, Decimal.parse('9.50'));
    });

    test('considers depleted batches, because price history outlives stock', () {
      final p = product([
        batch(id: 'b1', purchased: '2026-08-01', price: '9.50', remaining: '0'),
      ]);

      expect(p.latestUnitPrice, Decimal.parse('9.50'));
    });

    test('is null when there are no batches', () {
      expect(product([]).latestUnitPrice, isNull);
    });
  });

  group('statusOn', () {
    final now = DateTime.parse('2026-08-06');

    test('is expired when the nearest expiry has passed', () {
      final p = product([batch(expiry: '2026-08-05')]);

      expect(p.statusOn(now), ExpiryStatus.expired);
    });

    test('is expired at exactly zero days remaining', () {
      final p = product([batch(expiry: '2026-08-06')]);

      expect(p.statusOn(now), ExpiryStatus.expired);
    });

    test('is critical inside the seven day window', () {
      final p = product([batch(expiry: '2026-08-12')]);

      expect(p.statusOn(now), ExpiryStatus.critical);
    });

    test('is warning at exactly the 30 day boundary', () {
      final p = product([batch(expiry: '2026-09-05')]);

      expect(p.statusOn(now), ExpiryStatus.warning);
      expect(p.statusOn(now).isExpiringSoon, isTrue);
    });

    test('is ok one day past the 30 day boundary', () {
      final p = product([batch(expiry: '2026-09-07')]);

      expect(p.statusOn(now), ExpiryStatus.ok);
    });

    test('reads as no stock when nothing remains', () {
      final p = product([batch(remaining: '0')]);

      expect(p.statusOn(now), ExpiryStatus.none);
    });

    test('is ok when stock is held but nothing is dated', () {
      final p = product([batch(expiry: null)]);

      expect(p.statusOn(now), ExpiryStatus.ok);
    });
  });
}
