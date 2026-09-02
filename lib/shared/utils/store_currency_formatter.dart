import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'package:mine_storage/domain/entities/currency.dart';

/// Money is rendered in the **store's** currency, not the device preference.
///
/// A ledger that formats a Vietnamese shop's takings in dollars because the
/// phone is set to dollars is wrong, and §5.3's rounding keys on the currency's
/// minor units, so this is a correctness concern and not only a display one.
class StoreCurrencyFormatter {
  const StoreCurrencyFormatter({required this.symbol, required this.minorUnits});

  StoreCurrencyFormatter.of(Currency currency)
      : symbol = currency.symbol,
        minorUnits = currency.decimals;

  final String symbol;

  /// VND has none. Never assume two.
  final int minorUnits;

  String format(Decimal amount) {
    final format = NumberFormat.currency(symbol: symbol, decimalDigits: minorUnits);
    // The only acceptable double in the money path: the value is already final
    // and about to become a string. Never feed this back into arithmetic.
    return format.format(amount.toDouble());
  }

  /// Signed, for a ledger row where the direction matters as much as the size.
  String formatSigned(Decimal amount) =>
      amount < Decimal.zero ? format(amount) : '+${format(amount)}';

  /// A ratio rendered as a percentage, to one decimal place.
  String formatMargin(Decimal margin) =>
      '${(margin * Decimal.fromInt(100)).toDouble().toStringAsFixed(1)}%';
}
