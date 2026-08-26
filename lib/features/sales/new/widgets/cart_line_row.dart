import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import 'cart_metrics.dart';

/// One basket line. The "split across N lots" link is the only hint the lot
/// model is running underneath — and it leads back into the allocation that
/// produced it.
class CartLineRow extends StatelessWidget {
  const CartLineRow({
    super.key,
    required this.line,
    required this.money,
    required this.onEdit,
    required this.onRemove,
  });

  final SaleDraftLine line;
  final CurrencyFormatter money;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.textStyles;

    return InkWell(
      key: Key('cart-line-${line.productId}'),
      onTap: onEdit,
      onLongPress: onRemove,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.neutral2)),
        ),
        padding: CartMetrics.linePadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: CartMetrics.thumbSize,
              height: CartMetrics.thumbSize,
              decoration: BoxDecoration(
                color: colors.neutral2,
                borderRadius: BorderRadius.circular(CartMetrics.thumbRadius),
              ),
              child: Icon(Icons.inventory_2_outlined, color: colors.neutral5),
            ),
            const SizedBox(width: CartMetrics.lineGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          line.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: texts.sansBodyBold.copyWith(
                            fontSize: CartMetrics.nameSize,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        money.format(line.lineTotal),
                        key: Key('cart-amount-${line.productId}'),
                        style: texts.monoBody.copyWith(
                          fontSize: CartMetrics.amountSize,
                          fontWeight: FontWeight.w500,
                          color: colors.neutral9,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CartMetrics.lineInnerGap),
                  Text(
                    LocaleKeys.sales_lineMeta.tr(
                      namedArgs: {
                        'quantity': formatQuantity(line.quantity),
                        'price': money.format(line.unitSellPrice),
                      },
                    ),
                    style: texts.monoBody.copyWith(
                      fontSize: CartMetrics.metaSize,
                      color: colors.neutral6,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (line.isSplit) ...[
                    const SizedBox(height: CartMetrics.splitTopGap),
                    InkWell(
                      key: Key('cart-split-${line.productId}'),
                      onTap: onEdit,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.call_split_rounded,
                            size: CartMetrics.splitIconSize,
                            color: colors.inkPrimary,
                          ),
                          const SizedBox(width: CartMetrics.splitGap),
                          Text(
                            LocaleKeys.sales_splitAcross.tr(
                              namedArgs: {'count': '${line.allocations.length}'},
                            ),
                            style: texts.sansCaption.copyWith(
                              fontSize: CartMetrics.splitSize,
                              fontWeight: FontWeight.w600,
                              color: colors.inkPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
