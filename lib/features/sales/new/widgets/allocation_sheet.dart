import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/new/states/allocation_state.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import 'allocation_metrics.dart';
import 'allocation_row.dart';
import 'manual_allocation_row.dart';
import 'sale_buttons.dart';

/// S21. The seller picks a product and a quantity — never a lot. The split is
/// resolved FEFO and shown before anything is added.
Future<SaleDraftLine?> showAllocationSheet(
  BuildContext context, {
  required ProductEntity product,
  Decimal? quantity,
  Decimal? sellPrice,
}) {
  return showModalBottomSheet<SaleDraftLine>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.neutral0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AllocationMetrics.sheetRadius),
      ),
    ),
    builder: (_) => AllocationSheet(
      product: product,
      quantity: quantity,
      sellPrice: sellPrice,
    ),
  );
}

class AllocationSheet extends ConsumerStatefulWidget {
  const AllocationSheet({
    super.key,
    required this.product,
    this.quantity,
    this.sellPrice,
  });

  final ProductEntity product;
  final Decimal? quantity;
  final Decimal? sellPrice;

  @override
  ConsumerState<AllocationSheet> createState() => _AllocationSheetState();
}

class _AllocationSheetState extends ConsumerState<AllocationSheet> {
  final TextEditingController _price = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref
          .read(allocationStateProvider.notifier)
          .open(
            widget.product,
            quantity: widget.quantity,
            sellPrice: widget.sellPrice,
          );
      if (mounted) _price.text = ref.read(allocationStateProvider).sellPrice;
    });
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(allocationStateProvider);
    final colors = context.colors;
    final money = CurrencyFormatter(ref.watch(saleCartStateProvider).currency);
    final today = ref.read(nowProvider)();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: AllocationMetrics.sheetPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: AllocationMetrics.grabWidth,
                    height: AllocationMetrics.grabHeight,
                    margin: const EdgeInsets.only(
                      bottom: AllocationMetrics.grabBottomGap,
                    ),
                    decoration: BoxDecoration(
                      color: colors.neutral3,
                      borderRadius: BorderRadius.circular(
                        AllocationMetrics.grabHeight / 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AllocationMetrics.blockGap),
                Padding(
                  padding: AllocationMetrics.horizontalPadding,
                  child: Text(
                    state.isManual
                        ? LocaleKeys.sales_manualTitle.tr()
                        : widget.product.name,
                    style: context.textStyles.sansBodyBold.copyWith(
                      fontSize: AllocationMetrics.titleSize,
                    ),
                  ),
                ),
                if (state.isManual)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: AllocationMetrics.innerGap,
                    ),
                    child: Text(
                      LocaleKeys.sales_manualSubtitle.tr(
                        namedArgs: {
                          'product': widget.product.name,
                          'quantity': state.quantity,
                        },
                      ),
                      style: context.textStyles.sansBody.copyWith(
                        fontSize: AllocationMetrics.subtitleSize,
                        color: colors.neutral6,
                      ),
                    ),
                  ),
                const SizedBox(height: AllocationMetrics.blockGap),
                Padding(
                  padding: AllocationMetrics.horizontalPadding,
                  child: _buildFields(context, state),
                ),
                const SizedBox(height: AllocationMetrics.blockGap),
                Padding(
                  padding: AllocationMetrics.horizontalPadding,
                  child: _buildSplit(context, state, money, today),
                ),
                const SizedBox(height: AllocationMetrics.blockGap),
                Padding(
                  padding: AllocationMetrics.horizontalPadding,
                  child: _buildTotal(context, state, money),
                ),
                const SizedBox(height: AllocationMetrics.blockGap),
                Padding(
                  padding: AllocationMetrics.horizontalPadding,
                  child: SalePrimaryButton(
                    key: const Key('allocation-add-to-sale'),
                    label: LocaleKeys.sales_allocAddToSale.tr(),
                    onPressed: state.canAdd
                        ? () => Navigator.of(context).pop(state.toLine())
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFields(BuildContext context, AllocationState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _Field(
            label: LocaleKeys.sales_allocQuantity.tr(),
            child: _QuantityStepper(state: state),
          ),
        ),
        const SizedBox(width: AllocationMetrics.fieldGap),
        Expanded(
          child: _Field(
            label: LocaleKeys.sales_allocSellPrice.tr(),
            child: _PriceField(controller: _price),
          ),
        ),
      ],
    );
  }

  Widget _buildSplit(
    BuildContext context,
    AllocationState state,
    CurrencyFormatter money,
    DateTime today,
  ) {
    final colors = context.colors;

    if (state.exceedsStock) {
      return _Notice(
        message: LocaleKeys.sales_allocNotEnough.tr(
          namedArgs: {'available': formatQuantity(state.totalRemaining)},
        ),
      );
    }
    if (state.fractionRefused) {
      return _Notice(message: LocaleKeys.sales_allocWholeUnits.tr());
    }
    if (state.allocations.isEmpty) return const SizedBox.shrink();

    final notifier = ref.read(allocationStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                LocaleKeys.sales_allocComesFrom.tr().toUpperCase(),
                style: context.textStyles.sansCaption.copyWith(
                  fontSize: AllocationMetrics.sectionLabelSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: AllocationMetrics.sectionSpacing,
                  color: colors.neutral6,
                ),
              ),
            ),
            InkWell(
              key: const Key('allocation-toggle-manual'),
              onTap: state.isManual ? notifier.leaveManual : notifier.enterManual,
              child: Text(
                state.isManual
                    ? LocaleKeys.sales_allocAuto.tr()
                    : LocaleKeys.sales_allocEdit.tr(),
                style: context.textStyles.sansCaption.copyWith(
                  fontSize: AllocationMetrics.linkSize,
                  fontWeight: FontWeight.w600,
                  color: colors.inkPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AllocationMetrics.innerGap),
        if (state.isManual) ...[
          for (final lot in state.manualLots) ...[
            if (lot != state.manualLots.first)
              const SizedBox(height: AllocationMetrics.innerGap),
            ManualAllocationRow(
              key: ValueKey('manual-${lot.batchId}'),
              lot: lot,
              money: money,
              onChanged: (value) =>
                  notifier.setManualQuantity(lot.batchId, value),
            ),
          ],
          if (!state.manualSumsExactly) ...[
            const SizedBox(height: AllocationMetrics.innerGap),
            _Notice(message: _mismatchMessage(state)),
          ],
        ] else
          for (final allocation in state.allocations) ...[
            if (allocation != state.allocations.first)
              const SizedBox(height: AllocationMetrics.innerGap),
            AllocationRow(allocation: allocation, money: money, today: today),
          ],
      ],
    );
  }

  /// §5.2.4 — the message names the shortfall so the seller knows exactly what
  /// to change, and Add to sale stays disabled until they do.
  static String _mismatchMessage(AllocationState state) {
    final requested = state.quantity;
    final allocated = formatQuantity(state.manualAllocated);
    if (state.manualExcess > Decimal.zero) {
      return LocaleKeys.sales_manualOver.tr(
        namedArgs: {
          'allocated': allocated,
          'requested': requested,
          'excess': formatQuantity(state.manualExcess),
        },
      );
    }
    return LocaleKeys.sales_manualShort.tr(
      namedArgs: {
        'allocated': allocated,
        'requested': requested,
        'missing': formatQuantity(state.manualMissing),
      },
    );
  }

  Widget _buildTotal(BuildContext context, AllocationState state, CurrencyFormatter money) {
    final colors = context.colors;

    return Container(
      padding: AllocationMetrics.totalPadding,
      decoration: BoxDecoration(
        color: colors.neutral1,
        borderRadius: BorderRadius.circular(AllocationMetrics.totalRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              LocaleKeys.sales_allocLineTotal.tr(
                namedArgs: {
                  'quantity': state.quantity,
                  'price': state.parsedSellPrice == null
                      ? '—'
                      : money.format(state.parsedSellPrice!),
                },
              ),
              style: context.textStyles.sansCaption.copyWith(
                fontSize: AllocationMetrics.totalKeySize,
                color: colors.neutral6,
              ),
            ),
          ),
          Text(
            money.format(state.lineTotal),
            key: const Key('allocation-line-total'),
            style: context.textStyles.monoBody.copyWith(
              fontSize: AllocationMetrics.totalValueSize,
              fontWeight: FontWeight.w500,
              color: colors.neutral9,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.sansCaption.copyWith(
            fontSize: AllocationMetrics.fieldLabelSize,
            fontWeight: FontWeight.w500,
            color: context.colors.neutral7,
          ),
        ),
        const SizedBox(height: AllocationMetrics.fieldLabelGap),
        child,
      ],
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  const _QuantityStepper({required this.state});

  final AllocationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notifier = ref.read(allocationStateProvider.notifier);

    Widget button(Key key, IconData icon, VoidCallback onTap) => InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AllocationMetrics.stepperButtonRadius),
      child: Container(
        width: AllocationMetrics.stepperButtonSize,
        height: AllocationMetrics.stepperButtonSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.neutral3,
            width: AllocationMetrics.stepperBorderWidth,
          ),
          borderRadius: BorderRadius.circular(
            AllocationMetrics.stepperButtonRadius,
          ),
        ),
        child: Icon(icon, color: colors.neutral7),
      ),
    );

    return Row(
      children: [
        button(
          const Key('allocation-decrement'),
          Icons.remove_rounded,
          notifier.decrement,
        ),
        const SizedBox(width: AllocationMetrics.stepperGap),
        Expanded(
          child: Container(
            height: AllocationMetrics.stepperValueHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.neutral0,
              border: Border.all(
                color: colors.primary4,
                width: AllocationMetrics.stepperBorderWidth,
              ),
              borderRadius: BorderRadius.circular(
                AllocationMetrics.stepperValueRadius,
              ),
            ),
            child: Text(
              state.quantity,
              key: const Key('allocation-quantity'),
              style: context.textStyles.monoBody.copyWith(
                fontSize: AllocationMetrics.stepperValueSize,
                color: colors.neutral9,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(width: AllocationMetrics.stepperGap),
        button(
          const Key('allocation-increment'),
          Icons.add_rounded,
          notifier.increment,
        ),
      ],
    );
  }
}

class _PriceField extends ConsumerWidget {
  const _PriceField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return SizedBox(
      height: AllocationMetrics.inputMinHeight,
      child: TextField(
        key: const Key('allocation-sell-price'),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: ref.read(allocationStateProvider.notifier).setSellPrice,
        style: context.textStyles.monoBody.copyWith(
          fontSize: AllocationMetrics.inputTextSize,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colors.neutral0,
          contentPadding: AllocationMetrics.inputPadding,
          border: _border(colors.neutral3),
          enabledBorder: _border(colors.neutral3),
          focusedBorder: _border(colors.primary4),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AllocationMetrics.inputRadius),
    borderSide: BorderSide(
      color: color,
      width: AllocationMetrics.stepperBorderWidth,
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: AllocationMetrics.noticePadding,
      decoration: BoxDecoration(
        color: colors.red0,
        borderRadius: BorderRadius.circular(AllocationMetrics.noticeRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: AllocationMetrics.noticeIconSize,
            color: colors.red5,
          ),
          const SizedBox(width: AllocationMetrics.noticeGap),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.sansBody.copyWith(
                fontSize: AllocationMetrics.noticeTextSize,
                height: AllocationMetrics.noticeTextHeight,
                color: colors.red5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
