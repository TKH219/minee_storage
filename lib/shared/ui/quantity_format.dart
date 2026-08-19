import 'package:intl/intl.dart';

/// Quantities are decimal to three places everywhere, mono and tabular.
String formatQuantity(double value) => value.toStringAsFixed(3);

final NumberFormat _money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

String formatMoney(double value) => _money.format(value);
