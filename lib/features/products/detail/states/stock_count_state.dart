import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

final stockCountStateProvider =
    NotifierProvider<StockCountStateNotifier, StockCountState>(
      StockCountStateNotifier.new,
      isAutoDispose: true,
    );

/// Setting one lot to what is actually on the shelf.
///
/// A count moves quantity and nothing else: the lot keeps the cost it was
/// received at, so not one money figure appears here or on the transaction it
/// writes.
class StockCountState extends BaseState with Equatable {
  const StockCountState({
    this.product,
    this.batch,
    this.counted = '',
    this.reason = '',
    this.fractionRefused = false,
    this.didCommit = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final ProductEntity? product;
  final ProductBatchEntity? batch;

  /// What was found on the shelf. The server turns it into a signed delta —
  /// sending the delta from here would race anything that moved in between.
  final String counted;

  /// Required: it is the only record of why the number moved.
  final String reason;

  final bool fractionRefused;
  final bool didCommit;

  List<ProductBatchEntity> get lots => product?.availableBatches ?? const [];

  Decimal get remaining => batch?.remainingQuantity ?? Decimal.zero;

  Decimal? get parsedCounted => Decimal.tryParse(counted.trim());

  /// Counted less what the lot claims to hold. Signed, and updated live.
  Decimal get difference => (parsedCounted ?? remaining) - remaining;

  bool get isUnchanged => parsedCounted != null && difference == Decimal.zero;

  bool get canCommit {
    final parsed = parsedCounted;
    return batch != null &&
        parsed != null &&
        parsed >= Decimal.zero &&
        !fractionRefused &&
        !isUnchanged &&
        reason.trim().isNotEmpty &&
        !isLoading;
  }

  @override
  StockCountState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    ProductEntity? product,
    ProductBatchEntity? batch,
    String? counted,
    String? reason,
    bool? fractionRefused,
    bool? didCommit,
  }) {
    return StockCountState(
      product: product ?? this.product,
      batch: batch ?? this.batch,
      counted: counted ?? this.counted,
      reason: reason ?? this.reason,
      fractionRefused: fractionRefused ?? this.fractionRefused,
      didCommit: didCommit ?? this.didCommit,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    product,
    batch,
    counted,
    reason,
    fractionRefused,
    didCommit,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class StockCountStateNotifier extends BaseStateNotifier<StockCountState> {
  late final TransactionRepository _ledger;
  String? _storeId;

  @override
  StockCountState createInitialState() {
    _ledger = ref.read(transactionRepositoryProvider);
    _storeId = ref.read(activeStoreProvider);
    return const StockCountState();
  }

  void open(ProductEntity product, {ProductBatchEntity? batch}) {
    final lots = product.availableBatches;
    updateState(
      StockCountState(
        product: product,
        batch: batch ?? (lots.isEmpty ? null : lots.first),
      ),
    );
  }

  void selectBatch(ProductBatchEntity batch) =>
      updateState(state.copyWith(batch: batch));

  void updateReason(String reason) => updateState(state.copyWith(reason: reason));

  void updateCounted(String value) {
    final product = state.product;
    if (product == null) return;

    final parsed = Decimal.tryParse(value.trim());
    updateState(
      state.copyWith(
        counted: value,
        status: StateLifeCycle.init,
        fractionRefused: parsed != null && !product.unit.acceptsQuantity(parsed),
      ),
    );
  }

  Future<void> commit() async {
    final product = state.product;
    final batch = state.batch;
    final storeId = _storeId;
    if (product == null || batch == null || storeId == null || !state.canCommit) {
      return;
    }

    try {
      showLoading();
      await _ledger.create(
        TransactionDraft(
          storeId: storeId,
          type: TransactionType.adjust,
          reasonNote: state.reason.trim(),
          lines: [
            TransactionLineDraft(
              productId: product.id,
              batchId: batch.id,
              quantity: state.parsedCounted!,
            ),
          ],
        ),
      );
      if (!ref.mounted) return;
      updateState(state.copyWith(status: StateLifeCycle.loaded, didCommit: true));
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }
}
