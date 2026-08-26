import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/audit_times.dart';
import 'package:mine_storage/domain/entities/product_unit.dart';

/// A signed delta against one lot.
///
/// [quantityDelta] is the only truth about stock: applying a transaction adds
/// it to the lot, reversing subtracts it. Nothing about a line needs to know
/// which of the four types it belongs to.
class TransactionLine extends Equatable with AuditTimes {
  const TransactionLine({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.batchId,
    required this.batchCode,
    required this.productName,
    required this.unit,
    required this.quantityDelta,
    required this.unitPrice,
    required this.unitCostSnapshot,
    required this.lineGross,
    required this.lineCost,
    this.batchUnitCost,
    this.expiryDate,
    this.sortOrder = 0,
    this.createdTime,
    this.updatedTime,
    this.deletedTime,
  });

  final String id;
  final String transactionId;
  final String productId;
  final String batchId;
  final String batchCode;
  final String productName;
  final ProductUnit unit;

  /// Negative on a sale and a write-off, positive on a receive, either sign on
  /// a stock count.
  final Decimal quantityDelta;

  final Decimal unitPrice;

  /// Frozen from the lot when the line was written, and never rewritten. A lot
  /// whose cost is corrected later will disagree with this, and that is right —
  /// a past sale's recorded profit must not silently change.
  final Decimal unitCostSnapshot;

  /// What the lot costs *now*. Null when the lot was not resolved with the line.
  final Decimal? batchUnitCost;

  final Decimal lineGross;
  final Decimal lineCost;
  final DateTime? expiryDate;
  final int sortOrder;

  @override
  final DateTime? createdTime;
  @override
  final DateTime? updatedTime;
  @override
  final DateTime? deletedTime;

  /// What the row shows. The arrow beside it comes from [isOutward].
  Decimal get displayQuantity => quantityDelta.abs();

  bool get isOutward => quantityDelta < Decimal.zero;

  /// The lot's cost has moved since this line froze its own. The detail screen
  /// says so where the two figures sit side by side.
  bool get costHasMoved =>
      batchUnitCost != null && batchUnitCost != unitCostSnapshot;

  @override
  List<Object?> get props => [
    id,
    transactionId,
    productId,
    batchId,
    batchCode,
    productName,
    unit,
    quantityDelta,
    unitPrice,
    unitCostSnapshot,
    batchUnitCost,
    lineGross,
    lineCost,
    expiryDate,
    sortOrder,
  ];
}
