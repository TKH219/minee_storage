import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  test('VND is the default and carries no minor units', () {
    expect(Currency.vnd.code, 'VND');
    expect(Currency.vnd.decimals, 0);
    expect(Currency.all.first, Currency.vnd);
  });

  test('every currency code is unique', () {
    final codes = Currency.all.map((c) => c.code).toList();

    expect(codes.toSet().length, codes.length);
  });

  test('an unknown code falls back to VND rather than throwing', () {
    expect(Currency.byCode('XXX'), Currency.vnd);
    expect(Currency.byCode('USD').decimals, 2);
  });
}
