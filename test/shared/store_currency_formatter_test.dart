import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/shared/utils/store_currency_formatter.dart';

void main() {
  group('money renders in the store\'s currency, not the device\'s', () {
    test('VND has no minor unit', () {
      const formatter = StoreCurrencyFormatter(symbol: '₫', minorUnits: 0);
      expect(formatter.format(Decimal.parse('386640')), '₫386,640');
    });

    test('a VND figure never grows a fractional tail', () {
      const formatter = StoreCurrencyFormatter(symbol: '₫', minorUnits: 0);
      expect(formatter.format(Decimal.parse('386640')), isNot(contains('.')));
    });

    test('USD carries two', () {
      const formatter = StoreCurrencyFormatter(symbol: r'$', minorUnits: 2);
      expect(formatter.format(Decimal.parse('38.7')), r'$38.70');
      expect(formatter.format(Decimal.parse('38.73')), r'$38.73');
    });

    test('it is built from the store\'s own currency row', () {
      final formatter = StoreCurrencyFormatter.of(Currency.vnd);
      expect(formatter.minorUnits, 0);
      expect(formatter.symbol, '₫');
    });

    test('a signed figure names its direction', () {
      const formatter = StoreCurrencyFormatter(symbol: r'$', minorUnits: 2);
      expect(formatter.formatSigned(Decimal.parse('2.00')), r'+$2.00');
      expect(formatter.formatSigned(Decimal.parse('-1.79')), r'-$1.79');
    });

    test('a margin renders as a percentage', () {
      const formatter = StoreCurrencyFormatter(symbol: r'$', minorUnits: 2);
      expect(formatter.formatMargin(Decimal.parse('0.295775')), '29.6%');
    });
  });
}
