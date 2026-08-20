import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/domain/entities/expiry_status.dart';
import 'package:mine_storage/domain/entities/lot.dart';
import 'package:mine_storage/domain/entities/product.dart';

import '../support/localization_test_harness.dart';

Lot lot({
  required String id,
  DateTime? expiresOn,
  required DateTime purchasedOn,
  required double unitPrice,
  required double initial,
  required double remaining,
}) => Lot(
      id: id,
      productId: 'p1',
      purchasedOn: purchasedOn,
      expiresOn: expiresOn,
      unitPrice: unitPrice,
      initialQuantity: initial,
      remainingQuantity: remaining,
    );

void main() {
  setUp(useLocale);

  final today = DateTime(2026, 8, 20);

  test('lot total is price times initial quantity, not remaining', () {
    final l = lot(id: 'l1', purchasedOn: DateTime(2026, 8, 8), unitPrice: 1.10, initial: 12, remaining: 2);
    expect(l.lotTotal, closeTo(13.20, 0.001));
  });

  test('header figures are derived from lots', () {
    final p = Product(id: 'p1', storeId: 's1', name: 'Whole Milk 1L', lots: [
      lot(id: 'l1', purchasedOn: DateTime(2026, 8, 8), expiresOn: DateTime(2026, 8, 22), unitPrice: 1.10, initial: 12, remaining: 2),
      lot(id: 'l2', purchasedOn: DateTime(2026, 8, 15), expiresOn: DateTime(2026, 9, 12), unitPrice: 1.25, initial: 10, remaining: 8),
    ]);
    expect(p.totalRemaining, 10);
    expect(p.nearestExpiry, DateTime(2026, 8, 22));
    expect(p.latestUnitPrice, 1.25);
  });

  test('a depleted expired lot does not make the product read expired', () {
    final p = Product(id: 'p1', storeId: 's1', name: 'Cheddar Block 400g', lots: [
      lot(id: 'l1', purchasedOn: DateTime(2026, 7, 1), expiresOn: DateTime(2026, 8, 1), unitPrice: 4.15, initial: 5, remaining: 0),
    ]);
    expect(p.hasStock, isFalse);
    expect(p.nearestExpiry, isNull);
    expect(p.statusOn(today), ExpiryStatus.none);
    expect(p.latestUnitPrice, 4.15);
  });

  test('FEFO orders dated lots by expiry and puts undated lots last', () {
    final p = Product(id: 'p1', storeId: 's1', name: 'Mixed', lots: [
      lot(id: 'undated', purchasedOn: DateTime(2026, 3, 14), unitPrice: 2.20, initial: 21, remaining: 21),
      lot(id: 'far', purchasedOn: DateTime(2026, 1, 1), expiresOn: DateTime(2027, 1, 1), unitPrice: 2.05, initial: 5, remaining: 5),
      lot(id: 'near', purchasedOn: DateTime(2026, 8, 1), expiresOn: DateTime(2026, 8, 22), unitPrice: 2.00, initial: 3, remaining: 3),
    ]);
    expect(p.lotsFefo.map((l) => l.id), ['near', 'far', 'undated']);
  });

  test('undated lots order among themselves by purchase date', () {
    final p = Product(id: 'p1', storeId: 's1', name: 'Sea Salt 1kg', lots: [
      lot(id: 'later', purchasedOn: DateTime(2026, 6, 1), unitPrice: 1, initial: 4, remaining: 4),
      lot(id: 'earlier', purchasedOn: DateTime(2026, 2, 1), unitPrice: 1, initial: 4, remaining: 4),
    ]);
    expect(p.lotsFefo.map((l) => l.id), ['earlier', 'later']);
    expect(p.statusOn(today), ExpiryStatus.ok);
  });
}
