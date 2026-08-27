import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/extensions/date_time_extensions.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';

/// Which lot a movement lands on. A write-off and a count are both facts about
/// one delivery, not about the product, so the choice comes before the figures.
class LotPickerTiles extends StatelessWidget {
  const LotPickerTiles({
    super.key,
    required this.lots,
    required this.selected,
    required this.onSelect,
  });

  final List<ProductBatchEntity> lots;
  final ProductBatchEntity? selected;
  final ValueChanged<ProductBatchEntity> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    return Column(
      children: [
        for (final lot in lots)
          InkWell(
            key: Key('lot-tile-${lot.id}'),
            onTap: () => onSelect(lot),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    lot.id == selected?.id
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: lot.id == selected?.id ? colors.primary4 : colors.neutral4,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      LocaleKeys.products_lotPickerLot.tr(
                        namedArgs: {'lot': lot.expiryDate.formatOr(lot.batchCode)},
                      ),
                      style: styles.sansBody.copyWith(color: colors.neutral9),
                    ),
                  ),
                  Text(
                    LocaleKeys.products_lotPickerHolds.tr(
                      namedArgs: {
                        'code': lot.batchCode,
                        'remaining': formatQuantity(lot.remainingQuantity),
                      },
                    ),
                    style: styles.sansCaption.copyWith(color: colors.neutral6),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
