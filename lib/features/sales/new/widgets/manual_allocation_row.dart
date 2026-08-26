import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/sales/new/states/allocation_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import 'allocation_metrics.dart';

/// One lot the seller can type a quantity against, with what it costs and what
/// it holds on the line beneath its name.
class ManualAllocationRow extends StatefulWidget {
  const ManualAllocationRow({
    super.key,
    required this.lot,
    required this.money,
    required this.onChanged,
  });

  final ManualLot lot;
  final CurrencyFormatter money;
  final ValueChanged<String> onChanged;

  static final DateFormat _date = DateFormat('d MMM');

  @override
  State<ManualAllocationRow> createState() => _ManualAllocationRowState();
}

class _ManualAllocationRowState extends State<ManualAllocationRow> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.lot.input);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inError = widget.lot.exceedsLot;

    return Container(
      padding: AllocationMetrics.editRowPadding,
      decoration: BoxDecoration(
        color: colors.neutral0,
        border: Border.all(color: colors.neutral2),
        borderRadius: BorderRadius.circular(AllocationMetrics.editRowRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _lotLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.sansBodyBold.copyWith(
                    fontSize: AllocationMetrics.editLotTitleSize,
                  ),
                ),
                Text(
                  LocaleKeys.sales_manualAvailable.tr(
                    namedArgs: {
                      'cost': widget.money.format(widget.lot.unitCost),
                      'available': formatQuantity(widget.lot.available),
                    },
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.monoBody.copyWith(
                    fontSize: AllocationMetrics.editLotSubSize,
                    color: colors.neutral6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AllocationMetrics.editRowGap),
          SizedBox(
            width: AllocationMetrics.qtyBoxWidth,
            height: AllocationMetrics.qtyBoxHeight,
            child: TextField(
              key: Key('manual-qty-${widget.lot.batchId}'),
              controller: _controller,
              onChanged: widget.onChanged,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: context.textStyles.monoBody.copyWith(
                fontSize: AllocationMetrics.qtyBoxTextSize,
                color: inError ? colors.red5 : colors.neutral9,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: _border(inError ? colors.red5 : colors.neutral3),
                enabledBorder: _border(inError ? colors.red5 : colors.neutral3),
                focusedBorder: _border(inError ? colors.red5 : colors.primary4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lotLabel() {
    final expiry = widget.lot.expiryDate;
    return expiry == null
        ? LocaleKeys.sales_allocLotNoExpiry.tr(
            namedArgs: {'date': widget.lot.batchCode},
          )
        : LocaleKeys.sales_allocLotExpiring.tr(
            namedArgs: {'date': ManualAllocationRow._date.format(expiry)},
          );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AllocationMetrics.qtyBoxRadius),
    borderSide: BorderSide(
      color: color,
      width: AllocationMetrics.qtyBoxBorderWidth,
    ),
  );
}
