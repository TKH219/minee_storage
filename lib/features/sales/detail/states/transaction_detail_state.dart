import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';
import 'package:mine_storage/providers.dart';

final transactionDetailStateProvider =
    NotifierProvider<TransactionDetailStateNotifier, TransactionDetailState>(
      TransactionDetailStateNotifier.new,
      isAutoDispose: true,
    );

/// One quantity going back to the lot it came out of. The delete dialog names
/// every one of these, because "stock will be restored" is true and useless.
class StockReturn extends Equatable {
  const StockReturn({
    required this.batchId,
    required this.batchCode,
    required this.productName,
    required this.quantity,
  });

  final String batchId;
  final String batchCode;
  final String productName;

  /// Always positive: it is what the lot receives, whichever way the original
  /// line pointed.
  final Decimal quantity;

  @override
  List<Object?> get props => [batchId, batchCode, productName, quantity];
}

class TransactionDetailState extends BaseState with Equatable {
  const TransactionDetailState({
    this.transaction,
    this.didDelete = false,
    this.reversalBlocked,
    this.isDeleting = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final Transaction? transaction;
  final bool didDelete;
  final bool isDeleting;

  /// The reversal the ledger refused. Nothing moved, so the transaction stays
  /// on screen exactly as it was.
  final ReversalBlockedException? reversalBlocked;

  bool get showsMoney => transaction?.type.carriesMoney ?? false;

  bool get showsProfit => transaction?.type.carriesProfit ?? false;

  int get lotCount => transaction?.lotCount ?? 0;

  /// A write-off's one money figure: what the stock that left was worth.
  Decimal get valueLeavingStock => (transaction?.lines ?? const <TransactionLine>[])
      .fold(Decimal.zero, (sum, line) => sum + line.lineCost);

  /// Lines whose lot has been re-costed since they froze their own. Both
  /// figures are shown side by side — the frozen one is the record.
  List<TransactionLine> get movedCostLines =>
      transaction?.lines.where((line) => line.costHasMoved).toList() ?? const [];

  List<StockReturn> get stockReturns => [
    for (final line in transaction?.lines ?? const <TransactionLine>[])
      StockReturn(
        batchId: line.batchId,
        batchCode: line.batchCode,
        productName: line.productName,
        quantity: line.displayQuantity,
      ),
  ];

  /// A sale shows one row per product with its lots beneath, while the ledger
  /// stores one line per lot.
  List<List<TransactionLine>> get linesByProduct {
    final grouped = <String, List<TransactionLine>>{};
    for (final line in transaction?.lines ?? const <TransactionLine>[]) {
      grouped.putIfAbsent(line.productId, () => []).add(line);
    }
    return grouped.values.toList();
  }

  @override
  TransactionDetailState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    Transaction? transaction,
    bool? didDelete,
    bool? isDeleting,
    ReversalBlockedException? reversalBlocked,
    bool clearReversalBlocked = false,
  }) {
    return TransactionDetailState(
      transaction: transaction ?? this.transaction,
      didDelete: didDelete ?? this.didDelete,
      isDeleting: isDeleting ?? this.isDeleting,
      reversalBlocked:
          clearReversalBlocked ? null : (reversalBlocked ?? this.reversalBlocked),
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    transaction,
    didDelete,
    isDeleting,
    reversalBlocked?.batchCode,
    reversalBlocked?.shortfall,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class TransactionDetailStateNotifier
    extends BaseStateNotifier<TransactionDetailState> {
  late final TransactionRepository _repository;
  String? _id;

  @override
  TransactionDetailState createInitialState() {
    _repository = ref.read(transactionRepositoryProvider);
    return const TransactionDetailState();
  }

  Future<void> load(String id) async {
    _id = id;
    showLoading();
    await _fetch();
  }

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    final id = _id;
    if (id == null) return;
    try {
      final transaction = await _repository.byId(id);
      if (!ref.mounted) return;
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          transaction: transaction,
          clearReversalBlocked: true,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  /// Removes the transaction and returns every quantity to the lot it came
  /// from. Refused whole when one of those lots can no longer take it back.
  Future<void> delete() async {
    final transaction = state.transaction;
    final readAt = transaction?.updatedTime;
    if (transaction == null || readAt == null || state.isDeleting) return;

    updateState(state.copyWith(isDeleting: true, clearReversalBlocked: true));
    try {
      await _repository.remove(transaction.id, expectedUpdatedAt: readAt);
      if (!ref.mounted) return;
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          isDeleting: false,
          didDelete: true,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      final exception = resolveException(e);
      // The refusal is not an error state: nothing moved, so the transaction
      // stands as recorded and stays on screen underneath the explanation.
      updateState(
        state.copyWith(
          isDeleting: false,
          reversalBlocked:
              exception is ReversalBlockedException ? exception : null,
          errorMessageKey: exception.messageKey,
          errorMessage: exception.message,
          status: exception is ReversalBlockedException
              ? StateLifeCycle.loaded
              : StateLifeCycle.error,
        ),
      );
    }
  }
}
