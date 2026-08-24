import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  test('every unit in the schema round-trips through its code', () {
    for (final unit in ProductUnit.values) {
      expect(ProductUnit.fromCode(unit.code), unit);
    }
    expect(ProductUnit.values.map((u) => u.code).toSet(), {
      'piece', 'kg', 'g', 'litre', 'ml', 'box', 'pack',
    });
  });

  test('an unknown or missing code falls back to piece', () {
    expect(ProductUnit.fromCode(null), ProductUnit.piece);
    expect(ProductUnit.fromCode('crate'), ProductUnit.piece);
  });

  test('counts take a stepper, measures take a keypad', () {
    expect(ProductUnit.piece.inputMode, QuantityInputMode.stepper);
    expect(ProductUnit.box.inputMode, QuantityInputMode.stepper);
    expect(ProductUnit.pack.inputMode, QuantityInputMode.stepper);
    expect(ProductUnit.kg.inputMode, QuantityInputMode.keypad);
    expect(ProductUnit.g.inputMode, QuantityInputMode.keypad);
    expect(ProductUnit.litre.inputMode, QuantityInputMode.keypad);
    expect(ProductUnit.ml.inputMode, QuantityInputMode.keypad);
  });

  test('a count unit refuses a fractional quantity', () {
    expect(ProductUnit.piece.acceptsQuantity(Decimal.parse('3')), isTrue);
    expect(ProductUnit.piece.acceptsQuantity(Decimal.parse('3.5')), isFalse);
    expect(ProductUnit.box.acceptsQuantity(Decimal.parse('0.25')), isFalse);
  });

  test('a measured unit accepts a fraction', () {
    expect(ProductUnit.kg.acceptsQuantity(Decimal.parse('3.5')), isTrue);
    expect(ProductUnit.ml.acceptsQuantity(Decimal.parse('0.125')), isTrue);
  });
}
