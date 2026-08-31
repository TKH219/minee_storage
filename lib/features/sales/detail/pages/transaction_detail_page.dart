import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/widgets/receive_sheet.dart';
import 'package:mine_storage/features/sales/detail/states/transaction_detail_state.dart';
import 'package:mine_storage/features/sales/detail/widgets/detail_notice.dart';
import 'package:mine_storage/features/sales/detail/widgets/transaction_money_panel.dart';
import 'package:mine_storage/features/sales/list/states/store_currency_state.dart';
import 'package:mine_storage/features/sales/list/widgets/ledger_labels.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_snack.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';
import 'package:mine_storage/shared/utils/store_currency_formatter.dart';
import 'package:go_router/go_router.dart';

final _stamp = DateFormat('d MMM HH:mm');

/// S26 — one movement, read back. What it shows is decided by the type: a
/// delivery has no profit to measure, and a count has no money at all.
class TransactionDetailPage extends BasePage {
  const TransactionDetailPage({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState
    extends
        BasePageState<
          TransactionDetailPage,
          TransactionDetailState,
          TransactionDetailStateNotifier
        > {
  @override
  void initState() {
    allowToShowLoading = false;
    super.initState();
  }

  @override
  void setCurrentState() => currentState = ref.watch(transactionDetailStateProvider);

  @override
  void setNotifier() => notifier = ref.read(transactionDetailStateProvider.notifier);

  @override
  void initDataFromConstructor() => notifier.load(widget.transactionId);

  Future<void> _confirmDelete(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('transaction-delete-dialog'),
        title: Text(LocaleKeys.sales_deleteTitle.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.sales_deleteBody.tr(
                namedArgs: {'code': transaction.code},
              ),
              style: dialogContext.textStyles.sansBody,
            ),
            const SizedBox(height: 12),
            // Naming every destination is the point: "stock will be restored"
            // is true and useless, this is checkable against the shelf.
            for (final back in currentState.stockReturns)
              DetailKeyValue(
                label: '${back.batchCode} · ${back.productName}',
                value: '+${formatQuantity(back.quantity)}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LocaleKeys.sales_deleteKeep.tr()),
          ),
          TextButton(
            key: const Key('transaction-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              LocaleKeys.sales_deleteConfirm.tr(),
              style: dialogContext.textStyles.sansBodyBold.copyWith(
                color: dialogContext.colors.red5,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await notifier.delete();
    if (!mounted) return;
    if (ref.read(transactionDetailStateProvider).didDelete) {
      showSuccessSnack(LocaleKeys.sales_deletedSnack.tr());
      if (mounted) context.pop();
    }
  }

  @override
  Widget buildPageContent(BuildContext context) {
    final transaction = currentState.transaction;

    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(
        title: Text(
          transaction?.code ?? '',
          style: context.textStyles.monoBody.copyWith(color: context.colors.neutral9),
        ),
        actions: [
          if (transaction != null) ...[
            IconButton(
              key: const Key('transaction-edit-button'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.pushNamed(
                AppRoutes.transactionEditName,
                pathParameters: {'id': transaction.id},
              ),
            ),
            IconButton(
              key: const Key('transaction-delete-button'),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: currentState.isDeleting
                  ? null
                  : () => _confirmDelete(transaction),
            ),
          ],
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
            key: const Key('transaction-detail-skeleton'),
            itemCount: 4,
            itemBuilder: (context, index) => const SkeletonRow(),
          ),
          _ => _buildLoaded(context, transaction!),
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, Transaction transaction) {
    final formatter = ref.watch(storeCurrencyFormatterProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        DetailStatRow(stats: _headerStats(transaction, formatter)),
        if (currentState.reversalBlocked != null)
          _buildReversalRefused(context, currentState.reversalBlocked!),
        if (transaction.isAmended)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DetailNotice(
              key: const Key('transaction-edited-notice'),
              message: LocaleKeys.sales_detailEditedAt.tr(
                namedArgs: {'date': _stamp.format(transaction.amendedAt!.toLocal())},
              ),
            ),
          ),
        for (final line in currentState.movedCostLines)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DetailNotice(
              key: Key('cost-moved-${line.id}'),
              tone: NoticeTone.warn,
              message: LocaleKeys.sales_detailCostMoved.tr(
                namedArgs: {
                  'lot': line.batchCode,
                  'now': formatter.format(line.batchUnitCost!),
                  'frozen': formatter.format(line.unitCostSnapshot),
                },
              ),
            ),
          ),
        ...switch (transaction.type) {
          TransactionType.sale => _buildSaleBody(context, transaction, formatter),
          TransactionType.receive => _buildReceiveBody(context, transaction, formatter),
          TransactionType.writeOff => _buildWriteOffBody(context, transaction, formatter),
          TransactionType.adjust => _buildAdjustBody(context, transaction, formatter),
        },
        if (transaction.note != null && transaction.note!.isNotEmpty) ...[
          DetailSectionLabel(label: LocaleKeys.sales_detailNote.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              transaction.note!,
              style: context.textStyles.sansBody.copyWith(
                color: context.colors.neutral7,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<(String, String)> _headerStats(
    Transaction transaction,
    StoreCurrencyFormatter formatter,
  ) {
    final recorded = _stamp.format(transaction.occurredAt.toLocal());
    return switch (transaction.type) {
      TransactionType.sale => [
        (
          LocaleKeys.sales_detailBuyer.tr(),
          transaction.counterparty ?? LocaleKeys.sales_walkIn.tr(),
        ),
        (LocaleKeys.sales_detailRecorded.tr(), recorded),
        (LocaleKeys.sales_detailPaidBy.tr(), _paymentLabel(transaction)),
      ],
      TransactionType.receive => [
        (LocaleKeys.sales_detailSupplier.tr(), transaction.counterparty ?? '—'),
        (LocaleKeys.sales_detailRecorded.tr(), recorded),
        (LocaleKeys.sales_detailPaidBy.tr(), _paymentLabel(transaction)),
      ],
      TransactionType.writeOff => [
        (
          LocaleKeys.sales_detailReason.tr(),
          transaction.reason == null ? '—' : writeOffReasonLabel(transaction.reason!),
        ),
        (LocaleKeys.sales_detailRecorded.tr(), recorded),
        (
          LocaleKeys.sales_detailQuantity.tr(),
          formatQuantity(transaction.netQuantityDelta),
        ),
      ],
      TransactionType.adjust => _adjustHeaderStats(transaction, recorded),
    };
  }

  /// Counted against previously held, as `#ledger` draws it. A line written
  /// before `quantity_before` existed cannot answer either question, so those
  /// fall back to the delta the server applied.
  List<(String, String)> _adjustHeaderStats(Transaction transaction, String recorded) {
    final counted = transaction.lines
        .map((line) => line.countedQuantity)
        .whereType<Decimal>()
        .fold<Decimal?>(null, (sum, value) => (sum ?? Decimal.zero) + value);
    final before = transaction.lines
        .map((line) => line.quantityBefore)
        .whereType<Decimal>()
        .fold<Decimal?>(null, (sum, value) => (sum ?? Decimal.zero) + value);

    if (counted == null || before == null) {
      return [
        (
          LocaleKeys.sales_detailAppliedDelta.tr(),
          formatQuantity(transaction.netQuantityDelta),
        ),
        (LocaleKeys.sales_detailRecorded.tr(), recorded),
        (
          LocaleKeys.sales_detailProduct.tr(),
          transaction.lines.isEmpty ? '—' : transaction.lines.first.productName,
        ),
      ];
    }

    return [
      (LocaleKeys.sales_detailCounted.tr(), formatQuantity(counted)),
      (LocaleKeys.sales_detailPreviously.tr(), formatQuantity(before)),
      (
        LocaleKeys.sales_detailDifference.tr(),
        formatQuantity(transaction.netQuantityDelta),
      ),
    ];
  }

  String _paymentLabel(Transaction transaction) => switch (transaction.paymentMethod) {
    null => '—',
    PaymentMethod.cash => LocaleKeys.sales_payCash.tr(),
    PaymentMethod.bankTransfer => LocaleKeys.sales_payBankTransfer.tr(),
    PaymentMethod.card => LocaleKeys.sales_payCard.tr(),
    PaymentMethod.eWallet => LocaleKeys.sales_payEWallet.tr(),
    PaymentMethod.other => LocaleKeys.sales_payOther.tr(),
  };

  List<Widget> _buildSaleBody(
    BuildContext context,
    Transaction transaction,
    StoreCurrencyFormatter formatter,
  ) => [
    for (final group in currentState.linesByProduct)
      _ProductLineCard(group: group, formatter: formatter),
    TransactionMoneyPanel(transaction: transaction, formatter: formatter),
  ];

  List<Widget> _buildReceiveBody(
    BuildContext context,
    Transaction transaction,
    StoreCurrencyFormatter formatter,
  ) => [
    for (final group in currentState.linesByProduct)
      _ProductLineCard(group: group, formatter: formatter, invoiced: true),
    if (transaction.fees.isNotEmpty) ...[
      DetailSectionLabel(label: LocaleKeys.sales_detailFees.tr()),
      for (final fee in transaction.fees)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: DetailKeyValue(
            label: '${fee.name} · ${receiveFeeDirectionLabel(fee.direction)}',
            value:
                '${fee.direction.isDiscount ? '−' : '+'}'
                '${formatter.format(fee.computedAmount)}',
          ),
        ),
    ],
    TransactionMoneyPanel(transaction: transaction, formatter: formatter),
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: DetailNotice(message: LocaleKeys.sales_detailReceiveNotice.tr()),
    ),
  ];

  List<Widget> _buildWriteOffBody(
    BuildContext context,
    Transaction transaction,
    StoreCurrencyFormatter formatter,
  ) => [
    DetailSectionLabel(label: LocaleKeys.sales_detailWhatLeftStock.tr()),
    for (final line in transaction.lines)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: DetailLotCard(
          title: line.batchCode,
          rows: [
            DetailKeyValue(
              label: LocaleKeys.sales_detailProduct.tr(),
              value: line.productName,
            ),
            DetailKeyValue(
              label: LocaleKeys.sales_detailUnitCost.tr(),
              value: formatter.format(line.unitCostSnapshot),
            ),
            DetailKeyValue(
              label: LocaleKeys.sales_detailWrittenOff.tr(),
              value: formatQuantity(line.displayQuantity),
              hint: line.quantityBefore == null
                  ? null
                  : LocaleKeys.sales_detailOfHeld.tr(
                      namedArgs: {'held': formatQuantity(line.quantityBefore!)},
                    ),
            ),
            DetailKeyValue(
              label: LocaleKeys.sales_detailValueLost.tr(),
              value: formatter.format(line.lineCost),
              emphasise: true,
            ),
          ],
        ),
      ),
    if (transaction.reasonNote != null && transaction.reasonNote!.isNotEmpty) ...[
      DetailSectionLabel(label: LocaleKeys.sales_detailNote.tr()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          transaction.reasonNote!,
          style: context.textStyles.sansBody.copyWith(color: context.colors.neutral7),
        ),
      ),
    ],
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: DetailNotice(message: LocaleKeys.sales_detailWriteOffNotice.tr()),
    ),
  ];

  List<Widget> _buildAdjustBody(
    BuildContext context,
    Transaction transaction,
    StoreCurrencyFormatter formatter,
  ) => [
    DetailSectionLabel(label: LocaleKeys.sales_detailLotCounted.tr()),
    for (final line in transaction.lines)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: DetailLotCard(
          title: line.batchCode,
          rows: [
            DetailKeyValue(
              label: LocaleKeys.sales_detailProduct.tr(),
              value: line.productName,
            ),
            if (line.quantityBefore != null)
              DetailKeyValue(
                label: LocaleKeys.sales_detailSystemHeld.tr(),
                value: formatQuantity(line.quantityBefore!),
              )
            else
              DetailKeyValue(
                label: LocaleKeys.sales_detailUnitCost.tr(),
                value: formatter.format(line.unitCostSnapshot),
              ),
            if (line.countedQuantity != null)
              DetailKeyValue(
                label: LocaleKeys.sales_detailCountedOnShelf.tr(),
                value: formatQuantity(line.countedQuantity!),
              ),
            DetailKeyValue(
              label: LocaleKeys.sales_detailAppliedDelta.tr(),
              value: formatQuantity(line.quantityDelta),
              emphasise: true,
              valueColor: line.isOutward
                  ? context.colors.red5
                  : context.colors.green5,
            ),
          ],
        ),
      ),
    if (transaction.reasonNote != null && transaction.reasonNote!.isNotEmpty) ...[
      DetailSectionLabel(label: LocaleKeys.sales_detailReason.tr()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          transaction.reasonNote!,
          style: context.textStyles.sansBody.copyWith(color: context.colors.neutral7),
        ),
      ),
    ],
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: DetailNotice(message: LocaleKeys.sales_detailAdjustNotice.tr()),
    ),
  ];

  Widget _buildReversalRefused(BuildContext context, ReversalBlockedException refusal) {
    return Column(
      key: const Key('reversal-refused'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: DetailNotice(
            tone: NoticeTone.error,
            message: LocaleKeys.sales_reversalTitle.tr(),
          ),
        ),
        if (refusal.batchCode != null) ...[
          DetailSectionLabel(label: LocaleKeys.sales_reversalWhereShort.tr()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DetailLotCard(
              title: refusal.batchCode!,
              rows: [
                if (refusal.shortfall != null)
                  DetailKeyValue(
                    label: LocaleKeys.sales_reversalWouldReturn.tr(),
                    value: formatQuantity(
                      refusal.shortfall! + (refusal.remaining ?? Decimal.zero),
                    ),
                  ),
                if (refusal.remaining != null)
                  DetailKeyValue(
                    label: LocaleKeys.sales_reversalHoldsNow.tr(),
                    value: formatQuantity(refusal.remaining!),
                  ),
                if (refusal.shortfall != null)
                  DetailKeyValue(
                    label: LocaleKeys.sales_reversalShortfall.tr(),
                    value: formatQuantity(refusal.shortfall!),
                    emphasise: true,
                  ),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: DetailNotice(message: LocaleKeys.sales_reversalAllOrNothing.tr()),
        ),
      ],
    );
  }
}

/// One product, with every lot it drew on named underneath it. The ledger keeps
/// a line per lot; this is the shape a reader can trace the cost of goods
/// through.
class _ProductLineCard extends StatelessWidget {
  const _ProductLineCard({
    required this.group,
    required this.formatter,
    this.invoiced = false,
  });

  final List<TransactionLine> group;
  final StoreCurrencyFormatter formatter;
  final bool invoiced;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final first = group.first;
    final quantity = group.fold(
      Decimal.zero,
      (sum, line) => sum + line.displayQuantity,
    );
    final gross = group.fold(Decimal.zero, (sum, line) => sum + line.lineGross);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.neutral0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.neutral2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  first.productName,
                  style: styles.sansBodyBold.copyWith(color: colors.neutral9),
                ),
              ),
              Text(
                formatter.format(gross),
                style: styles.monoBody.copyWith(color: colors.neutral9),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            invoiced
                ? LocaleKeys.sales_detailInvoiced.tr(
                    namedArgs: {
                      'quantity': formatQuantity(quantity),
                      'price': formatter.format(first.unitPrice),
                    },
                  )
                : LocaleKeys.sales_lineMeta.tr(
                    namedArgs: {
                      'quantity': formatQuantity(quantity),
                      'price': formatter.format(first.unitPrice),
                    },
                  ),
            style: styles.sansCaption.copyWith(color: colors.neutral7),
          ),
          const SizedBox(height: 6),
          for (final line in group)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                invoiced
                    ? LocaleKeys.sales_detailLanded.tr(
                        namedArgs: {
                          'cost': formatter.format(line.unitCostSnapshot),
                          'lot': line.batchCode,
                        },
                      )
                    : LocaleKeys.sales_detailFromLot.tr(
                        namedArgs: {
                          'quantity': formatQuantity(line.displayQuantity),
                          'lot': line.batchCode,
                          'cost': formatter.format(line.unitCostSnapshot),
                        },
                      ),
                style: styles.sansCaption.copyWith(color: colors.neutral6),
              ),
            ),
          if (group.any((line) => line.costHasMoved))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                LocaleKeys.sales_detailCostNowReads.tr(
                  namedArgs: {
                    'cost': formatter.format(
                      group.firstWhere((line) => line.costHasMoved).batchUnitCost!,
                    ),
                  },
                ),
                style: styles.sansCaption.copyWith(color: colors.orange6),
              ),
            ),
        ],
      ),
    );
  }
}
