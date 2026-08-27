import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/date_time_extensions.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/write_off_state.dart';
import 'package:mine_storage/features/products/detail/widgets/lot_picker_tiles.dart';
import 'package:mine_storage/features/sales/list/states/store_currency_state.dart';
import 'package:mine_storage/features/sales/list/widgets/ledger_labels.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_filter_chip.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';

/// Stock leaving for a reason that is not a sale.
///
/// No payment method and no fee editor: nothing was bought or sold here, so
/// neither field has an honest value to hold.
class WriteOffSheet extends ConsumerStatefulWidget {
  const WriteOffSheet({super.key, required this.product, this.batch});

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
      builder: (_) => WriteOffSheet(product: product, batch: batch),
    );
  }

  @override
  ConsumerState<WriteOffSheet> createState() => _WriteOffSheetState();
}

class _WriteOffSheetState extends ConsumerState<WriteOffSheet> {
  final _quantity = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(writeOffStateProvider.notifier)
          .open(widget.product, batch: widget.batch);
    });
  }

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    await ref.read(writeOffStateProvider.notifier).commit();
    if (!mounted) return;
    if (!ref.read(writeOffStateProvider).didCommit) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(writeOffStateProvider);
    final notifier = ref.read(writeOffStateProvider.notifier);
    final formatter = ref.watch(storeCurrencyFormatterProvider);
    final colors = context.colors;
    final styles = context.textStyles;
    final batch = state.batch;

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
                LocaleKeys.products_writeOffTitle.tr(),
                style: styles.sansTitleHeading3,
              ),
              const SizedBox(height: 4),
              Text(
                batch == null
                    ? LocaleKeys.products_writeOffNoLots.tr()
                    : LocaleKeys.products_writeOffSubtitle.tr(
                        namedArgs: {
                          'product': widget.product.name,
                          'lot': batch.expiryDate.formatOr(batch.batchCode),
                          'remaining': formatQuantity(batch.remainingQuantity),
                        },
                      ),
                style: styles.sansCaption.copyWith(color: colors.neutral6),
              ),
              if (state.lots.length > 1) ...[
                const SizedBox(height: 12),
                LotPickerTiles(
                  lots: state.lots,
                  selected: batch,
                  onSelect: notifier.selectBatch,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                LocaleKeys.products_writeOffReason.tr(),
                style: styles.sansTableHeader.copyWith(color: colors.neutral7),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reason in WriteOffReason.values)
                    AppFilterChip(
                      key: Key('write-off-reason-${reason.name}'),
                      label: writeOffReasonLabel(reason),
                      selected: state.reason == reason,
                      onTap: () => notifier.selectReason(reason),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                key: const Key('write-off-quantity'),
                label: LocaleKeys.products_writeOffQuantity.tr(),
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: notifier.updateQuantity,
                helperText: batch == null
                    ? null
                    : LocaleKeys.products_writeOffCap.tr(
                        namedArgs: {
                          'remaining': formatQuantity(batch.remainingQuantity),
                        },
                      ),
                errorText: switch (state) {
                  final s when s.exceedsLot => LocaleKeys.products_notEnoughStock.tr(
                    namedArgs: {'available': formatQuantity(s.remaining)},
                  ),
                  final s when s.fractionRefused =>
                    LocaleKeys.products_quantityAboveZero.tr(),
                  _ => null,
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: LocaleKeys.sales_detailNote.tr(),
                hint: LocaleKeys.products_writeOffNote.tr(),
                controller: _note,
                onChanged: notifier.updateNote,
              ),
              const SizedBox(height: 20),
              if (batch != null && state.parsedQuantity != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        LocaleKeys.products_writeOffValue.tr(
                          namedArgs: {
                            'quantity': state.quantity.trim(),
                            'cost': formatter.format(batch.unitPrice),
                          },
                        ),
                        style: styles.sansCaption.copyWith(color: colors.neutral6),
                      ),
                    ),
                    Text(
                      formatter.format(state.valueLeaving),
                      key: const Key('write-off-value'),
                      style: styles.monoBody.copyWith(color: colors.neutral9),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('write-off-commit'),
                  style: FilledButton.styleFrom(backgroundColor: colors.red5),
                  onPressed: state.canCommit ? _commit : null,
                  child: Text(
                    LocaleKeys.products_writeOffButton.tr(
                      namedArgs: {
                        'quantity': formatQuantity(
                          state.parsedQuantity ?? Decimal.zero,
                        ),
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
