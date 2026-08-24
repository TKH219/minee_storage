import 'package:decimal/decimal.dart';

import 'package:mine_storage/core/constants.dart';

/// Quantities are decimal to three places everywhere, mono and tabular.
String formatQuantity(Decimal value) =>
    value.toDouble().toStringAsFixed(Constants.quantityDecimalPlaces);
