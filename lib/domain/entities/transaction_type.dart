/// What moved the stock, and why.
///
/// The type never decides the direction of a movement — the sign of
/// `quantityDelta` does. It decides which money columns carry meaning.
enum TransactionType { sale, receive, writeOff, adjust }

extension TransactionTypeX on TransactionType {
  String get wireValue => switch (this) {
    TransactionType.sale => 'sale',
    TransactionType.receive => 'receive',
    TransactionType.writeOff => 'write_off',
    TransactionType.adjust => 'adjust',
  };

  static TransactionType fromWire(String value) => switch (value) {
    'sale' => TransactionType.sale,
    'receive' => TransactionType.receive,
    'write_off' => TransactionType.writeOff,
    'adjust' => TransactionType.adjust,
    _ => throw ArgumentError.value(value, 'type', 'not a transaction type'),
  };

  /// The two that move money. The other two only move stock.
  bool get carriesMoney =>
      this == TransactionType.sale || this == TransactionType.receive;

  /// A receive pays a supplier, so it has revenue in no sense the shop can bank.
  bool get carriesProfit => this == TransactionType.sale;

  /// Which movements the user must give a reason for.
  bool get needsReason => this == TransactionType.writeOff;
}
