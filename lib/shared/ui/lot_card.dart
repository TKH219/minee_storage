import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/settings/states/settings_state.dart';

import 'quantity_format.dart';

class LotCard extends ConsumerWidget {
  const LotCard({
    super.key,
    required this.lot,
    this.isNextOut = false,
    this.today,
  });

  final ProductBatchEntity lot;
  final bool isNextOut;
  final DateTime? today;

  static final DateFormat _full = DateFormat('d MMM y');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.textStyles;
    final money = ref.watch(currencyFormatterProvider);

    return Container(
      key: const Key('lot-card-container'),
      decoration: BoxDecoration(
        color: isNextOut ? colors.tintPrimary : colors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNextOut ? colors.primary2 : colors.neutral3),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lot.expiryDate == null
                      ? LocaleKeys.stock_notTracked.tr()
                      : _full.format(lot.expiryDate!),
                  style: texts.sansBodyBold.copyWith(fontSize: 15),
                ),
              ),
              if (isNextOut)
                Text(
                  LocaleKeys.stock_nextOut.tr(),
                  style: texts.sansTableHeader.copyWith(
                    color: colors.inkPrimary,
                    letterSpacing: 0.6,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _field(context, LocaleKeys.stock_purchased.tr(), _full.format(lot.purchasedAt)),
          _field(context, LocaleKeys.stock_unitPrice.tr(), money.format(lot.unitPrice)),
          _field(context, LocaleKeys.stock_lotTotal.tr(), money.format(lot.totalCost)),
          _remaining(context),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textStyles.sansCaption.copyWith(color: context.colors.neutral6),
          ),
          Text(
            value,
            style: context.textStyles.monoBody.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _remaining(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          LocaleKeys.stock_remaining.tr(),
          style: context.textStyles.sansCaption.copyWith(color: context.colors.neutral6),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatQuantity(lot.remainingQuantity),
              style: context.textStyles.monoBody.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'of ${formatQuantity(lot.initialQuantity)}',
              style: context.textStyles.sansCaption.copyWith(color: context.colors.neutral6),
            ),
          ],
        ),
      ],
    );
  }
}
