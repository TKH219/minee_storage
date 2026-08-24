import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'package:mine_storage/domain/entities/currency.dart';

/// Display only. Changing the currency re-labels stored prices; it never
/// converts them, because no exchange rates exist in this app.
class CurrencyFormatter {
  const CurrencyFormatter(this.currency);

  final Currency currency;

  String format(Decimal amount) {
    final format = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: currency.decimals,
    );
    // The only acceptable double in the money path: the value is already final
    // and about to become a string. Never feed this back into arithmetic.
    return format.format(amount.toDouble());
  }
}
