import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/date_time_extensions.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/lot_form_state.dart';
import 'package:mine_storage/features/settings/states/settings_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/app_option_sheet.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';

/// Receiving stock — where cost and expiry enter the system.
///
/// Two controls here are not in the design: the shop the delivery landed at,
/// and where it physically sits. Both follow from a product belonging to a user
/// rather than a shop; see `.ai/design/deviations-product-catalogue.md`.
class LotSheet extends ConsumerStatefulWidget {
  const LotSheet({super.key, required this.product, this.batch});

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
      builder: (_) => LotSheet(product: product, batch: batch),
    );
  }

  @override
  ConsumerState<LotSheet> createState() => _LotSheetState();
}

class _LotSheetState extends ConsumerState<LotSheet> {
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  final _supplier = TextEditingController();
  List<Store> _stores = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(lotFormStateProvider.notifier).open(widget.product, batch: widget.batch);
      final batch = widget.batch;
      if (batch != null) {
        _quantity.text = batch.initialQuantity.toString();
        _price.text = batch.unitPrice.toString();
        _location.text = batch.storageLocation ?? '';
        _supplier.text = batch.supplier ?? '';
      }
      _loadStores();
    });
  }

  Future<void> _loadStores() async {
    try {
      final stores = await ref.read(storeRepositoryProvider).listMine();
      if (mounted) setState(() => _stores = stores);
    } on Object {
      // The picker falls back to the active store, which is already selected.
    }
  }

  @override
  void dispose() {
    for (final c in [_quantity, _price, _location, _supplier]) {
      c.dispose();
    }
    super.dispose();
  }

  String _storeName(String? id) {
    for (final store in _stores) {
      if (store.id == id) return store.name;
    }
    return id ?? '';
  }

  Future<void> _pickStore(LotFormState state) async {
    if (_stores.isEmpty) return;
    final picked = await showAppOptionSheet<String>(
      context: context,
      title: LocaleKeys.products_store.tr(),
      options: [
        for (final store in _stores) AppOption(value: store.id, label: store.name),
      ],
      selected: state.storeId,
    );
    if (picked != null) ref.read(lotFormStateProvider.notifier).updateStore(picked);
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lotFormStateProvider);
    final notifier = ref.read(lotFormStateProvider.notifier);
    final money = ref.watch(currencyFormatterProvider);
    final colors = context.colors;

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
                (widget.batch == null
                        ? LocaleKeys.products_receiveStock
                        : LocaleKeys.products_editLot)
                    .tr(),
                style: context.textStyles.sansTitleHeading3,
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.name,
                style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
              ),
              const SizedBox(height: 16),
              _ReadOnlyField(
                key: const Key('lot-store-field'),
                label: LocaleKeys.products_store.tr(),
                value: _storeName(state.storeId),
                onTap: () => _pickStore(state),
              ),
              const SizedBox(height: 16),
              _ReadOnlyField(
                label: LocaleKeys.products_purchasedOn.tr(),
                value: state.purchasedAt.formatOr('—'),
                onTap: () => _pickDate(
                  initial: state.purchasedAt,
                  onPicked: (v) => notifier.updatePurchasedAt(v!),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ReadOnlyField(
                      label: LocaleKeys.products_expiresOn.tr(),
                      value: state.expiryDate.formatOr('—'),
                      enabled: true,
                      errorText: state.expiryIsInvalid
                          ? LocaleKeys.products_expiryAfterPurchase.tr()
                          : null,
                      onTap: () => _pickDate(
                        initial: state.expiryDate,
                        onPicked: notifier.updateExpiryDate,
                      ),
                    ),
                  ),
                  // Clearing greys the date rather than hiding the field, so an
                  // undated lot still reads as a deliberate choice.
                  IconButton(
                    key: const Key('lot-clear-expiry'),
                    onPressed: () => notifier.updateExpiryDate(null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: LocaleKeys.products_unitPrice.tr(),
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: notifier.updateUnitPrice,
                      errorText: state.priceIsInvalid
                          ? LocaleKeys.products_priceNotNegative.tr()
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      label: LocaleKeys.products_quantity.tr(),
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: notifier.updateQuantity,
                      errorText: _quantityError(state),
                    ),
                  ),
                ],
              ),
              if (state.drawnQuantity != null) ...[
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.products_remainingMovesWithStock.tr(),
                  key: const Key('lot-remaining-note'),
                  style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: LocaleKeys.products_storageLocation.tr(),
                hint: LocaleKeys.products_storageLocationHint.tr(),
                controller: _location,
                onChanged: notifier.updateStorageLocation,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: LocaleKeys.products_supplier.tr(),
                hint: LocaleKeys.products_optional.tr(),
                controller: _supplier,
                onChanged: notifier.updateSupplier,
              ),
              const SizedBox(height: 20),
              // Computed for display and never stored: it is quantity x price.
              if (state.lotTotal != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.products_lotTotalLive.tr(
                        namedArgs: {
                          'qty': state.quantity.trim(),
                          'price': money.format(
                            Decimal.tryParse(state.unitPrice.trim()) ?? Decimal.zero,
                          ),
                        },
                      ),
                      style: context.textStyles.sansCaption.copyWith(
                        color: colors.neutral6,
                      ),
                    ),
                    Text(
                      money.format(state.lotTotal!),
                      key: const Key('lot-total-value'),
                      style: context.textStyles.monoBody.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('lot-save-button'),
                  onPressed: state.canSubmit
                      ? () async {
                          await notifier.submit();
                          if (!context.mounted) return;
                          if (ref.read(lotFormStateProvider).didSave) {
                            Navigator.of(context).pop(true);
                          }
                        }
                      : null,
                  child: Text(
                    (widget.batch == null
                            ? LocaleKeys.products_addLot
                            : LocaleKeys.products_saveLot)
                        .tr(),
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

String? _quantityError(LotFormState state) {
  if (state.quantityIsInvalid) return LocaleKeys.products_quantityAboveZero.tr();
  if (state.quantityBelowDrawn) {
    return LocaleKeys.products_quantityBelowDrawn.tr(
      namedArgs: {'drawn': state.drawnQuantity.toString()},
    );
  }
  return null;
}

/// A field the design draws as an input but which opens a picker.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool enabled;
  final String? errorText;

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
            errorText: errorText,
            suffixIcon: Icon(Icons.calendar_today_outlined, color: context.colors.neutral6),
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      ],
    );
  }
}
