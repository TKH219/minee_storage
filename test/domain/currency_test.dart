import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  test('fromRow maps a currencies row', () {
    final currency = Currency.fromRow({
      'code': 'USD',
      'symbol': r'$',
      'decimals': 2,
      'sort_order': 20,
    });

    expect(currency.code, 'USD');
    expect(currency.symbol, r'$');
    expect(currency.decimals, 2);
    expect(currency.sortOrder, 20);
  });

  test('a row missing its precision defaults to two minor units', () {
    final currency = Currency.fromRow({'code': 'XAF', 'symbol': 'F'});

    expect(currency.decimals, 2);
    expect(currency.sortOrder, 0);
  });

  test('VND is the default and carries no minor units', () {
    expect(Currency.vnd.code, 'VND');
    expect(Currency.vnd.symbol, '₫');
    expect(Currency.vnd.decimals, 0);
  });

  test('equality is by value', () {
    const a = Currency(code: 'USD', symbol: r'$', decimals: 2, sortOrder: 20);
    const b = Currency(code: 'USD', symbol: r'$', decimals: 2, sortOrder: 20);

    expect(a, b);
  });
}
