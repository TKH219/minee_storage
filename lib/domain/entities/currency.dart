import 'package:equatable/equatable.dart';

/// The currency list is held in code rather than the database because it is
/// static reference data; adding one needs no migration.
class Currency extends Equatable {
  const Currency({required this.code, required this.symbol, required this.decimals});

  final String code;
  final String symbol;

  /// Minor-unit precision. Drives money rounding — VND has none.
  final int decimals;

  static const Currency vnd = Currency(code: 'VND', symbol: '₫', decimals: 0);

  static const List<Currency> all = [
    vnd,
    Currency(code: 'USD', symbol: r'$', decimals: 2),
    Currency(code: 'EUR', symbol: '€', decimals: 2),
    Currency(code: 'JPY', symbol: '¥', decimals: 0),
    Currency(code: 'KRW', symbol: '₩', decimals: 0),
    Currency(code: 'THB', symbol: '฿', decimals: 2),
    Currency(code: 'SGD', symbol: r'S$', decimals: 2),
    Currency(code: 'MYR', symbol: 'RM', decimals: 2),
    Currency(code: 'PHP', symbol: '₱', decimals: 2),
    Currency(code: 'IDR', symbol: 'Rp', decimals: 0),
    Currency(code: 'CNY', symbol: '¥', decimals: 2),
    Currency(code: 'AUD', symbol: r'A$', decimals: 2),
    Currency(code: 'GBP', symbol: '£', decimals: 2),
  ];

  static Currency byCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => vnd);

  @override
  List<Object?> get props => [code, symbol, decimals];
}
