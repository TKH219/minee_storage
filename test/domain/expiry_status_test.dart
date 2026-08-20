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

  test('stock with no tracked expiry is ok, not none', () {
    expect(statusOn(null), ExpiryStatus.ok);
  });

  test('critical is within seven days, inclusive of day 7', () {
    expect(statusOn(today.add(const Duration(days: 3))), ExpiryStatus.critical);
    expect(statusOn(today.add(const Duration(days: 7))), ExpiryStatus.critical);
    expect(statusOn(today.add(const Duration(days: 8))), ExpiryStatus.warning);
  });

  test('warning runs to day 30, ok begins at day 31', () {
    expect(statusOn(today.add(const Duration(days: 9))), ExpiryStatus.warning);
    expect(statusOn(today.add(const Duration(days: 30))), ExpiryStatus.warning);
    expect(statusOn(today.add(const Duration(days: 31))), ExpiryStatus.ok);
  });

  test('today counts as expired, tomorrow does not', () {
    expect(statusOn(today), ExpiryStatus.expired);
    expect(statusOn(today.subtract(const Duration(days: 1))), ExpiryStatus.expired);
    expect(statusOn(today.add(const Duration(days: 1))), ExpiryStatus.critical);
  });

  test('the Expiring soon chip covers both warning and critical', () {
    expect(ExpiryStatus.critical.isExpiringSoon, isTrue);
    expect(ExpiryStatus.warning.isExpiringSoon, isTrue);
    expect(ExpiryStatus.ok.isExpiringSoon, isFalse);
    expect(ExpiryStatus.expired.isExpiringSoon, isFalse);
    expect(ExpiryStatus.none.isExpiringSoon, isFalse);
  });
}
