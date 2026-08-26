import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/audit_times.dart';
import 'package:mine_storage/domain/entities/payment_method.dart';
import 'package:mine_storage/domain/entities/transaction_fee.dart';
import 'package:mine_storage/domain/entities/transaction_line.dart';
import 'package:mine_storage/domain/entities/transaction_money.dart';
import 'package:mine_storage/domain/entities/transaction_type.dart';
import 'package:mine_storage/domain/entities/write_off_reason.dart';

/// One movement of stock, with what it was worth and who it went to.
///
/// Fully editable and deletable: editing one *is* the return and deleting one
/// *is* the void, which is why there is no status here — [deletedTime] is the
/// only lifecycle state a transaction has.
class Transaction extends Equatable with AuditTimes {
  const Transaction({
    required this.id,
    required this.storeId,
    required this.type,
    required this.code,
    required this.occurredAt,
    required this.money,
    this.lines = const [],
    this.fees = const [],
    this.counterparty,
    this.counterpartyPhone,
    this.note,
    this.paymentMethod,
    this.reason,
    this.reasonNote,
    this.amendedAt,
    this.revision = 0,
    this.createdTime,
    this.updatedTime,
    this.deletedTime,
  });

  final String id;
  final String storeId;
  final TransactionType type;

  /// `S-202608-0041`. Sequential per store, per month, per type, and never
  /// reused — not even after a delete.
  final String code;

  /// User-editable, so yesterday's forgotten sale can be recorded today.
  /// Everything orders and groups by this, never by [createdTime].
  final DateTime occurredAt;

  final TransactionMoney money;
  final List<TransactionLine> lines;
  final List<TransactionFee> fees;
  final String? counterparty;
  final String? counterpartyPhone;
  final String? note;

  /// Present on a sale and a receive, absent on the other two.
  final PaymentMethod? paymentMethod;

  /// Required on a write-off, absent elsewhere.
  final WriteOffReason? reason;
  final String? reasonNote;

  final DateTime? amendedAt;
  final int revision;

  @override
  final DateTime? createdTime;
  @override
  final DateTime? updatedTime;
  @override
  final DateTime? deletedTime;

  bool get isAmended => amendedAt != null;

  /// How many distinct lots this movement touched.
  int get lotCount => lines.map((line) => line.batchId).toSet().length;

  /// True when any line's lot has been re-costed since the line froze its own.
  bool get anyCostHasMoved => lines.any((line) => line.costHasMoved);

  Decimal get totalQuantity =>
      lines.fold(Decimal.zero, (sum, line) => sum + line.displayQuantity);

  /// The signed movement across every line — the figure a ledger row shows.
  Decimal get netQuantityDelta =>
      lines.fold(Decimal.zero, (sum, line) => sum + line.quantityDelta);

  bool get isOutward => netQuantityDelta < Decimal.zero;

  @override
  List<Object?> get props => [
    id,
    storeId,
    type,
    code,
    occurredAt,
    money,
    lines,
    fees,
    counterparty,
    counterpartyPhone,
    note,
    paymentMethod,
    reason,
    reasonNote,
    amendedAt,
    revision,
    deletedTime,
  ];
}

/// One day of the ledger, with the subtotal the server computed over the
/// **whole** day. A page may carry only part of a busy day's rows, so summing
/// [transactions] here would print a different figure on page two.
class TransactionDay extends Equatable {
  const TransactionDay({
    required this.date,
    required this.subtotal,
    required this.transactionCount,
    this.transactions = const [],
  });

  final DateTime date;
  final Decimal subtotal;

  /// How many the whole day holds, which may exceed [transactions].
  final int transactionCount;

  final List<Transaction> transactions;

  bool get isPartial => transactions.length < transactionCount;

  @override
  List<Object?> get props => [date, subtotal, transactionCount, transactions];
}

/// One page of the ledger.
class TransactionPage extends Equatable {
  const TransactionPage({
    required this.days,
    required this.page,
    required this.limit,
    required this.total,
  });

  static const TransactionPage empty =
      TransactionPage(days: [], page: 1, limit: 20, total: 0);

  final List<TransactionDay> days;
  final int page;

  /// Counts transactions, not days.
  final int limit;
  final int total;

  bool get isEmpty => days.isEmpty;

  int get loadedCount =>
      days.fold(0, (sum, day) => sum + day.transactions.length);

  bool get hasMore => page * limit < total;

  @override
  List<Object?> get props => [days, page, limit, total];
}
