import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';
import 'package:mine_storage/providers.dart';

final transactionEditStateProvider =
    NotifierProvider<TransactionEditStateNotifier, TransactionEditState>(
      TransactionEditStateNotifier.new,
      isAutoDispose: true,
    );

/// One lot an amend would draw on, as either side of the comparison sees it.
class EditLot extends Equatable {
  const EditLot({
    required this.batchId,
    required this.batchCode,
    required this.quantity,
    required this.unitCost,
    required this.lineCost,
  });

  final String? batchId;
  final String batchCode;
  final Decimal quantity;
  final Decimal unitCost;
  final Decimal lineCost;

  @override
  List<Object?> get props => [batchId, batchCode, quantity, unitCost, lineCost];
}

/// One product's quantity as the edit currently stands.
class EditLine extends Equatable {
  const EditLine({
    required this.productId,
    required this.productName,
    required this.originalQuantity,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final Decimal originalQuantity;
  final Decimal unitPrice;

  /// What the field holds. Blank or unparseable leaves the line invalid rather
  /// than silently falling back to the original.
  final String quantity;

  Decimal? get parsed => Decimal.tryParse(quantity.trim());

  bool get isValid => parsed != null && parsed! > Decimal.zero;

  bool get hasChanged => parsed != originalQuantity;

  EditLine copyWith({String? quantity}) => EditLine(
    productId: productId,
    productName: productName,
    originalQuantity: originalQuantity,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
  );

  @override
  List<Object?> get props => [
    productId,
    productName,
    originalQuantity,
    unitPrice,
    quantity,
  ];
}

enum ServerChangeField { paymentMethod, quantity, buyerTotal }

/// One field that moved on the server while an edit was open.
class ServerChange extends Equatable {
  const ServerChange({
    required this.field,
    this.name,
    this.beforeAmount,
    this.afterAmount,
    this.beforeMethod,
    this.afterMethod,
  });

  final ServerChangeField field;
  final String? name;
  final Decimal? beforeAmount;
  final Decimal? afterAmount;
  final PaymentMethod? beforeMethod;
  final PaymentMethod? afterMethod;

  @override
  List<Object?> get props => [
    field,
    name,
    beforeAmount,
    afterAmount,
    beforeMethod,
    afterMethod,
  ];
}

class TransactionEditState extends BaseState with Equatable {
  const TransactionEditState({
    this.transaction,
    this.lines = const [],
    this.previewedLots = const [],
    this.previewedCogs,
    this.isPreviewing = false,
    this.isSaving = false,
    this.didSave = false,
    this.isStale = false,
    this.serverVersion,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final Transaction? transaction;
  final List<EditLine> lines;

  /// What the server said this edit would resolve onto. Empty until [preview]
  /// has run — the comparison is meaningless before then.
  final List<EditLot> previewedLots;
  final Decimal? previewedCogs;

  final bool isPreviewing;
  final bool isSaving;
  final bool didSave;

  /// The transaction moved underneath this edit. Retrying blind would reverse
  /// its stock twice, so the only forward action is to reload and look again.
  final bool isStale;

  /// The row as the server holds it now, fetched only to say what moved. It is
  /// never merged into the edits — the user chooses which version survives.
  final Transaction? serverVersion;

  /// What changed on the server while this edit was open. Rows carry the
  /// figures; the screen supplies the wording.
  List<ServerChange> get serverDiff {
    final mine = transaction;
    final theirs = serverVersion;
    if (mine == null || theirs == null) return const [];

    final rows = <ServerChange>[];
    if (mine.paymentMethod != theirs.paymentMethod) {
      rows.add(
        ServerChange(
          field: ServerChangeField.paymentMethod,
          beforeMethod: mine.paymentMethod,
          afterMethod: theirs.paymentMethod,
        ),
      );
    }
    final mineByProduct = _quantitiesOf(mine);
    final theirsByProduct = _quantitiesOf(theirs);
    final names = {
      for (final line in [...mine.lines, ...theirs.lines])
        line.productId: line.productName,
    };
    for (final entry in theirsByProduct.entries) {
      final before = mineByProduct[entry.key];
      if (before != null && before != entry.value) {
        rows.add(
          ServerChange(
            field: ServerChangeField.quantity,
            name: names[entry.key] ?? entry.key,
            beforeAmount: before,
            afterAmount: entry.value,
          ),
        );
      }
    }
    if (mine.money.buyerTotal != theirs.money.buyerTotal) {
      rows.add(
        ServerChange(
          field: ServerChangeField.buyerTotal,
          beforeAmount: mine.money.buyerTotal,
          afterAmount: theirs.money.buyerTotal,
        ),
      );
    }
    return rows;
  }

  static Map<String, Decimal> _quantitiesOf(Transaction transaction) {
    final totals = <String, Decimal>{};
    for (final line in transaction.lines) {
      totals[line.productId] =
          (totals[line.productId] ?? Decimal.zero) + line.displayQuantity;
    }
    return totals;
  }

  /// The lots the transaction holds now, in the order it drew on them.
  List<EditLot> get originalLots => [
    for (final line in transaction?.lines ?? const <TransactionLine>[])
      EditLot(
        batchId: line.batchId,
        batchCode: line.batchCode,
        quantity: line.displayQuantity,
        unitCost: line.unitCostSnapshot,
        lineCost: line.lineCost,
      ),
  ];

  List<EditLot> get newLots => previewedLots;

  bool get hasPreview => previewedLots.isNotEmpty;

  /// The lots this edit would land on are not the lots it came off. Said before
  /// Save, never in a snack afterwards.
  bool get lotSetChanged {
    if (!hasPreview) return false;
    final was = originalLots.map((lot) => lot.batchCode).toSet();
    final now = previewedLots.map((lot) => lot.batchCode).toSet();
    return was.length != now.length || !was.containsAll(now);
  }

  Decimal get originalCogs => transaction?.money.cogs ?? Decimal.zero;

  Decimal get cogsDelta => (previewedCogs ?? originalCogs) - originalCogs;

  Decimal? quantityFor(String productId) => lines
      .where((line) => line.productId == productId)
      .map((line) => line.parsed)
      .firstOrNull;

  bool get hasChanges => lines.any((line) => line.hasChanged);

  bool get isValid => lines.isNotEmpty && lines.every((line) => line.isValid);

  bool get canSave =>
      hasChanges && isValid && !isSaving && !isPreviewing && !isStale;

  @override
  TransactionEditState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    Transaction? transaction,
    List<EditLine>? lines,
    List<EditLot>? previewedLots,
    Decimal? previewedCogs,
    bool? isPreviewing,
    bool? isSaving,
    bool? didSave,
    bool? isStale,
    Transaction? serverVersion,
    bool clearPreview = false,
  }) {
    return TransactionEditState(
      transaction: transaction ?? this.transaction,
      lines: lines ?? this.lines,
      previewedLots: clearPreview ? const [] : (previewedLots ?? this.previewedLots),
      previewedCogs: clearPreview ? null : (previewedCogs ?? this.previewedCogs),
      isPreviewing: isPreviewing ?? this.isPreviewing,
      isSaving: isSaving ?? this.isSaving,
      didSave: didSave ?? this.didSave,
      isStale: isStale ?? this.isStale,
      serverVersion: serverVersion ?? this.serverVersion,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    transaction,
    lines,
    previewedLots,
    previewedCogs,
    isPreviewing,
    isSaving,
    didSave,
    isStale,
    serverVersion,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class TransactionEditStateNotifier extends BaseStateNotifier<TransactionEditState> {
  late final TransactionRepository _repository;
  String? _id;

  @override
  TransactionEditState createInitialState() {
    _repository = ref.read(transactionRepositoryProvider);
    return const TransactionEditState();
  }

  Future<void> load(String id) async {
    _id = id;
    showLoading();
    await _fetch();
  }

  /// Replaces the edits with the server's version. Nothing is merged: a merge
  /// would silently keep half of someone else's work and half of this one's.
  Future<void> reload() => _fetch();

  /// Read only so the conflict can be shown as a diff rather than a failure.
  Future<void> _readServerVersion() async {
    final id = _id;
    if (id == null) return;
    try {
      final current = await _repository.byId(id);
      if (!ref.mounted) return;
      updateState(state.copyWith(serverVersion: current));
    } on Object {
      // The diff is a courtesy. Failing to fetch it must not turn a refused
      // write into a second error on top of the one already shown.
    }
  }

  Future<void> _fetch() async {
    final id = _id;
    if (id == null) return;
    try {
      final transaction = await _repository.byId(id);
      if (!ref.mounted) return;
      updateState(
        TransactionEditState(
          status: StateLifeCycle.loaded,
          transaction: transaction,
          lines: _linesOf(transaction),
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  /// The ledger stores one line per lot; the edit screen shows one quantity per
  /// product, because that is the number a shopkeeper knows they got wrong.
  static List<EditLine> _linesOf(Transaction transaction) {
    final grouped = <String, List<TransactionLine>>{};
    for (final line in transaction.lines) {
      grouped.putIfAbsent(line.productId, () => []).add(line);
    }
    return [
      for (final entry in grouped.entries)
        EditLine(
          productId: entry.key,
          productName: entry.value.first.productName,
          originalQuantity: entry.value.fold(
            Decimal.zero,
            (sum, line) => sum + line.displayQuantity,
          ),
          unitPrice: entry.value.first.unitPrice,
          quantity: entry.value
              .fold(Decimal.zero, (sum, line) => sum + line.displayQuantity)
              .toString(),
        ),
    ];
  }

  void setQuantity(String productId, String value) {
    updateState(
      state.copyWith(
        lines: [
          for (final line in state.lines)
            line.productId == productId ? line.copyWith(quantity: value) : line,
        ],
        // Any change invalidates the comparison already on screen — showing a
        // stale one would name lots this edit no longer asks for.
        clearPreview: true,
      ),
    );
  }

  TransactionDraft? _draft() {
    final transaction = state.transaction;
    if (transaction == null || !state.isValid) return null;
    return TransactionDraft(
      storeId: transaction.storeId,
      type: transaction.type,
      occurredAt: transaction.occurredAt,
      paymentMethod: transaction.paymentMethod,
      counterparty: transaction.counterparty,
      counterpartyPhone: transaction.counterpartyPhone,
      note: transaction.note,
      reason: transaction.reason,
      reasonNote: transaction.reasonNote,
      fees: [for (final fee in transaction.fees) fee.asFee],
      lines: [
        for (final line in state.lines)
          TransactionLineDraft(
            productId: line.productId,
            quantity: line.parsed!,
            unitPrice: line.unitPrice,
          ),
      ],
    );
  }

  /// Resolves the edit against stock as it stands now, without writing. An
  /// amend rarely lands on the lots the original drew from, and that difference
  /// belongs on screen before Save rather than in a snack after it.
  Future<void> preview() async {
    final draft = _draft();
    if (draft == null || state.isPreviewing) return;

    updateState(state.copyWith(isPreviewing: true));
    try {
      final resolved = await _repository.preview(draft);
      if (!ref.mounted) return;
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          isPreviewing: false,
          previewedLots: [
            for (final line in resolved.lines)
              EditLot(
                batchId: line.batchId,
                batchCode: line.batchCode ?? '',
                quantity: line.displayQuantity,
                unitCost: line.unitCostSnapshot,
                lineCost: line.lineCost,
              ),
          ],
          previewedCogs: resolved.money.cogs,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      updateState(state.copyWith(isPreviewing: false));
      onError(e);
    }
  }

  Future<void> commit() async {
    final transaction = state.transaction;
    final readAt = transaction?.updatedTime;
    final draft = _draft();
    if (transaction == null || readAt == null || draft == null || state.isSaving) {
      return;
    }

    updateState(state.copyWith(isSaving: true));
    try {
      await _repository.amend(transaction.id, draft, expectedUpdatedAt: readAt);
      if (!ref.mounted) return;
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          isSaving: false,
          didSave: true,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      final exception = resolveException(e);
      if (exception is StaleTransactionException) {
        updateState(state.copyWith(isSaving: false, isStale: true));
        await _readServerVersion();
        return;
      }
      updateState(state.copyWith(isSaving: false));
      onError(e);
    }
  }
}
