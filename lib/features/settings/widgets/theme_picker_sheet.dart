import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

import 'currency_picker_sheet.dart';
import 'settings_metrics.dart';

/// The theme row is drawn with a value and a chevron, exactly like Currency —
/// so it opens a picker rather than cycling on tap.
Future<ThemeMode?> showThemePicker(
  BuildContext context, {
  required ThemeMode selected,
}) {
  return showModalBottomSheet<ThemeMode>(
    context: context,
    backgroundColor: context.colors.neutral0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(CurrencyPickerMetrics.sheetRadius),
      ),
    ),
    builder: (_) => ThemePickerSheet(selected: selected),
  );
}

class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key, required this.selected});

  final ThemeMode selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: CurrencyPickerMetrics.sheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: CurrencyPickerMetrics.grabWidth,
                height: CurrencyPickerMetrics.grabHeight,
                margin: const EdgeInsets.only(
                  bottom: CurrencyPickerMetrics.grabBottomGap,
                ),
                decoration: BoxDecoration(
                  color: colors.neutral3,
                  borderRadius: BorderRadius.circular(
                    CurrencyPickerMetrics.grabHeight / 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: CurrencyPickerMetrics.blockGap),
            Padding(
              padding: CurrencyPickerMetrics.horizontalPadding,
              child: Text(
                LocaleKeys.settings_theme.tr(),
                style: context.textStyles.sansBodyBold.copyWith(
                  fontSize: CurrencyPickerMetrics.titleSize,
                ),
              ),
            ),
            const SizedBox(height: CurrencyPickerMetrics.blockGap),
            for (final mode in ThemeMode.values)
              _ThemeTile(mode: mode, selected: mode == selected),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.mode, required this.selected});

  final ThemeMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      key: Key('theme-tile-${mode.name}'),
      onTap: () => Navigator.of(context).pop(mode),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: SettingsMetrics.tileMinHeight,
        ),
        child: Padding(
          padding: SettingsMetrics.tilePadding,
          child: Row(
            children: [
              Container(
                key: Key('theme-radio-${mode.name}'),
                width: CurrencyPickerMetrics.radioSize,
                height: CurrencyPickerMetrics.radioSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.primary4 : colors.neutral4,
                    width: selected
                        ? CurrencyPickerMetrics.radioSelectedBorder
                        : CurrencyPickerMetrics.radioBorder,
                  ),
                ),
              ),
              const SizedBox(width: SettingsMetrics.tileGap),
              Expanded(
                child: Text(
                  mode.labelKey.tr(),
                  style: context.textStyles.sansBody.copyWith(
                    fontSize: SettingsMetrics.labelSize,
                  ),
                ),
              ),
              Icon(mode.icon, size: SettingsMetrics.iconSize, color: colors.neutral6),
            ],
          ),
        ),
      ),
    );
  }
}
