import 'package:decimal/decimal.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import 'fee_metrics.dart';

/// One fee, with the tag that says who ends up with the money and the line
/// that names what the amount was charged on.
class FeeRow extends StatelessWidget {
  const FeeRow({
    super.key,
    required this.computed,
    required this.signedAmount,
    required this.money,
    required this.hasDiscount,
    required this.onRemove,
  });

  final ComputedFee computed;
  final Decimal signedAmount;
  final CurrencyFormatter money;

  /// Changes the wording of a post-discount base — "on $34.01 after discount"
  /// only makes sense when a discount is actually in play.
  final bool hasDiscount;

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.textStyles;
    final negative = signedAmount < Decimal.zero;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.neutral2)),
      ),
      padding: FeeMetrics.rowPadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  computed.fee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: texts.sansBodyBold.copyWith(
                    fontSize: FeeMetrics.nameSize,
                  ),
                ),
                Text(
                  _baseLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: texts.sansCaption.copyWith(
                    fontSize: FeeMetrics.baseSize,
                    color: colors.neutral6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FeeMetrics.rowGap),
          _DirectionTag(direction: computed.fee.direction),
          const SizedBox(width: FeeMetrics.rowGap),
          Text(
            '${negative ? '−' : '+'}${money.format(signedAmount.abs())}',
            key: Key('fee-amount-${computed.fee.id}'),
            style: texts.monoBody.copyWith(
              fontSize: FeeMetrics.amountSize,
              color: negative ? colors.red5 : colors.neutral8,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          IconButton(
            key: Key('fee-remove-${computed.fee.id}'),
            onPressed: onRemove,
            tooltip: LocaleKeys.sales_feeRemove.tr(),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 18, color: colors.neutral5),
          ),
        ],
      ),
    );
  }

  /// The whole point of the row: say what this amount was taken from.
  String _baseLabel() {
    final base = computed.base;
    if (base == null) {
      return switch (computed.fee.direction) {
        FeeDirection.buyerCharge => LocaleKeys.sales_feeFixedYouKeep.tr(),
        FeeDirection.passThrough => LocaleKeys.sales_feeFixedRemitted.tr(),
        _ => LocaleKeys.sales_feeFixed.tr(),
      };
    }
    if (computed.fee.direction == FeeDirection.discount) {
      return LocaleKeys.sales_feeOnSubtotal.tr();
    }
    return hasDiscount
        ? LocaleKeys.sales_feeOnAfterDiscount.tr(
            namedArgs: {'base': money.format(base)},
          )
        : LocaleKeys.sales_feeOnBase.tr(namedArgs: {'base': money.format(base)});
  }
}

class _DirectionTag extends StatelessWidget {
  const _DirectionTag({required this.direction});

  final FeeDirection direction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (background, ink, label) = switch (direction) {
      FeeDirection.discount => (
        colors.green0,
        colors.green5,
        LocaleKeys.sales_feeDirDiscount.tr(),
      ),
      FeeDirection.passThrough => (
        colors.orange0,
        colors.orange6,
        LocaleKeys.sales_feeDirPassThrough.tr(),
      ),
      FeeDirection.sellerCost => (
        colors.red0,
        colors.red5,
        LocaleKeys.sales_feeDirSellerCost.tr(),
      ),
      FeeDirection.buyerCharge => (
        colors.neutral2,
        colors.neutral6,
        LocaleKeys.sales_feeDirBuyer.tr(),
      ),
    };

    return Container(
      padding: FeeMetrics.tagPadding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(FeeMetrics.tagRadius),
      ),
      child: Text(
        label.toUpperCase(),
        style: context.textStyles.sansCaption.copyWith(
          fontSize: FeeMetrics.tagTextSize,
          fontWeight: FontWeight.w600,
          letterSpacing: FeeMetrics.tagSpacing,
          color: ink,
        ),
      ),
    );
  }
}
