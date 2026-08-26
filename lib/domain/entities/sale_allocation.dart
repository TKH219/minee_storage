import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// One lot's share of one sale line, with the cost frozen at the moment the
/// split was resolved. The same goods bought twice at different prices stay two
/// lots rather than an average, so the seller can see both costs at once.
class SaleAllocation extends Equatable {
  const SaleAllocation({
    required this.batchId,
    required this.batchCode,
    required this.quantity,
    required this.unitCost,
    this.expiryDate,
    this.remainingAfter,
  });

  final String batchId;
  final String batchCode;
  final Decimal quantity;
  final Decimal unitCost;
  final DateTime? expiryDate;

  /// What the lot still holds once this quantity leaves it. Null when the
  /// remainder was never resolved.
  final Decimal? remainingAfter;

  Decimal get cost => unitCost * quantity;

  bool get emptiesLot => remainingAfter == Decimal.zero;

  SaleAllocation copyWith({Decimal? quantity, Decimal? remainingAfter}) {
    return SaleAllocation(
      batchId: batchId,
      batchCode: batchCode,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost,
      expiryDate: expiryDate,
      remainingAfter: remainingAfter ?? this.remainingAfter,
    );
  }

  @override
  List<Object?> get props => [
    batchId,
    batchCode,
    quantity,
    unitCost,
    expiryDate,
    remainingAfter,
  ];
}
