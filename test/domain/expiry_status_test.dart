import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/domain/entities/expiry_status.dart';

void main() {
  final today = DateTime(2026, 8, 20);

  ExpiryStatus statusOn(DateTime? expiry, {bool hasStock = true}) =>
      expiryStatusFor(nearestExpiry: expiry, hasStock: hasStock, today: today);

  test('no remaining stock always reads as none', () {
    expect(statusOn(DateTime(2026, 8, 1), hasStock: false), ExpiryStatus.none);
    expect(statusOn(null, hasStock: false), ExpiryStatus.none);
  });

  test('stock with no tracked expiry is healthy, not none', () {
    expect(statusOn(null), ExpiryStatus.healthy);
  });

  test('day 30 is still expiring soon, day 31 is healthy', () {
    expect(statusOn(today.add(const Duration(days: 30))), ExpiryStatus.expiringSoon);
    expect(statusOn(today.add(const Duration(days: 31))), ExpiryStatus.healthy);
  });

  test('today counts as expired, tomorrow does not', () {
    expect(statusOn(today), ExpiryStatus.expired);
    expect(statusOn(today.subtract(const Duration(days: 1))), ExpiryStatus.expired);
    expect(statusOn(today.add(const Duration(days: 1))), ExpiryStatus.expiringSoon);
  });
}
