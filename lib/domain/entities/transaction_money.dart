import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/fee.dart';
import 'package:mine_storage/domain/entities/transaction_type.dart';
import 'package:mine_storage/domain/services/sale_money.dart';

/// The eleven figures §5.3 defines, frozen at write and re-frozen at amend.
///
/// Never recomputed on read: a price corrected months later must not rewrite
/// what a past sale earned.
class TransactionMoney extends Equatable {
  const TransactionMoney({
    required this.itemsSubtotal,
    required this.discountTotal,
    required this.buyerChargeTotal,
    required this.sellerCostTotal,
    required this.passThroughTotal,
    required this.buyerTotal,
    required this.netRevenue,
    required this.cogs,
    required this.grossProfit,
    required this.netProfit,
    required this.netMargin,
    this.fees = const [],
  });

  static final TransactionMoney zero = TransactionMoney(
    itemsSubtotal: Decimal.zero,
    discountTotal: Decimal.zero,
    buyerChargeTotal: Decimal.zero,
    sellerCostTotal: Decimal.zero,
    passThroughTotal: Decimal.zero,
    buyerTotal: Decimal.zero,
    netRevenue: Decimal.zero,
    cogs: Decimal.zero,
    grossProfit: Decimal.zero,
    netProfit: Decimal.zero,
    netMargin: Decimal.zero,
  );

  final Decimal itemsSubtotal;
  final Decimal discountTotal;

  /// Everything the buyer is charged on top, pass-through included.
  final Decimal buyerChargeTotal;

  /// What the store pays out of its own side. The buyer never sees it.
  final Decimal sellerCostTotal;

  /// The part of [buyerChargeTotal] the store remits and keeps none of.
  final Decimal passThroughTotal;

  /// What the buyer hands over.
  final Decimal buyerTotal;

  /// What the store keeps once it has remitted and paid its own fees.
  final Decimal netRevenue;

  final Decimal cogs;

  /// The discounted goods total less what they cost, before any fee.
  final Decimal grossProfit;

  final Decimal netProfit;

  /// A ratio, not money. Unbounded below — a sale costing more than it earns
  /// has a margin under −100%.
  final Decimal netMargin;

  final List<ComputedFee> fees;

  /// The single line a basket shows in place of every fee.
  Decimal get feesAndDiscounts => buyerTotal - itemsSubtotal;

  Decimal get lessPassThroughAndCosts => passThroughTotal + sellerCostTotal;

  /// §5.3, then the type overrides. Delegates the two-pass arithmetic to
  /// [SaleMoney] so the sale flow and the ledger cannot drift apart.
  static TransactionMoney compute({
    required TransactionType type,
    required Decimal itemsSubtotal,
    required Decimal cogs,
    required List<Fee> fees,
    required int decimals,
  }) {
    final totals = SaleMoney.compute(
      itemsSubtotal: itemsSubtotal,
      cogs: cogs,
      fees: fees,
      decimals: decimals,
    );

    final grossProfit = totals.itemsSubtotal - totals.discountTotal - cogs;

    // A write-off or a stock count moves no money. cogs alone carries the value
    // of what left, which is the figure the waste report reads.
    if (!type.carriesMoney) {
      return TransactionMoney(
        itemsSubtotal: Decimal.zero,
        discountTotal: Decimal.zero,
        buyerChargeTotal: Decimal.zero,
        sellerCostTotal: Decimal.zero,
        passThroughTotal: Decimal.zero,
        buyerTotal: Decimal.zero,
        netRevenue: Decimal.zero,
        cogs: cogs,
        grossProfit: Decimal.zero,
        netProfit: Decimal.zero,
        netMargin: Decimal.zero,
        fees: totals.fees,
      );
    }

    // On a receive the shop is the buyer. It paid what it paid; it earned
    // nothing, so the four profit figures are meaningless and stay zero.
    if (!type.carriesProfit) {
      return TransactionMoney(
        itemsSubtotal: totals.itemsSubtotal,
        discountTotal: totals.discountTotal,
        buyerChargeTotal: totals.buyerChargeTotal,
        sellerCostTotal: totals.sellerCostTotal,
        passThroughTotal: totals.passThroughTotal,
        buyerTotal: totals.buyerTotal,
        netRevenue: Decimal.zero,
        cogs: Decimal.zero,
        grossProfit: Decimal.zero,
        netProfit: Decimal.zero,
        netMargin: Decimal.zero,
        fees: totals.fees,
      );
    }

    return TransactionMoney(
      itemsSubtotal: totals.itemsSubtotal,
      discountTotal: totals.discountTotal,
      buyerChargeTotal: totals.buyerChargeTotal,
      sellerCostTotal: totals.sellerCostTotal,
      passThroughTotal: totals.passThroughTotal,
      buyerTotal: totals.buyerTotal,
      netRevenue: totals.netRevenue,
      cogs: cogs,
      grossProfit: grossProfit,
      netProfit: totals.netProfit,
      netMargin: totals.netMargin,
      fees: totals.fees,
    );
  }

  @override
  List<Object?> get props => [
    itemsSubtotal,
    discountTotal,
    buyerChargeTotal,
    sellerCostTotal,
    passThroughTotal,
    buyerTotal,
    netRevenue,
    cogs,
    grossProfit,
    netProfit,
    netMargin,
    fees,
  ];
}
