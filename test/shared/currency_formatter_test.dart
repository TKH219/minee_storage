import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

const usd = Currency(code: 'USD', symbol: r'$', decimals: 2);

void main() {
  test('formats a two-decimal currency to its minor units', () {
    final formatted = const CurrencyFormatter(usd).format(Decimal.parse('12.5'));

    expect(formatted, contains('12.50'));
    expect(formatted, contains(r'$'));
  });

  test('formats a zero-decimal currency without minor units', () {
    final formatted = const CurrencyFormatter(
      Currency.vnd,
    ).format(Decimal.parse('120000'));

    expect(formatted, isNot(contains('.00')));
    expect(formatted, contains('\u20ab'));
  });

  test('formats zero rather than rendering an empty string', () {
    expect(const CurrencyFormatter(usd).format(Decimal.zero), contains('0'));
  });

  test('precision comes from the row, not from the formatter', () {
    const threeDecimals = Currency(code: 'BHD', symbol: '.\u062f.\u0628', decimals: 3);

    expect(
      const CurrencyFormatter(threeDecimals).format(Decimal.parse('1.5')),
      contains('1.500'),
    );
  });
}
