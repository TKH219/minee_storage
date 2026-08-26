import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

/// How a money row reads. The design gives each one its own weight, rule and
/// ground, and S19 and S23 both draw from this same set.
enum MoneyRowStyle {
  /// A plain figure in the running list.
  plain,

  /// A figure that came off the total — rendered in the danger colour.
  negative,

  /// The headline the buyer actually hands over.
  total,

  /// Opens a new group with a hairline above it.
  subtotalRule,

  /// The profit line, on its own tinted ground.
  profit,
}

class MoneyRow {
  const MoneyRow({
    required this.label,
    required this.value,
    this.style = MoneyRowStyle.plain,
    this.note,
    this.key,
    this.onTap,
  });

  final String label;
  final String value;
  final MoneyRowStyle style;

  /// The small line under a label, e.g. "remitted, you keep none".
  final String? note;

  final Key? key;

  /// Set when the row leads somewhere — the basket's fees line opens the
  /// editor rather than being a dead figure.
  final VoidCallback? onTap;
}

/// Measured from the design's `.money` block.
abstract class MoneySummaryMetrics {
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(vertical: 7);
  static const double rowGap = 12;
  static const double keySize = 13.5;
  static const double valueSize = 14;
  static const double noteSize = 11;
  static const double noteHeight = 1.4;

  static const double totalKeySize = 15;
  static const double totalValueSize = 20;
  static const double totalRuleWidth = 1.5;
  static const double totalTopMargin = 6;
  static const double totalTopPadding = 12;

  static const double subtotalTopMargin = 4;
  static const double subtotalTopPadding = 11;

  static const double profitRadius = 10;
  static const EdgeInsets profitPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const double profitTopMargin = 10;
}

/// The money block shared by the basket and the review screen.
class MoneySummary extends StatelessWidget {
  const MoneySummary({super.key, required this.rows, this.profitIsPositive = true});

  final List<MoneyRow> rows;

  /// Drives the profit row's colour — §9 gives profit its sign's colour.
  final bool profitIsPositive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MoneySummaryMetrics.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final row in rows) _buildRow(context, row)],
      ),
    );
  }

  Widget _buildRow(BuildContext context, MoneyRow row) {
    final colors = context.colors;
    final texts = context.textStyles;

    final isTotal = row.style == MoneyRowStyle.total;
    final isProfit = row.style == MoneyRowStyle.profit;
    final profitInk = profitIsPositive ? colors.green5 : colors.red5;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                row.label,
                style: texts.sansBody.copyWith(
                  fontSize: isTotal
                      ? MoneySummaryMetrics.totalKeySize
                      : MoneySummaryMetrics.keySize,
                  fontWeight: isTotal || isProfit ? FontWeight.w600 : FontWeight.w400,
                  color: isProfit
                      ? profitInk
                      : (isTotal ? colors.neutral9 : colors.neutral7),
                ),
              ),
              if (row.note != null)
                Text(
                  row.note!,
                  style: texts.sansCaption.copyWith(
                    fontSize: MoneySummaryMetrics.noteSize,
                    height: MoneySummaryMetrics.noteHeight,
                    color: colors.neutral5,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: MoneySummaryMetrics.rowGap),
        Text(
          row.value,
          key: row.key,
          style: texts.monoBody.copyWith(
            fontSize: isTotal
                ? MoneySummaryMetrics.totalValueSize
                : MoneySummaryMetrics.valueSize,
            fontWeight: isTotal || isProfit ? FontWeight.w500 : FontWeight.w400,
            color: switch (row.style) {
              MoneyRowStyle.negative => colors.red5,
              MoneyRowStyle.profit => profitInk,
              MoneyRowStyle.total => colors.neutral9,
              _ => colors.neutral8,
            },
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    final wrapped = row.onTap == null
        ? content
        : InkWell(onTap: row.onTap, child: content);

    return switch (row.style) {
      MoneyRowStyle.profit => Container(
        margin: const EdgeInsets.only(top: MoneySummaryMetrics.profitTopMargin),
        padding: MoneySummaryMetrics.profitPadding,
        decoration: BoxDecoration(
          color: profitIsPositive ? colors.green0 : colors.red0,
          borderRadius: BorderRadius.circular(MoneySummaryMetrics.profitRadius),
        ),
        child: wrapped,
      ),
      MoneyRowStyle.total => Container(
        margin: const EdgeInsets.only(top: MoneySummaryMetrics.totalTopMargin),
        padding: const EdgeInsets.only(
          top: MoneySummaryMetrics.totalTopPadding,
          bottom: 7,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.neutral3,
              width: MoneySummaryMetrics.totalRuleWidth,
            ),
          ),
        ),
        child: wrapped,
      ),
      MoneyRowStyle.subtotalRule => Container(
        margin: const EdgeInsets.only(top: MoneySummaryMetrics.subtotalTopMargin),
        padding: const EdgeInsets.only(
          top: MoneySummaryMetrics.subtotalTopPadding,
          bottom: 7,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.neutral2)),
        ),
        child: wrapped,
      ),
      _ => Padding(padding: MoneySummaryMetrics.rowPadding, child: wrapped),
    };
  }
}
