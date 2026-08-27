import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/utils/store_currency_formatter.dart';

/// The money §5.3 froze onto a transaction, in the order the design reads it.
///
/// A receive stops at what was paid: it earned nothing, so the four profit
/// figures would be meaningless rather than merely zero.
class TransactionMoneyPanel extends StatelessWidget {
  const TransactionMoneyPanel({
    super.key,
    required this.transaction,
    required this.formatter,
  });

  final Transaction transaction;
  final StoreCurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final money = transaction.money;
    final rows = <Widget>[
      _MoneyRow(
        label: LocaleKeys.sales_itemsSubtotal.tr(),
        value: formatter.format(money.itemsSubtotal),
      ),
      for (final fee in transaction.fees) _feeRow(context, fee),
      _MoneyRow(
        label: transaction.type == TransactionType.receive
            ? LocaleKeys.sales_detailPaid.tr()
            : LocaleKeys.sales_detailBuyerPaid.tr(),
        value: formatter.format(money.buyerTotal),
        emphasise: true,
      ),
    ];

    if (transaction.type.carriesProfit) {
      rows.addAll([
        _MoneyRow(
          label: LocaleKeys.sales_lessPassThrough.tr(),
          value: '−${formatter.format(money.lessPassThroughAndCosts)}',
          tone: colors.neutral6,
        ),
        _MoneyRow(
          label: LocaleKeys.sales_netRevenue.tr(),
          note: LocaleKeys.sales_detailNetRevenueNote.tr(),
          value: formatter.format(money.netRevenue),
        ),
        _MoneyRow(
          label: LocaleKeys.sales_detailGrossProfit.tr(),
          note: LocaleKeys.sales_detailGrossProfitNote.tr(),
          value: formatter.format(money.grossProfit),
        ),
        _MoneyRow(
          label: LocaleKeys.sales_costOfGoods.tr(),
          value: '−${formatter.format(money.cogs)}',
          tone: colors.red5,
        ),
        _MoneyRow(
          key: const Key('detail-net-profit'),
          label: LocaleKeys.sales_netProfitMargin.tr(
            namedArgs: {
              'margin': formatter.formatMargin(money.netMargin).replaceAll('%', ''),
            },
          ),
          value: formatter.format(money.netProfit),
          emphasise: true,
          tone: colors.green5,
        ),
      ]);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.neutral0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.neutral2),
      ),
      child: Column(children: rows),
    );
  }

  Widget _feeRow(BuildContext context, TransactionFee fee) {
    final signed = fee.direction == FeeDirection.discount
        ? '−${formatter.format(fee.computedAmount)}'
        : '+${formatter.format(fee.computedAmount)}';
    return _MoneyRow(
      label: fee.name,
      note: switch (fee.direction) {
        FeeDirection.discount => LocaleKeys.sales_detailDiscountTag.tr(),
        FeeDirection.passThrough => LocaleKeys.sales_detailPassThrough.tr(),
        FeeDirection.buyerCharge => LocaleKeys.sales_detailBuyerCharge.tr(),
        FeeDirection.sellerCost => LocaleKeys.sales_detailYourCost.tr(),
      },
      value: signed,
      tone: fee.direction == FeeDirection.discount ? context.colors.red5 : null,
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.emphasise = false,
    this.tone,
  });

  final String label;
  final String? note;
  final String value;
  final bool emphasise;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: (emphasise ? styles.sansBodyBold : styles.sansBody).copyWith(
                    color: colors.neutral9,
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: styles.sansCaption.copyWith(color: colors.neutral6),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: (emphasise ? styles.sansBodyBold : styles.monoBody).copyWith(
              color: tone ?? colors.neutral9,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
