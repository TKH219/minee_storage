import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_option_sheet.dart';

String unitLabel(ProductUnit unit) => switch (unit) {
  ProductUnit.piece => LocaleKeys.products_unitPiece.tr(),
  ProductUnit.kg => LocaleKeys.products_unitKg.tr(),
  ProductUnit.g => LocaleKeys.products_unitG.tr(),
  ProductUnit.litre => LocaleKeys.products_unitLitre.tr(),
  ProductUnit.ml => LocaleKeys.products_unitMl.tr(),
  ProductUnit.box => LocaleKeys.products_unitBox.tr(),
  ProductUnit.pack => LocaleKeys.products_unitPack.tr(),
};

/// The design draws no unit control, so this borrows the field grammar it does
/// draw: the same label and 52-high input as every other row, made read-only and
/// opening the design system's option sheet.
class UnitPickerField extends StatelessWidget {
  const UnitPickerField({super.key, required this.value, required this.onChanged});

  final ProductUnit value;
  final ValueChanged<ProductUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.products_unit.tr(),
          style: context.textStyles.sansTableHeader.copyWith(
            color: colors.neutral7,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          key: const Key('product-unit-field'),
          readOnly: true,
          canRequestFocus: false,
          controller: TextEditingController(text: unitLabel(value)),
          onTap: () => _pick(context),
          decoration: InputDecoration(
            suffixIcon: Icon(Icons.expand_more_rounded, color: colors.neutral6),
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showAppOptionSheet<ProductUnit>(
      context: context,
      title: LocaleKeys.products_unitPickerTitle.tr(),
      options: [
        for (final unit in ProductUnit.values)
          AppOption(value: unit, label: unitLabel(unit)),
      ],
      selected: value,
    );
    if (picked != null) onChanged(picked);
  }
}
