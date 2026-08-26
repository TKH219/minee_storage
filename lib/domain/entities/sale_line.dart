import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/sale_allocation.dart';

/// A paid line. Every figure is frozen at confirmation and never recomputed on
/// read — a price or cost corrected later must not rewrite history.
class SaleLine extends Equatable {
  const SaleLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitSellPrice,
    required this.allocations,
  });

  final String productId;
  final String productName;
  final Decimal quantity;
  final Decimal unitSellPrice;
  final List<SaleAllocation> allocations;

  Decimal get lineTotal => quantity * unitSellPrice;

  Decimal get lineCost =>
      allocations.fold(Decimal.zero, (sum, allocation) => sum + allocation.cost);

  @override
  List<Object?> get props => [
    productId,
    productName,
    quantity,
    unitSellPrice,
    allocations,
  ];
}
