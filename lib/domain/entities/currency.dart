import 'package:equatable/equatable.dart';

/// A row of `public.currencies` — the currencies a shop can trade in.
class Currency extends Equatable {
  const Currency({
    required this.code,
    required this.symbol,
    required this.decimals,
    this.sortOrder = 0,
  });

  factory Currency.fromRow(Map<String, dynamic> row) => Currency(
    code: row['code'] as String,
    symbol: (row['symbol'] as String?) ?? '',
    decimals: (row['decimals'] as int?) ?? 2,
    sortOrder: (row['sort_order'] as int?) ?? 0,
  );

  final String code;
  final String symbol;

  /// Minor-unit precision. Drives money rounding — VND has none.
  final int decimals;
  final int sortOrder;

  /// The default a new shop is created with, matching `stores.currency`'s own
  /// default. Held in code so the picker has something to show before the
  /// table has loaded — it is not a stand-in for the table.
  static const Currency vnd = Currency(code: 'VND', symbol: '₫', decimals: 0, sortOrder: 10);

  @override
  List<Object?> get props => [code, symbol, decimals, sortOrder];
}
