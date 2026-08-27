import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/stock_count_state.dart';
import 'package:mine_storage/features/products/detail/widgets/lot_picker_tiles.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';

/// Setting one lot to what is actually on the shelf.
///
/// Not one money figure appears: a count moves quantity, and the lot keeps the
/// cost it was received at.
class StockCountSheet extends ConsumerStatefulWidget {
  const StockCountSheet({super.key, required this.product, this.batch});

  final ProductEntity product;
  final ProductBatchEntity? batch;

  static Future<bool?> show(
    BuildContext context, {
    required ProductEntity product,
    ProductBatchEntity? batch,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.neutral0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StockCountSheet(product: product, batch: batch),
    );
  }

  @override
  ConsumerState<StockCountSheet> createState() => _StockCountSheetState();
}

class _StockCountSheetState extends ConsumerState<StockCountSheet> {
  final _counted = TextEditingController();
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(stockCountStateProvider.notifier)
          .open(widget.product, batch: widget.batch);
    });
  }

  @override
  void dispose() {
    _counted.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    await ref.read(stockCountStateProvider.notifier).commit();
    if (!mounted) return;
    if (!ref.read(stockCountStateProvider).didCommit) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockCountStateProvider);
    final notifier = ref.read(stockCountStateProvider.notifier);
    final colors = context.colors;
    final styles = context.textStyles;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.products_countTitle.tr(),
                style: styles.sansTitleHeading3,
              ),
              const SizedBox(height: 4),
              Text(
                state.lots.length == 1
                    ? LocaleKeys.products_countOneLot.tr(
                        namedArgs: {'product': widget.product.name},
                      )
                    : LocaleKeys.products_countSubtitle.tr(
                        namedArgs: {
                          'product': widget.product.name,
                          'count': '${state.lots.length}',
                        },
                      ),
                style: styles.sansCaption.copyWith(color: colors.neutral6),
              ),
              if (state.lots.length > 1) ...[
                const SizedBox(height: 16),
                Text(
                  LocaleKeys.products_countWhichLot.tr(),
                  style: styles.sansTableHeader.copyWith(color: colors.neutral7),
                ),
                const SizedBox(height: 4),
                LotPickerTiles(
                  lots: state.lots,
                  selected: state.batch,
                  onSelect: notifier.selectBatch,
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                key: const Key('stock-count-counted'),
                label: LocaleKeys.products_countCounted.tr(),
                controller: _counted,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: notifier.updateCounted,
                errorText: state.fractionRefused
                    ? LocaleKeys.products_quantityAboveZero.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      LocaleKeys.products_countDifference.tr(),
                      style: styles.sansCaption.copyWith(color: colors.neutral6),
                    ),
                  ),
                  Text(
                    formatQuantity(state.difference),
                    key: const Key('stock-count-difference'),
                    style: styles.monoBody.copyWith(
                      color: state.difference < Decimal.zero
                          ? colors.red5
                          : state.difference > Decimal.zero
                          ? colors.green5
                          : colors.neutral6,
                    ),
                  ),
                ],
              ),
              if (state.isUnchanged) ...[
                const SizedBox(height: 6),
                Text(
                  LocaleKeys.products_countNoChange.tr(),
                  key: const Key('stock-count-unchanged'),
                  style: styles.sansCaption.copyWith(color: colors.neutral6),
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                key: const Key('stock-count-reason'),
                label: LocaleKeys.products_countReason.tr(),
                controller: _reason,
                onChanged: notifier.updateReason,
                helperText: LocaleKeys.products_countReasonHelp.tr(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('stock-count-commit'),
                  onPressed: state.canCommit ? _commit : null,
                  child: Text(LocaleKeys.products_countApply.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
