import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  test('serialises a product draft, dropping nulls', () {
    final json = ProductRequest.fromDraft(
      const ProductDraft(name: 'Olive oil', category: 'Pantry', unit: ProductUnit.litre),
      storeId: 'store-a',
    ).toJson();

    expect(json['name'], 'Olive oil');
    expect(json['category'], 'Pantry');
    expect(json['unit'], 'litre');
    expect(json['storeId'], 'store-a');
    expect(json.containsKey('barcode'), isFalse);
    expect(json.containsKey('photoUrl'), isFalse);
  });

  test('serialises batch decimals as strings', () {
    final json = BatchRequest.fromDraft(
      BatchDraft(
        storeId: 'store-a',
        purchasedAt: DateTime.utc(2026, 8, 1),
        unitPrice: Decimal.parse('12.75'),
        expiryDate: DateTime.utc(2026, 9, 1),
        initialQuantity: Decimal.parse('2.500'),
      ),
    ).toJson();

    expect(json['unitPrice'], '12.75');
    // Decimal normalises trailing zeros; 2.5 and 2.500 are the same NUMERIC.
    expect(json['initialQuantity'], '2.5');
    expect(json['purchasedAt'], '2026-08-01T00:00:00.000Z');
    expect(json['storeId'], 'store-a');
    // The column is a date, so an instant would make expiry depend on the
    // sender's clock offset.
    expect(json['expiryDate'], '2026-09-01');
    expect(json.containsKey('remainingQuantity'), isFalse);
  });

  test('carries no remaining quantity, however the draft was built', () {
    final json = BatchRequest.fromDraft(
      BatchDraft(
        storeId: 'store-a',
        purchasedAt: DateTime.utc(2026, 8, 1),
        unitPrice: Decimal.parse('1.00'),
        expiryDate: DateTime.utc(2026, 9, 1),
        initialQuantity: Decimal.parse('5'),
      ),
    ).toJson();

    expect(json.containsKey('remainingQuantity'), isFalse);
  });

  test('an undated batch sends no expiry rather than an invented one', () {
    final json = BatchRequest.fromDraft(
      BatchDraft(
        storeId: 'store-a',
        purchasedAt: DateTime.utc(2026, 8, 1),
        unitPrice: Decimal.parse('2.05'),
        initialQuantity: Decimal.parse('21'),
      ),
    ).toJson();

    expect(json.containsKey('expiryDate'), isFalse);
  });
}
