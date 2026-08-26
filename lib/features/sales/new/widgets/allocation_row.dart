import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import 'allocation_metrics.dart';

/// One lot's share of a line, with its own cost on the same line as its
/// quantity — the whole point of showing the split at all.
class AllocationRow extends StatelessWidget {
  const AllocationRow({
    super.key,
    required this.allocation,
    required this.money,
    required this.today,
  });

  final SaleAllocation allocation;
  final CurrencyFormatter money;
  final DateTime today;

  static final DateFormat _date = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final expired =
        allocation.expiryDate != null && !allocation.expiryDate!.isAfter(today);

    return Container(
      padding: AllocationMetrics.allocPadding,
      decoration: BoxDecoration(
        color: expired ? colors.red0 : colors.neutral1,
        border: Border.all(color: expired ? Colors.transparent : colors.neutral2),
        borderRadius: BorderRadius.circular(AllocationMetrics.allocRadius),
      ),
      child: Row(
        children: [
          Container(
            width: AllocationMetrics.pillSize,
            height: AllocationMetrics.pillSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: expired ? colors.red5 : colors.primary1,
              shape: BoxShape.circle,
            ),
            child: Text(
              formatQuantity(allocation.quantity),
              style: context.textStyles.monoBody.copyWith(
                fontSize: AllocationMetrics.pillTextSize,
                fontWeight: FontWeight.w500,
                color: expired
                    ? (colors.isDark ? colors.neutral0 : colors.white)
                    : colors.primary5,
              ),
            ),
          ),
          const SizedBox(width: AllocationMetrics.allocGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _lotLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.sansBodyBold.copyWith(
                    fontSize: AllocationMetrics.allocTitleSize,
                  ),
                ),
                Text(
                  _costLabel(),
                  maxLines: 2,
                  style: context.textStyles.sansCaption.copyWith(
                    fontSize: AllocationMetrics.allocSubSize,
                    color: colors.neutral6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _lotLabel() {
    final expiry = allocation.expiryDate;
    return expiry == null
        ? LocaleKeys.sales_allocLotNoExpiry.tr(
            namedArgs: {'date': allocation.batchCode},
          )
        : LocaleKeys.sales_allocLotExpiring.tr(
            namedArgs: {'date': _date.format(expiry)},
          );
  }

  String _costLabel() {
    final cost = money.format(allocation.unitCost);
    if (allocation.emptiesLot) {
      return LocaleKeys.sales_allocCostEmpties.tr(namedArgs: {'cost': cost});
    }
    return LocaleKeys.sales_allocCostRemains.tr(
      namedArgs: {
        'cost': cost,
        'remaining': formatQuantity(allocation.remainingAfter ?? Decimal.zero),
      },
    );
  }
}
