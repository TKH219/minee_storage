import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

import 'settings_metrics.dart';

/// Measured from the design's currency picker (`#settings`, node `3321:15894`).
abstract class CurrencyPickerMetrics {
  static const double sheetRadius = 20;
  static const EdgeInsets sheetPadding = EdgeInsets.only(top: 10, bottom: 24);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const double blockGap = 16;

  static const double grabWidth = 36;
  static const double grabHeight = 4;
  static const double grabBottomGap = 2;
  static const double titleSize = 18;

  static const double radioSize = 20;
  static const double radioBorder = 2;
  static const double radioSelectedBorder = 6;

  static const EdgeInsets noticePadding = EdgeInsets.symmetric(horizontal: 13, vertical: 12);
  static const double noticeRadius = 10;
  static const double noticeGap = 10;
  static const double noticeTextSize = 13;
  static const double noticeTextHeight = 1.45;
  static const double noticeIconSize = 20;
}

Future<Currency?> showCurrencyPicker(
  BuildContext context, {
  required List<Currency> currencies,
  required Currency selected,
}) {
  return showModalBottomSheet<Currency>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.neutral0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(CurrencyPickerMetrics.sheetRadius),
      ),
    ),
    builder: (_) => CurrencyPickerSheet(
      currencies: currencies,
      selected: selected,
    ),
  );
}

/// The notice above the list is doing real work: without it a shopkeeper will
/// assume switching currency converts their recorded figures. It does not.
class CurrencyPickerSheet extends StatelessWidget {
  const CurrencyPickerSheet({
    super.key,
    required this.currencies,
    required this.selected,
  });

  final List<Currency> currencies;
  final Currency selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ordered = [...currencies]..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.code.compareTo(b.code);
    });

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
                LocaleKeys.settings_currency.tr(),
                style: context.textStyles.sansBodyBold.copyWith(
                  fontSize: CurrencyPickerMetrics.titleSize,
                ),
              ),
            ),
            const SizedBox(height: CurrencyPickerMetrics.blockGap),
            Padding(
              padding: CurrencyPickerMetrics.horizontalPadding,
              child: const _RelabelNotice(),
            ),
            const SizedBox(height: CurrencyPickerMetrics.blockGap),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final currency in ordered)
                    _CurrencyTile(
                      currency: currency,
                      selected: currency.code == selected.code,
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

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({required this.currency, required this.selected});

  final Currency currency;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      key: Key('currency-tile-${currency.code}'),
      onTap: () => Navigator.of(context).pop(currency),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: SettingsMetrics.tileMinHeight,
        ),
        child: Padding(
          padding: SettingsMetrics.tilePadding,
          child: Row(
            children: [
              Container(
                key: Key('currency-radio-${currency.code}'),
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
                  _nameFor(currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.sansBody.copyWith(
                    fontSize: SettingsMetrics.labelSize,
                  ),
                ),
              ),
              Text(
                '${currency.code} · ${currency.symbol}',
                style: context.textStyles.monoBody.copyWith(
                  fontSize: SettingsMetrics.valueSize,
                  color: colors.neutral6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The code stands in for a currency this app has no name for, rather than
  /// leaving the row blank.
  static String _nameFor(Currency currency) => switch (currency.code) {
    'USD' => LocaleKeys.settings_currencyUSD.tr(),
    'EUR' => LocaleKeys.settings_currencyEUR.tr(),
    'GBP' => LocaleKeys.settings_currencyGBP.tr(),
    'SGD' => LocaleKeys.settings_currencySGD.tr(),
    'VND' => LocaleKeys.settings_currencyVND.tr(),
    _ => currency.code,
  };
}

class _RelabelNotice extends StatelessWidget {
  const _RelabelNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: CurrencyPickerMetrics.noticePadding,
      decoration: BoxDecoration(
        color: colors.primary0,
        borderRadius: BorderRadius.circular(CurrencyPickerMetrics.noticeRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: CurrencyPickerMetrics.noticeIconSize,
            color: colors.primary5,
          ),
          const SizedBox(width: CurrencyPickerMetrics.noticeGap),
          Expanded(
            child: Text(
              LocaleKeys.settings_currencyNotice.tr(),
              style: context.textStyles.sansBody.copyWith(
                fontSize: CurrencyPickerMetrics.noticeTextSize,
                height: CurrencyPickerMetrics.noticeTextHeight,
                color: colors.primary5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
