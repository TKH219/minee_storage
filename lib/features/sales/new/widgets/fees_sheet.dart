import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/new/states/fees_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import 'fee_metrics.dart';
import 'fee_row.dart';
import 'sale_buttons.dart';

/// S22. Four directions, and each row says who ends up with the money.
Future<List<Fee>?> showFeesSheet(
  BuildContext context, {
  required Decimal itemsSubtotal,
  required List<Fee> fees,
  required Currency currency,
}) {
  return showModalBottomSheet<List<Fee>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.neutral0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(FeeMetrics.sheetRadius),
      ),
    ),
    builder: (_) => FeesSheet(
      itemsSubtotal: itemsSubtotal,
      fees: fees,
      currency: currency,
    ),
  );
}

class FeesSheet extends ConsumerStatefulWidget {
  const FeesSheet({
    super.key,
    required this.itemsSubtotal,
    required this.fees,
    required this.currency,
  });

  final Decimal itemsSubtotal;
  final List<Fee> fees;
  final Currency currency;

  @override
  ConsumerState<FeesSheet> createState() => _FeesSheetState();
}

class _FeesSheetState extends ConsumerState<FeesSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(feesStateProvider.notifier)
          .open(
            itemsSubtotal: widget.itemsSubtotal,
            fees: widget.fees,
            decimals: widget.currency.decimals,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feesStateProvider);
    final colors = context.colors;
    final money = CurrencyFormatter(widget.currency);

    return FractionallySizedBox(
      heightFactor: FeeMetrics.sheetHeightFactor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: FeeMetrics.sheetPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: FeeMetrics.grabWidth,
                  height: FeeMetrics.grabHeight,
                  margin: const EdgeInsets.only(bottom: FeeMetrics.grabBottomGap),
                  decoration: BoxDecoration(
                    color: colors.neutral3,
                    borderRadius: BorderRadius.circular(FeeMetrics.grabHeight / 2),
                  ),
                ),
              ),
              const SizedBox(height: FeeMetrics.blockGap),
              Padding(
                padding: FeeMetrics.horizontalPadding,
                child: Text(
                  LocaleKeys.sales_feesTitle.tr(),
                  style: context.textStyles.sansBodyBold.copyWith(
                    fontSize: FeeMetrics.titleSize,
                  ),
                ),
              ),
              const SizedBox(height: FeeMetrics.blockGap),
              Expanded(
                child: ListView(
                  padding: FeeMetrics.horizontalPadding,
                  children: [
                    if (state.fees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          LocaleKeys.sales_feeNoneYet.tr(),
                          textAlign: TextAlign.center,
                          style: context.textStyles.sansBody.copyWith(
                            color: colors.neutral6,
                          ),
                        ),
                      ),
                    for (final computed in state.computed)
                      FeeRow(
                        computed: computed,
                        signedAmount: state.amountFor(computed.fee.id),
                        money: money,
                        hasDiscount: state.hasDiscount,
                        onRemove: () => ref
                            .read(feesStateProvider.notifier)
                            .removeFee(computed.fee.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: FeeMetrics.blockGap),
              Padding(
                padding: FeeMetrics.horizontalPadding,
                child: _DiscountNotice(),
              ),
              const SizedBox(height: FeeMetrics.blockGap),
              Padding(
                padding: FeeMetrics.horizontalPadding,
                child: SaleSecondaryButton(
                  key: const Key('fees-add'),
                  label: LocaleKeys.sales_feeAdd.tr(),
                  icon: Icons.add_rounded,
                  small: true,
                  onPressed: _addFee,
                ),
              ),
              const SizedBox(height: FeeMetrics.blockGap),
              Padding(
                padding: FeeMetrics.horizontalPadding,
                child: SalePrimaryButton(
                  key: const Key('fees-done'),
                  label: LocaleKeys.sales_feeDone.tr(),
                  onPressed: () =>
                      Navigator.of(context).pop(ref.read(feesStateProvider).fees),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addFee() async {
    final fee = await showModalBottomSheet<Fee>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.neutral0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FeeMetrics.sheetRadius),
        ),
      ),
      builder: (_) => const _AddFeeSheet(),
    );
    if (fee == null || !mounted) return;
    ref.read(feesStateProvider.notifier).addFee(fee);
  }
}

