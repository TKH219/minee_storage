import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/fee.dart';
import 'package:mine_storage/domain/entities/payment_method.dart';
import 'package:mine_storage/domain/entities/product_unit.dart';
import 'package:mine_storage/domain/entities/sale_allocation.dart';
import 'package:mine_storage/domain/entities/sale_totals.dart';
import 'package:mine_storage/domain/services/sale_money.dart';

class SaleDraftLine extends Equatable {
  const SaleDraftLine({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitSellPrice,
    required this.allocations,
  });

  final String productId;
  final String productName;
  final ProductUnit unit;
  final Decimal quantity;
  final Decimal unitSellPrice;
  final List<SaleAllocation> allocations;

  Decimal get lineTotal => quantity * unitSellPrice;

  Decimal get lineCost =>
      allocations.fold(Decimal.zero, (sum, allocation) => sum + allocation.cost);

  bool get isSplit => allocations.length > 1;

  SaleDraftLine copyWith({
    Decimal? quantity,
    Decimal? unitSellPrice,
    List<SaleAllocation>? allocations,
  }) {
    return SaleDraftLine(
      productId: productId,
      productName: productName,
      unit: unit,
      quantity: quantity ?? this.quantity,
      unitSellPrice: unitSellPrice ?? this.unitSellPrice,
      allocations: allocations ?? this.allocations,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    unit,
    quantity,
    unitSellPrice,
    allocations,
  ];
}

/// A sale before it is paid for. It holds no stock — §5.4.1 — so two devices
/// can build drafts over the same goods and only the confirm decides.
class SaleDraft extends Equatable {
  const SaleDraft({
    this.lines = const [],
    this.fees = const [],
    this.paymentMethod = PaymentMethod.cash,
    this.decimals = 2,
  });

  final List<SaleDraftLine> lines;
  final List<Fee> fees;
  final PaymentMethod paymentMethod;

  /// The store currency's minor-unit precision. VND has none.
  final int decimals;

  bool get isEmpty => lines.isEmpty;

  Decimal get itemsSubtotal =>
      lines.fold(Decimal.zero, (sum, line) => sum + line.lineTotal);

  Decimal get cogs => lines.fold(Decimal.zero, (sum, line) => sum + line.lineCost);

  int get lotCount => lines
      .expand((line) => line.allocations)
      .map((allocation) => allocation.batchId)
      .toSet()
      .length;

  SaleTotals get totals => SaleMoney.compute(
    itemsSubtotal: itemsSubtotal,
    cogs: cogs,
    fees: fees,
    decimals: decimals,
  );

  SaleDraft copyWith({
    List<SaleDraftLine>? lines,
    List<Fee>? fees,
    PaymentMethod? paymentMethod,
    int? decimals,
  }) {
    return SaleDraft(
      lines: lines ?? this.lines,
      fees: fees ?? this.fees,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      decimals: decimals ?? this.decimals,
    );
  }

  @override
  List<Object?> get props => [lines, fees, paymentMethod, decimals];
}
