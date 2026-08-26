import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/payment_method.dart';
import 'package:mine_storage/domain/entities/transaction_type.dart';

/// What the ledger is narrowed to. Every field is a query parameter — the
/// server does the filtering, so a page and its day subtotals always agree.
class LedgerFilter extends Equatable {
  const LedgerFilter({
    this.type,
    this.from,
    this.to,
    this.productId,
    this.paymentMethod,
    this.query = '',
  });

  final TransactionType? type;
  final DateTime? from;
  final DateTime? to;
  final String? productId;
  final PaymentMethod? paymentMethod;
  final String query;

  bool get isEmpty =>
      type == null &&
      from == null &&
      to == null &&
      productId == null &&
      paymentMethod == null &&
      query.isEmpty;

  bool get isActive => !isEmpty;

  int get activeCount => [
    type != null,
    from != null || to != null,
    productId != null,
    paymentMethod != null,
    query.isNotEmpty,
  ].where((on) => on).length;

  /// Passing null clears a field, which a `??` copyWith cannot express.
  LedgerFilter copyWith({
    TransactionType? type,
    bool clearType = false,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
    String? productId,
    bool clearProduct = false,
    PaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
    String? query,
  }) {
    return LedgerFilter(
      type: clearType ? null : (type ?? this.type),
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      productId: clearProduct ? null : (productId ?? this.productId),
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [type, from, to, productId, paymentMethod, query];
}
