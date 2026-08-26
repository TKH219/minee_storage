/// How the cash arrived. It affects no money math — it is what makes "how much
/// came through the bank this month" answerable.
///
/// [other] exists because a supplier can be paid in ways a shop counter never
/// sees. The payment picker deliberately offers only the four the design draws;
/// [other] arrives from the server, it is not chosen on S23.
enum PaymentMethod { cash, bankTransfer, card, eWallet, other }

extension PaymentMethodX on PaymentMethod {
  String get wireValue => switch (this) {
    PaymentMethod.cash => 'cash',
    PaymentMethod.bankTransfer => 'bank_transfer',
    PaymentMethod.card => 'card',
    PaymentMethod.eWallet => 'ewallet',
    PaymentMethod.other => 'other',
  };

  static PaymentMethod fromWire(String value) => switch (value) {
    'cash' => PaymentMethod.cash,
    'bank_transfer' => PaymentMethod.bankTransfer,
    'card' => PaymentMethod.card,
    'ewallet' => PaymentMethod.eWallet,
    'other' => PaymentMethod.other,
    _ => throw ArgumentError.value(value, 'paymentMethod', 'not a payment method'),
  };

  /// The four the design draws on S23.
  static const List<PaymentMethod> selectable = [
    PaymentMethod.cash,
    PaymentMethod.bankTransfer,
    PaymentMethod.card,
    PaymentMethod.eWallet,
  ];
}
