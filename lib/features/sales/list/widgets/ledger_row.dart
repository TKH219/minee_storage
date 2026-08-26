import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/list/widgets/ledger_labels.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';
import 'package:mine_storage/shared/utils/store_currency_formatter.dart';

/// One movement. The arrow follows the **sign of the delta**, never the type —
/// a stock count that finds more points the same way a delivery does.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.transaction,
    required this.formatter,
    this.onTap,
  });

  final Transaction transaction;
  final StoreCurrencyFormatter formatter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final outward = transaction.isOutward;
    final movementColor = outward ? colors.red5 : colors.green5;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.neutral2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                transactionTypeIcon(transaction.type),
                size: 20,
                color: colors.neutral7,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.code,
                          style: styles.monoBody.copyWith(color: colors.neutral9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // A stock count moves no money, so it shows a dash rather
                      // than a zero that would read as a free sale.
                      Text(
                        transaction.type.carriesMoney
                            ? formatter.format(transaction.money.buyerTotal)
                            : '—',
                        style: styles.sansBody.copyWith(
                          color: transaction.type.carriesMoney
                              ? colors.neutral9
                              : colors.neutral6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transactionSubtitle(transaction)} · '
                    '${DateFormat.Hm().format(transaction.occurredAt.toLocal())}',
                    style: styles.sansCaption.copyWith(color: colors.neutral6),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        outward ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        size: 14,
                        color: movementColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatQuantity(transaction.netQuantityDelta),
                        style: styles.sansCaption.copyWith(color: movementColor),
                      ),
                      if (transaction.isAmended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.neutral2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            LocaleKeys.sales_ledgerEdited.tr(),
                            style: styles.sansCaption.copyWith(color: colors.neutral7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A day header, carrying the subtotal the **server** computed over the whole
/// day. A busy day spans pages, so summing the visible rows would print a
/// different figure on page two than on page one.
class LedgerDayHeader extends StatelessWidget {
  const LedgerDayHeader({
    super.key,
    required this.day,
    required this.formatter,
    required this.today,
  });

  final TransactionDay day;
  final StoreCurrencyFormatter formatter;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dayHeaderLabel(day.date, today),
              style: styles.sansBodyBold.copyWith(color: colors.neutral7),
            ),
          ),
          Text(
            formatter.formatSigned(day.subtotal),
            style: styles.monoBody.copyWith(color: colors.neutral7),
          ),
        ],
      ),
    );
  }
}
