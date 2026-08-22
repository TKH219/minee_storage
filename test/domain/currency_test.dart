import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  test('VND is the default and carries no minor units', () {
    expect(Currency.vnd.code, 'VND');
    expect(Currency.vnd.symbol, '₫');
    expect(Currency.vnd.decimals, 0);
  });

  test('the default has no generated id, because it was never persisted', () {
    expect(Currency.vnd.id, isEmpty);
  });

  test('equality is by value', () {
    const a = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2, sortOrder: 20);
    const b = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2, sortOrder: 20);

    expect(a, b);
  });

  test('two rows for the same code are still different rows', () {
    const a = Currency(id: 'cur-1', code: 'USD', symbol: r'$', decimals: 2);
    const b = Currency(id: 'cur-2', code: 'USD', symbol: r'$', decimals: 2);

    expect(a, isNot(b));
  });
}
