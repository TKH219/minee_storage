import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

final writeOffStateProvider =
    NotifierProvider<WriteOffStateNotifier, WriteOffState>(
      WriteOffStateNotifier.new,
      isAutoDispose: true,
    );

/// Taking stock out for a reason that is not a sale.
///
/// A write-off is per lot: which goods spoiled is a fact about one delivery,
/// not about the product, and the loss is valued at that lot's own cost.
class WriteOffState extends BaseState with Equatable {
  const WriteOffState({
    this.product,
    this.batch,
    this.reason = WriteOffReason.expired,
    this.quantity = '',
    this.note = '',
    this.exceedsLot = false,
    this.fractionRefused = false,
    this.didCommit = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final ProductEntity? product;
  final ProductBatchEntity? batch;
  final WriteOffReason reason;
  final String quantity;
  final String note;

  /// More than the lot holds. A refusal, not a warning — nothing here may push
  /// a lot below zero.
  final bool exceedsLot;

  /// A fraction against a counted unit. Refused at input, never at save.
  final bool fractionRefused;

  final bool didCommit;

  List<ProductBatchEntity> get lots => product?.availableBatches ?? const [];

  Decimal get remaining => batch?.remainingQuantity ?? Decimal.zero;

  Decimal? get parsedQuantity => Decimal.tryParse(quantity.trim());

  Decimal get valueLeaving =>
      (parsedQuantity ?? Decimal.zero) * (batch?.unitPrice ?? Decimal.zero);

  bool get canCommit {
    final parsed = parsedQuantity;
    return batch != null &&
        parsed != null &&
        parsed > Decimal.zero &&
        !exceedsLot &&
        !fractionRefused &&
        !isLoading;
  }

  @override
  WriteOffState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    ProductEntity? product,
    ProductBatchEntity? batch,
    WriteOffReason? reason,
    String? quantity,
    String? note,
    bool? exceedsLot,
    bool? fractionRefused,
    bool? didCommit,
  }) {
    return WriteOffState(
      product: product ?? this.product,
      batch: batch ?? this.batch,
      reason: reason ?? this.reason,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      exceedsLot: exceedsLot ?? this.exceedsLot,
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
    reason,
    quantity,
    note,
    exceedsLot,
    fractionRefused,
    didCommit,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class WriteOffStateNotifier extends BaseStateNotifier<WriteOffState> {
  late final TransactionRepository _ledger;
  String? _storeId;

  @override
  WriteOffState createInitialState() {
    _ledger = ref.read(transactionRepositoryProvider);
    _storeId = ref.read(activeStoreProvider);
    return const WriteOffState();
  }

  /// Opens on [batch], or on the lot that would go out first — spoiled stock is
  /// almost always the oldest, so that is the answer worth defaulting to.
  void open(ProductEntity product, {ProductBatchEntity? batch}) {
    final lots = product.availableBatches;
    updateState(
      WriteOffState(
        product: product,
        batch: batch ?? (lots.isEmpty ? null : lots.first),
      ),
    );
  }

  void selectBatch(ProductBatchEntity batch) {
    updateState(state.copyWith(batch: batch));
    updateQuantity(state.quantity);
  }

  void selectReason(WriteOffReason reason) =>
      updateState(state.copyWith(reason: reason));

  void updateNote(String note) => updateState(state.copyWith(note: note));

  void updateQuantity(String value) {
    final product = state.product;
    final batch = state.batch;
    if (product == null || batch == null) return;

    final parsed = Decimal.tryParse(value.trim());
    updateState(
      state.copyWith(
        quantity: value,
        status: StateLifeCycle.init,
        fractionRefused: parsed != null && !product.unit.acceptsQuantity(parsed),
        exceedsLot: parsed != null && parsed > batch.remainingQuantity,
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
          type: TransactionType.writeOff,
          reason: state.reason,
          reasonNote: state.note.trim().isEmpty ? null : state.note.trim(),
          lines: [
            TransactionLineDraft(
              productId: product.id,
              batchId: batch.id,
              quantity: state.parsedQuantity!,
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

  /// A movement belongs to a store, so there is nothing truthful to write
  /// without one.
  bool get hasStore => _storeId != null;

  String get noStoreKey => LocaleKeys.products_noActiveStore;
}
