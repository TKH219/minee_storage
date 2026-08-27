import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/detail/widgets/detail_notice.dart';
import 'package:mine_storage/features/sales/edit/states/transaction_edit_state.dart';
import 'package:mine_storage/features/sales/list/states/store_currency_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_snack.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';
import 'package:mine_storage/shared/utils/store_currency_formatter.dart';

/// Amending a movement. The edit is re-resolved against stock as it stands now
/// and the difference is named **before** Save — an amend rarely lands on the
/// lots the original drew from, and finding that out afterwards is too late.
class TransactionEditPage extends BasePage {
  const TransactionEditPage({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<TransactionEditPage> createState() => _TransactionEditPageState();
}

class _TransactionEditPageState
    extends
        BasePageState<
          TransactionEditPage,
          TransactionEditState,
          TransactionEditStateNotifier
        > {
  final Map<String, TextEditingController> _quantities = {};

  @override
  void initState() {
    allowToShowLoading = false;
    super.initState();
  }

  @override
  void dispose() {
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void setCurrentState() => currentState = ref.watch(transactionEditStateProvider);

  @override
  void setNotifier() => notifier = ref.read(transactionEditStateProvider.notifier);

  @override
  void initDataFromConstructor() => notifier.load(widget.transactionId);

  TextEditingController _controllerFor(EditLine line) {
    return _quantities.putIfAbsent(
      line.productId,
      () => TextEditingController(text: line.quantity),
    );
  }

  Future<void> _save() async {
    await notifier.commit();
    if (!mounted) return;
    if (ref.read(transactionEditStateProvider).didSave) {
      showSuccessSnack(LocaleKeys.sales_editSavedSnack.tr());
      if (mounted) context.pop();
    }
  }

  Future<void> _reload() async {
    await notifier.reload();
    if (!mounted) return;
    for (final line in ref.read(transactionEditStateProvider).lines) {
      _quantities[line.productId]?.text = line.quantity;
    }
  }

  @override
  Widget buildPageContent(BuildContext context) {
    final transaction = currentState.transaction;

    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: context.pop,
        ),
        title: Text(
          LocaleKeys.sales_editTitle.tr(
            namedArgs: {'code': transaction?.code ?? ''},
          ),
        ),
        actions: [
          TextButton(
            key: const Key('transaction-edit-save'),
            onPressed: currentState.canSave ? _save : null,
            child: Text(LocaleKeys.sales_editSave.tr()),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (currentState) {
          final s when s.isError && s.transaction == null => ErrorAwareContainer(
            message:
                s.errorMessage ??
                (s.errorMessageKey ?? LocaleKeys.sales_detailLoadFailed).tr(),
            onRetry: () => notifier.load(widget.transactionId),
          ),
          final s when s.transaction == null => ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) => const SkeletonRow(),
          ),
          final s when s.isStale => _buildStale(context),
          _ => _buildForm(context),
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final formatter = ref.watch(storeCurrencyFormatterProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        for (final line in currentState.lines) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AppTextField(
              key: Key('edit-quantity-${line.productId}'),
              label: LocaleKeys.sales_editQuantityChange.tr(
                namedArgs: {'product': line.productName},
              ),
              controller: _controllerFor(line),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                notifier.setQuantity(line.productId, value);
                notifier.preview();
              },
              errorText: line.isValid
                  ? null
                  : LocaleKeys.products_quantityAboveZero.tr(),
            ),
          ),
          if (line.hasChanged && line.isValid)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: DetailKeyValue(
                label: line.productName,
                value:
                    '${formatQuantity(line.originalQuantity)} → '
                    '${formatQuantity(line.parsed!)}',
                emphasise: true,
              ),
            ),
        ],
        DetailSectionLabel(label: LocaleKeys.sales_editWasLots.tr()),
        for (final lot in currentState.originalLots)
          _LotRow(lot: lot, formatter: formatter, faded: true),
        if (!currentState.hasPreview)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DetailNotice(message: LocaleKeys.sales_editPreviewFirst.tr()),
          )
        else ...[
          DetailSectionLabel(label: LocaleKeys.sales_editNowLots.tr()),
          for (final lot in currentState.newLots)
            _LotRow(lot: lot, formatter: formatter),
          if (currentState.lotSetChanged)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: DetailNotice(
                key: const Key('edit-lot-set-changed'),
                tone: NoticeTone.warn,
                message: LocaleKeys.sales_editBatchSetChanged.tr(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailKeyValue(
                  key: const Key('edit-cogs-after'),
                  label: LocaleKeys.sales_editCogsAfter.tr(),
                  value: formatter.format(
                    currentState.previewedCogs ?? currentState.originalCogs,
                  ),
                  emphasise: true,
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleKeys.sales_editCogsWas.tr(
                    namedArgs: {
                      'before': formatter.format(currentState.originalCogs),
                      'delta': formatter.formatSigned(currentState.cogsDelta),
                    },
                  ),
                  style: context.textStyles.sansCaption.copyWith(
                    color: context.colors.neutral6,
                  ),
                ),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 52,
                child: OutlinedButton(
                  onPressed: context.pop,
                  child: Text(LocaleKeys.sales_editBack.tr()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const Key('transaction-edit-save-changes'),
                    onPressed: currentState.canSave ? _save : null,
                    child: Text(LocaleKeys.sales_editSaveChanges.tr()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// A stale write, shown as a diff rather than a failure. Retrying blind would
  /// silently overwrite someone else's work, so the only forward action is to
  /// reload and look again.
  Widget _buildStale(BuildContext context) {
    final formatter = ref.watch(storeCurrencyFormatterProvider);

    return ListView(
      key: const Key('transaction-edit-stale'),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: DetailNotice(
            tone: NoticeTone.warn,
            message: LocaleKeys.sales_editStaleTitle.tr(),
          ),
        ),
        if (currentState.serverDiff.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DetailLotCard(
              title: currentState.transaction?.code ?? '',
              rows: [
                for (final change in currentState.serverDiff)
                  DetailKeyValue(
                    label: _changeLabel(change),
                    value: _changeValue(change, formatter),
                    emphasise: change.field == ServerChangeField.buyerTotal,
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: DetailNotice(message: LocaleKeys.sales_editStaleBody.tr()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const Key('transaction-edit-reload'),
              onPressed: _reload,
              child: Text(LocaleKeys.sales_editStaleReload.tr()),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton(
            onPressed: context.pop,
            child: Text(LocaleKeys.sales_editStaleDiscard.tr()),
          ),
        ),
      ],
    );
  }

  String _changeLabel(ServerChange change) => switch (change.field) {
    ServerChangeField.paymentMethod => LocaleKeys.sales_detailPaidBy.tr(),
    ServerChangeField.quantity => change.name ?? '',
    ServerChangeField.buyerTotal => LocaleKeys.sales_detailBuyerPaid.tr(),
  };

  String _changeValue(ServerChange change, StoreCurrencyFormatter formatter) =>
      switch (change.field) {
        ServerChangeField.paymentMethod =>
          '${_paymentLabel(change.beforeMethod)} → ${_paymentLabel(change.afterMethod)}',
        ServerChangeField.quantity =>
          '${formatQuantity(change.beforeAmount!)} → ${formatQuantity(change.afterAmount!)}',
        ServerChangeField.buyerTotal =>
          '${formatter.format(change.beforeAmount!)} → ${formatter.format(change.afterAmount!)}',
      };

  String _paymentLabel(PaymentMethod? method) => switch (method) {
    null => '—',
    PaymentMethod.cash => LocaleKeys.sales_payCash.tr(),
    PaymentMethod.bankTransfer => LocaleKeys.sales_payBankTransfer.tr(),
    PaymentMethod.card => LocaleKeys.sales_payCard.tr(),
    PaymentMethod.eWallet => LocaleKeys.sales_payEWallet.tr(),
    PaymentMethod.other => LocaleKeys.sales_payOther.tr(),
  };
}

class _LotRow extends StatelessWidget {
  const _LotRow({required this.lot, required this.formatter, this.faded = false});

  final EditLot lot;
  final StoreCurrencyFormatter formatter;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.neutral0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: faded ? colors.neutral2 : colors.primary2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: faded ? colors.neutral2 : colors.highlight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                formatQuantity(lot.quantity),
                style: styles.monoBody.copyWith(
                  color: faded ? colors.neutral7 : colors.primary5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.batchCode,
                    style: styles.sansBodyBold.copyWith(color: colors.neutral9),
                  ),
                  Text(
                    LocaleKeys.sales_editLotLine.tr(
                      namedArgs: {
                        'cost': formatter.format(lot.unitCost),
                        'total': formatter.format(lot.lineCost),
                      },
                    ),
                    style: styles.sansCaption.copyWith(color: colors.neutral6),
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
