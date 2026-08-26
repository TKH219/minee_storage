import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/fee.dart';
import 'package:mine_storage/domain/entities/payment_method.dart';
import 'package:mine_storage/domain/entities/transaction_money.dart';
import 'package:mine_storage/domain/entities/transaction_type.dart';
import 'package:mine_storage/domain/entities/write_off_reason.dart';

/// The lot a receive line opens. Absent on every other type, which draw on
/// lots that already exist.
class TransactionBatchDraft extends Equatable {
  const TransactionBatchDraft({
    this.batchCode,
    this.expiryDate,
    this.supplier,
    this.storageLocation,
    this.note,
  });

  final String? batchCode;
  final DateTime? expiryDate;
  final String? supplier;
  final String? storageLocation;
  final String? note;

  @override
  List<Object?> get props => [batchCode, expiryDate, supplier, storageLocation, note];
}

/// One line of a transaction before the server resolves it.
///
/// [quantity] is always positive; the server applies the sign from the type.
/// On a stock count it is the **counted** quantity, and the delta is the
/// difference from what the lot holds.
class TransactionLineDraft extends Equatable {
  const TransactionLineDraft({
    required this.productId,
    required this.quantity,
    this.batchId,
    this.unitPrice,
    this.batch,
  });

  final String productId;

  /// Null lets FEFO resolve the split on a sale or a write-off, and creates a
  /// lot on a receive. **Required on a stock count** — a count is per lot.
  final String? batchId;

  final Decimal quantity;
  final Decimal? unitPrice;
  final TransactionBatchDraft? batch;

  @override
  List<Object?> get props => [productId, batchId, quantity, unitPrice, batch];
}

/// A transaction before it is written. It holds no stock: two devices can build
/// drafts over the same goods and only the write decides.
class TransactionDraft extends Equatable {
  const TransactionDraft({
    required this.storeId,
    required this.type,
    required this.lines,
    this.occurredAt,
    this.fees = const [],
    this.counterparty,
    this.counterpartyPhone,
    this.note,
    this.paymentMethod,
    this.reason,
    this.reasonNote,
  });

  final String storeId;
  final TransactionType type;
  final List<TransactionLineDraft> lines;
  final DateTime? occurredAt;
  final List<Fee> fees;
  final String? counterparty;
  final String? counterpartyPhone;
  final String? note;
  final PaymentMethod? paymentMethod;
  final WriteOffReason? reason;
  final String? reasonNote;

  bool get isEmpty => lines.isEmpty;

  TransactionDraft copyWith({
    List<TransactionLineDraft>? lines,
    DateTime? occurredAt,
    List<Fee>? fees,
    String? counterparty,
    String? counterpartyPhone,
    String? note,
    PaymentMethod? paymentMethod,
    WriteOffReason? reason,
    String? reasonNote,
  }) {
    return TransactionDraft(
      storeId: storeId,
      type: type,
      lines: lines ?? this.lines,
      occurredAt: occurredAt ?? this.occurredAt,
      fees: fees ?? this.fees,
      counterparty: counterparty ?? this.counterparty,
      counterpartyPhone: counterpartyPhone ?? this.counterpartyPhone,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reason: reason ?? this.reason,
      reasonNote: reasonNote ?? this.reasonNote,
    );
  }

  @override
  List<Object?> get props => [
    storeId,
    type,
    lines,
    occurredAt,
    fees,
    counterparty,
    counterpartyPhone,
    note,
    paymentMethod,
    reason,
    reasonNote,
  ];
}

/// What a preview resolved, without writing anything.
class TransactionPreview extends Equatable {
  const TransactionPreview({
    required this.storeId,
    required this.type,
    required this.currencyMinorUnits,
    required this.money,
    this.lines = const [],
  });

  final String storeId;
  final TransactionType type;
  final int currencyMinorUnits;
  final TransactionMoney money;
  final List<ResolvedLine> lines;

  /// The lots this would draw on, in the order it would draw on them.
  List<String> get batchIds =>
      lines.map((line) => line.batchId).whereType<String>().toList();

  @override
  List<Object?> get props => [storeId, type, currencyMinorUnits, money, lines];
}

/// One line as the server resolved it, before anything was written.
class ResolvedLine extends Equatable {
  const ResolvedLine({
    required this.productId,
    required this.productName,
    required this.quantityDelta,
    required this.unitPrice,
    required this.unitCostSnapshot,
    required this.lineGross,
    required this.lineCost,
    this.batchId,
    this.batchCode,
    this.sortOrder = 0,
  });

  final String productId;
  final String? batchId;
  final String? batchCode;
  final String productName;
  final Decimal quantityDelta;
  final Decimal unitPrice;
  final Decimal unitCostSnapshot;
  final Decimal lineGross;
  final Decimal lineCost;
  final int sortOrder;

  Decimal get displayQuantity => quantityDelta.abs();

  @override
  List<Object?> get props => [
    productId,
    batchId,
    batchCode,
    productName,
    quantityDelta,
    unitPrice,
    unitCostSnapshot,
    lineGross,
    lineCost,
    sortOrder,
  ];
}
