import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

import 'package:mine_storage/domain/entities/fee.dart';
import 'package:mine_storage/domain/entities/sale_totals.dart';

/// §5.3, resolved in two passes so a percent discount can never depend on
/// itself and a percent fee is always charged on the discounted amount.
///
/// Pure by design: no clock, no repository, no Flutter — the same figures fall
/// out unchanged when this moves behind a server transaction.
abstract class SaleMoney {
  static Decimal roundMoney(Rational value, int decimals) =>
      value.toDecimal(scaleOnInfinitePrecision: decimals + 6).round(scale: decimals);

  static SaleTotals compute({
    required Decimal itemsSubtotal,
    required Decimal cogs,
    required List<Fee> fees,
    required int decimals,
  }) {
    Decimal amountOf(Fee fee, Decimal base) => switch (fee.kind) {
      FeeKind.fixed => roundMoney(fee.value.toRational(), decimals),
      FeeKind.percent => roundMoney(
        base.toRational() * fee.value.toRational() / Rational.fromInt(100),
        decimals,
      ),
    };

    final resolved = <String, ComputedFee>{};

    var discountTotal = Decimal.zero;
    for (final fee in fees.where((fee) => fee.direction.isDiscount)) {
      final amount = amountOf(fee, itemsSubtotal);
      discountTotal += amount;
      resolved[fee.id] = ComputedFee(
        fee: fee,
        amount: amount,
        base: fee.kind == FeeKind.percent ? itemsSubtotal : null,
      );
    }

    final percentBase = itemsSubtotal - discountTotal;
    var buyerChargeTotal = Decimal.zero;
    var passThroughTotal = Decimal.zero;
    var sellerCostTotal = Decimal.zero;
    for (final fee in fees.where((fee) => !fee.direction.isDiscount)) {
      final amount = amountOf(fee, percentBase);
      resolved[fee.id] = ComputedFee(
        fee: fee,
        amount: amount,
        base: fee.kind == FeeKind.percent ? percentBase : null,
      );
      if (fee.direction.raisesBuyerTotal) buyerChargeTotal += amount;
      if (fee.direction.isPassThrough) passThroughTotal += amount;
      if (fee.direction == FeeDirection.sellerCost) sellerCostTotal += amount;
    }

    final buyerTotal = itemsSubtotal + buyerChargeTotal - discountTotal;
    final netRevenue = buyerTotal - passThroughTotal - sellerCostTotal;
    final netProfit = netRevenue - cogs;

    return SaleTotals(
      itemsSubtotal: itemsSubtotal,
      cogs: cogs,
      discountTotal: discountTotal,
      buyerChargeTotal: buyerChargeTotal,
      passThroughTotal: passThroughTotal,
      sellerCostTotal: sellerCostTotal,
      buyerTotal: buyerTotal,
      netRevenue: netRevenue,
      netProfit: netProfit,
      netMargin: netRevenue == Decimal.zero
          ? Decimal.zero
          : (netProfit.toRational() / netRevenue.toRational())
                .toDecimal(scaleOnInfinitePrecision: 6),
      fees: [for (final fee in fees) resolved[fee.id]!],
    );
  }
}
