import 'package:decimal/decimal.dart';

enum QuantityInputMode { stepper, keypad }

enum ProductUnit {
  piece('piece'),
  kg('kg'),
  g('g'),
  litre('litre'),
  ml('ml'),
  box('box'),
  pack('pack');

  const ProductUnit(this.code);

  final String code;

  static ProductUnit fromCode(String? code) {
    for (final unit in ProductUnit.values) {
      if (unit.code == code) return unit;
    }
    return ProductUnit.piece;
  }

  bool get isCount => this == piece || this == box || this == pack;

  QuantityInputMode get inputMode =>
      isCount ? QuantityInputMode.stepper : QuantityInputMode.keypad;

  /// Half a box is not a thing anyone can hand over, so a count unit refuses a
  /// fraction at the point of entry rather than at save.
  bool acceptsQuantity(Decimal value) => !isCount || value.isInteger;
}
