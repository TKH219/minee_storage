import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/fee.dart';

/// Every money column §5.3 defines, computed once and then frozen.
class SaleTotals extends Equatable {
  const SaleTotals({
    required this.itemsSubtotal,
    required this.cogs,
    required this.discountTotal,
    required this.buyerChargeTotal,
    required this.passThroughTotal,
    required this.sellerCostTotal,
    required this.buyerTotal,
    required this.netRevenue,
    required this.netProfit,
    required this.netMargin,
    required this.fees,
  });

  static final SaleTotals zero = SaleTotals(
    itemsSubtotal: Decimal.zero,
    cogs: Decimal.zero,
    discountTotal: Decimal.zero,
    buyerChargeTotal: Decimal.zero,
    passThroughTotal: Decimal.zero,
    sellerCostTotal: Decimal.zero,
    buyerTotal: Decimal.zero,
    netRevenue: Decimal.zero,
    netProfit: Decimal.zero,
    netMargin: Decimal.zero,
    fees: const [],
  );

  final Decimal itemsSubtotal;
  final Decimal cogs;
  final Decimal discountTotal;
  final Decimal buyerChargeTotal;
  final Decimal passThroughTotal;
  final Decimal sellerCostTotal;

  /// What the buyer hands over.
  final Decimal buyerTotal;

  /// What the store keeps once it has remitted and paid its own fees.
  final Decimal netRevenue;

  final Decimal netProfit;

  /// A ratio, not money — kept at full precision and rounded only for display.
  final Decimal netMargin;

  final List<ComputedFee> fees;

  /// The single line the basket shows instead of every fee.
  Decimal get feesAndDiscounts => buyerTotal - itemsSubtotal;

  Decimal get lessPassThroughAndCosts => passThroughTotal + sellerCostTotal;

  @override
  List<Object?> get props => [
    itemsSubtotal,
    cogs,
    discountTotal,
    buyerChargeTotal,
    passThroughTotal,
    sellerCostTotal,
    buyerTotal,
    netRevenue,
    netProfit,
    netMargin,
    fees,
  ];
}