class _DiscountNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: FeeMetrics.noticePadding,
      decoration: BoxDecoration(
        color: colors.primary0,
        borderRadius: BorderRadius.circular(FeeMetrics.noticeRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: FeeMetrics.noticeIconSize,
            color: colors.primary5,
          ),
          const SizedBox(width: FeeMetrics.noticeGap),
          Expanded(
            child: Text(
              LocaleKeys.sales_feeDiscountsFirst.tr(),
              style: context.textStyles.sansBody.copyWith(
                fontSize: FeeMetrics.noticeTextSize,
                height: FeeMetrics.noticeTextHeight,
                color: colors.primary5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFeeSheet extends StatefulWidget {
  const _AddFeeSheet();

  @override
  State<_AddFeeSheet> createState() => _AddFeeSheetState();
}

class _AddFeeSheetState extends State<_AddFeeSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _value = TextEditingController();
  FeeKind _kind = FeeKind.fixed;
  FeeDirection _direction = FeeDirection.buyerCharge;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  bool get _canAdd {
    final value = Decimal.tryParse(_value.text.trim());
    return _name.text.trim().isNotEmpty && value != null && value > Decimal.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  LocaleKeys.sales_feeAdd.tr(),
                  style: context.textStyles.sansBodyBold.copyWith(
                    fontSize: FeeMetrics.titleSize,
                  ),
                ),
                const SizedBox(height: FeeMetrics.blockGap),
                TextField(
                  key: const Key('add-fee-name'),
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: LocaleKeys.sales_feeName.tr(),
                  ),
                ),
                const SizedBox(height: FeeMetrics.blockGap),
                TextField(
                  key: const Key('add-fee-value'),
                  controller: _value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: LocaleKeys.sales_feeValue.tr(),
                  ),
                ),
                const SizedBox(height: FeeMetrics.blockGap),
                SegmentedButton<FeeKind>(
                  segments: [
                    ButtonSegment(
                      value: FeeKind.fixed,
                      label: Text(LocaleKeys.sales_feeKindFixed.tr()),
                    ),
                    ButtonSegment(
                      value: FeeKind.percent,
                      label: Text(LocaleKeys.sales_feeKindPercent.tr()),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (selection) =>
                      setState(() => _kind = selection.first),
                ),
                const SizedBox(height: FeeMetrics.blockGap),
                DropdownButtonFormField<FeeDirection>(
                  key: const Key('add-fee-direction'),
                  initialValue: _direction,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.sales_feeDirection.tr(),
                  ),
                  items: [
                    for (final direction in FeeDirection.values)
                      DropdownMenuItem(
                        value: direction,
                        child: Text(_directionLabel(direction)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _direction = value ?? _direction),
                ),
                const SizedBox(height: FeeMetrics.blockGap),
                SalePrimaryButton(
                  key: const Key('add-fee-confirm'),
                  label: LocaleKeys.sales_feeAdd.tr(),
                  onPressed: _canAdd ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      Fee(
        id: '',
        name: _name.text.trim(),
        kind: _kind,
        value: Decimal.parse(_value.text.trim()),
        direction: _direction,
      ),
    );
  }

  static String _directionLabel(FeeDirection direction) => switch (direction) {
    FeeDirection.discount => LocaleKeys.sales_feeDirDiscount.tr(),
    FeeDirection.passThrough => LocaleKeys.sales_feeDirPassThrough.tr(),
    FeeDirection.buyerCharge => LocaleKeys.sales_feeDirBuyer.tr(),
    FeeDirection.sellerCost => LocaleKeys.sales_feeDirSellerCost.tr(),
  };
}
