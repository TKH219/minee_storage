import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/services/attention_alerts.dart';

Decimal d(String value) => Decimal.parse(value);

final today = DateTime(2026, 8, 19);

ProductBatchEntity lot({
  String id = 'b1',
  String productId = 'p1',
  String price = '2.00',
  String remaining = '4',
  DateTime? expiry,
  DateTime? deletedAt,
}) {
  return ProductBatchEntity(
    id: id,
    productId: productId,
    storeId: 'store-a',
    batchCode: '#B-0001',
    purchasedAt: today.subtract(const Duration(days: 30)),
    unitPrice: d(price),
    initialQuantity: d('10'),
    remainingQuantity: d(remaining),
    expiryDate: expiry,
    deletedAt: deletedAt,
    createdAt: today,
    updatedAt: today,
  );
}

ProductEntity product({
  String id = 'p1',
  String name = 'Whole Milk 1L',
  List<ProductBatchEntity> batches = const [],
  DateTime? deletedAt,
}) {
  return ProductEntity(
    id: id,
    name: name,
    createdAt: today,
    updatedAt: today,
    deletedAt: deletedAt,
    batches: batches,
  );
}

void main() {
  group('AttentionAlerts.from', () {
    test('an empty catalogue produces no alerts, not three empty ones', () {
      expect(AttentionAlerts.from(const [], today: today), isEmpty);
    });

    test('a healthy catalogue produces no alerts', () {
      final alerts = AttentionAlerts.from([
        product(
          batches: [lot(expiry: today.add(const Duration(days: 200)))],
        ),
      ], today: today);

      expect(alerts, isEmpty);
    });

    test('expired products are named in one alert', () {
      final alerts = AttentionAlerts.from([
        product(
          id: 'p1',
          name: 'Greek Yoghurt',
          batches: [lot(expiry: today.subtract(const Duration(days: 2)))],
        ),
        product(
          id: 'p2',
          name: 'Rye Crackers',
          batches: [lot(id: 'b2', productId: 'p2', expiry: today.subtract(const Duration(days: 1)))],
        ),
      ], today: today);

      final expired = alerts.single;
      expect(expired.kind, AttentionAlertKind.expired);
      expect(expired.count, 2);
      expect(expired.productNames, ['Greek Yoghurt', 'Rye Crackers']);
    });

    test('products expiring within thirty days carry their cost', () {
      final alerts = AttentionAlerts.from([
        product(
          batches: [
            lot(price: '1.10', remaining: '2', expiry: today.add(const Duration(days: 3))),
            lot(
              id: 'b2',
              price: '1.25',
              remaining: '4',
              expiry: today.add(const Duration(days: 24)),
            ),
          ],
        ),
      ], today: today);

      final expiring = alerts.single;
      expect(expiring.kind, AttentionAlertKind.expiringSoon);
      expect(expiring.count, 1);
      expect(expiring.valueAtCost, d('7.20'));
    });

    test('a lot beyond the thirty-day window adds nothing to the cost', () {
      final alerts = AttentionAlerts.from([
        product(
          batches: [
            lot(price: '1.10', remaining: '2', expiry: today.add(const Duration(days: 3))),
            lot(
              id: 'b2',
              price: '99.00',
              remaining: '5',
              expiry: today.add(const Duration(days: 400)),
            ),
          ],
        ),
      ], today: today);

      expect(alerts.single.valueAtCost, d('2.20'));
    });

    test('a product holding nothing is out of stock, not expired', () {
      final alerts = AttentionAlerts.from([
        product(
          name: 'Cheddar Block 400g',
          batches: [
            lot(remaining: '0', expiry: today.subtract(const Duration(days: 5))),
          ],
        ),
      ], today: today);

      final outOfStock = alerts.single;
      expect(outOfStock.kind, AttentionAlertKind.outOfStock);
      expect(outOfStock.productNames, ['Cheddar Block 400g']);
      expect(outOfStock.valueAtCost, isNull);
    });

    test('a product with no lots at all is out of stock', () {
      final alerts = AttentionAlerts.from([product(name: 'Dish Soap')], today: today);
      expect(alerts.single.kind, AttentionAlertKind.outOfStock);
    });

    test('archived products are excluded from every alert', () {
      final alerts = AttentionAlerts.from([
        product(
          deletedAt: today,
          batches: [lot(expiry: today.subtract(const Duration(days: 2)))],
        ),
      ], today: today);

      expect(alerts, isEmpty);
    });

    test('an archived lot does not make its product expire', () {
      final alerts = AttentionAlerts.from([
        product(
          batches: [
            lot(expiry: today.subtract(const Duration(days: 2)), deletedAt: today),
            lot(id: 'b2', expiry: today.add(const Duration(days: 200))),
          ],
        ),
      ], today: today);

      expect(alerts, isEmpty);
    });

    test('a product with no expiry dates is neither expired nor expiring', () {
      final alerts = AttentionAlerts.from([
        product(batches: [lot()]),
      ], today: today);

      expect(alerts, isEmpty);
    });

    test('alerts come back in the design\'s order', () {
      final alerts = AttentionAlerts.from([
        product(
          id: 'p1',
          name: 'Gone',
          batches: [lot(expiry: today.subtract(const Duration(days: 1)))],
        ),
        product(
          id: 'p2',
          name: 'Soon',
          batches: [
            lot(id: 'b2', productId: 'p2', expiry: today.add(const Duration(days: 9))),
          ],
        ),
        product(
          id: 'p3',
          name: 'Empty',
          batches: [lot(id: 'b3', productId: 'p3', remaining: '0')],
        ),
      ], today: today);

      expect(alerts.map((alert) => alert.kind), [
        AttentionAlertKind.expired,
        AttentionAlertKind.expiringSoon,
        AttentionAlertKind.outOfStock,
      ]);
    });
  });
}
