import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/date_time_extensions.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/receive_state.dart';
import 'package:mine_storage/features/sales/detail/widgets/detail_notice.dart';
import 'package:mine_storage/features/sales/list/states/store_currency_state.dart';
import 'package:mine_storage/features/sales/new/widgets/fees_sheet.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_option_sheet.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';

/// A delivery in, written as a `receive` transaction that opens the lot.
///
/// The one movement sheet that carries money in both directions, so the one
/// that gets a supplier, a payment method and a fee editor.
class ReceiveSheet extends ConsumerStatefulWidget {
  const ReceiveSheet({super.key, required this.product});

  final ProductEntity product;

  static Future<bool?> show(BuildContext context, {required ProductEntity product}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.neutral0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReceiveSheet(product: product),
    );
  }

  @override
  ConsumerState<ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends ConsumerState<ReceiveSheet> {
  final _quantity = TextEditingController();
  final _unitCost = TextEditingController();
  final _batchCode = TextEditingController();
  final _supplier = TextEditingController();
  final _location = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(receiveStateProvider.notifier).open(widget.product);
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _quantity,
      _unitCost,
      _batchCode,
      _supplier,
      _location,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExpiry(DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      ref.read(receiveStateProvider.notifier).updateExpiry(picked);
    }
  }

  Future<void> _pickPaymentMethod(PaymentMethod selected) async {
    final picked = await showAppOptionSheet<PaymentMethod>(
      context: context,
      title: LocaleKeys.products_receivePaidBy.tr(),
      options: [
        for (final method in PaymentMethodX.selectable)
          AppOption(value: method, label: _paymentLabel(method)),
      ],
      selected: selected,
    );
    if (picked != null && mounted) {
      ref.read(receiveStateProvider.notifier).selectPaymentMethod(picked);
    }
  }

  Future<void> _editFees(ReceiveState state) async {
    final currency = await ref.read(storeCurrencyProvider.future);
    if (!mounted) return;
    final edited = await showFeesSheet(
      context,
      itemsSubtotal: state.goodsTotal,
      fees: state.fees,
      currency: currency,
      // A receive has no seller side, so the two directions it can carry are
      // what folds into the lot's cost and what comes off the invoice.
      directions: const [FeeDirection.buyerCharge, FeeDirection.discount],
    );
    if (edited != null && mounted) {
      ref.read(receiveStateProvider.notifier).updateFees(edited);
    }
  }

  Future<void> _commit() async {
    await ref.read(receiveStateProvider.notifier).commit();
    if (!mounted) return;
    if (!ref.read(receiveStateProvider).didCommit) return;
    Navigator.of(context).pop(true);
  }

  static String _paymentLabel(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => LocaleKeys.sales_payCash.tr(),
    PaymentMethod.bankTransfer => LocaleKeys.sales_payBankTransfer.tr(),
    PaymentMethod.card => LocaleKeys.sales_payCard.tr(),
    PaymentMethod.eWallet => LocaleKeys.sales_payEWallet.tr(),
    PaymentMethod.other => LocaleKeys.sales_payOther.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiveStateProvider);
    final notifier = ref.read(receiveStateProvider.notifier);
    final formatter = ref.watch(storeCurrencyFormatterProvider);
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
                LocaleKeys.products_receiveTitle.tr(
                  namedArgs: {'product': widget.product.name},
                ),
                style: styles.sansTitleHeading3,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      key: const Key('receive-quantity'),
                      label: LocaleKeys.products_quantity.tr(),
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: notifier.updateQuantity,
                      errorText: state.fractionRefused
                          ? LocaleKeys.products_quantityAboveZero.tr()
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      key: const Key('receive-unit-cost'),
                      label: LocaleKeys.products_receiveUnitCost.tr(),
                      controller: _unitCost,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: notifier.updateUnitCost,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      key: const Key('receive-expiry'),
                      label: LocaleKeys.products_expiresOn.tr(),
                      value: state.expiryDate.formatOr('—'),
                      icon: Icons.calendar_today_outlined,
                      onTap: () => _pickExpiry(state.expiryDate),
                    ),
                  ),
                  IconButton(
                    key: const Key('receive-clear-expiry'),
                    onPressed: () => notifier.updateExpiry(null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: LocaleKeys.products_receiveLotCode.tr(),
                hint: LocaleKeys.products_optional.tr(),
                controller: _batchCode,
                onChanged: notifier.updateBatchCode,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: LocaleKeys.products_supplier.tr(),
                hint: LocaleKeys.products_optional.tr(),
                controller: _supplier,
                onChanged: notifier.updateSupplier,
              ),
              const SizedBox(height: 16),
              _PickerField(
                key: const Key('receive-payment-method'),
                label: LocaleKeys.products_receivePaidBy.tr(),
                value: _paymentLabel(state.paymentMethod),
                icon: Icons.expand_more_rounded,
                onTap: () => _pickPaymentMethod(state.paymentMethod),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: LocaleKeys.products_storageLocation.tr(),
                hint: LocaleKeys.products_storageLocationHint.tr(),
                controller: _location,
                onChanged: notifier.updateStorageLocation,
              ),
              const SizedBox(height: 16),
              for (final fee in state.fees)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: DetailKeyValue(
                    label:
                        '${fee.name} · '
                        '${fee.direction == FeeDirection.discount ? LocaleKeys.sales_detailDiscountTag.tr() : LocaleKeys.sales_detailIntoCost.tr()}',
                    value: fee.kind == FeeKind.fixed
                        ? formatter.format(fee.value)
                        : '${fee.value}%',
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('receive-edit-fees'),
                  onPressed: () => _editFees(state),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(LocaleKeys.sales_feesTitle.tr()),
                ),
              ),
              const SizedBox(height: 8),
              DetailNotice(message: LocaleKeys.products_receiveFeesNotice.tr()),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.sales_detailGoodsInvoiced.tr(),
                    style: styles.sansCaption.copyWith(color: colors.neutral6),
                  ),
                  Text(
                    formatter.format(state.goodsTotal),
                    key: const Key('receive-goods-total'),
                    style: styles.monoBody.copyWith(color: colors.neutral9),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('receive-commit'),
                  onPressed: state.canCommit ? _commit : null,
                  child: Text(
                    LocaleKeys.products_receiveButton.tr(
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

/// A field the design draws as an input but which opens a picker.
class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textStyles.sansTableHeader.copyWith(
            color: context.colors.neutral7,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          readOnly: true,
          canRequestFocus: false,
          controller: TextEditingController(text: value),
          onTap: onTap,
          decoration: InputDecoration(
            suffixIcon: Icon(icon, color: context.colors.neutral6),
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      ],
    );
  }
}
