import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

final receiveStateProvider = NotifierProvider<ReceiveStateNotifier, ReceiveState>(
  ReceiveStateNotifier.new,
  isAutoDispose: true,
);

/// A delivery in: the only movement that both creates a lot and moves money in
/// two directions, which is why it is the only one with a supplier, a payment
/// method and a fee editor.
class ReceiveState extends BaseState with Equatable {
  const ReceiveState({
    this.product,
    this.quantity = '',
    this.unitCost = '',
    this.expiryDate,
    this.batchCode = '',
    this.supplier = '',
    this.storageLocation = '',
    this.paymentMethod = PaymentMethod.cash,
    this.fees = const [],
    this.fractionRefused = false,
    this.didCommit = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final ProductEntity? product;
  final String quantity;
  final String unitCost;
  final DateTime? expiryDate;
  final String batchCode;
  final String supplier;
  final String storageLocation;
  final PaymentMethod paymentMethod;

  /// A receive has no seller side, so the editor is limited to what folds into
  /// the lot's cost and what comes off the invoice.
  final List<Fee> fees;

  final bool fractionRefused;
  final bool didCommit;

  Decimal? get parsedQuantity => Decimal.tryParse(quantity.trim());

  Decimal? get parsedUnitCost => Decimal.tryParse(unitCost.trim());

  /// What the goods cost before any fee is folded in. The landed figure is the
  /// server's to compute — it is what every later sale is costed at.
  Decimal get goodsTotal =>
      (parsedQuantity ?? Decimal.zero) * (parsedUnitCost ?? Decimal.zero);

  bool get canCommit {
    final quantity = parsedQuantity;
    final cost = parsedUnitCost;
    return product != null &&
        quantity != null &&
        quantity > Decimal.zero &&
        cost != null &&
        cost >= Decimal.zero &&
        !fractionRefused &&
        !isLoading;
  }

  @override
  ReceiveState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    ProductEntity? product,
    String? quantity,
    String? unitCost,
    DateTime? expiryDate,
    bool clearExpiry = false,
    String? batchCode,
    String? supplier,
    String? storageLocation,
    PaymentMethod? paymentMethod,
    List<Fee>? fees,
    bool? fractionRefused,
    bool? didCommit,
  }) {
    return ReceiveState(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      batchCode: batchCode ?? this.batchCode,
      supplier: supplier ?? this.supplier,
      storageLocation: storageLocation ?? this.storageLocation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fees: fees ?? this.fees,
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
    quantity,
    unitCost,
    expiryDate,
    batchCode,
    supplier,
    storageLocation,
    paymentMethod,
    fees,
    fractionRefused,
    didCommit,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class ReceiveStateNotifier extends BaseStateNotifier<ReceiveState> {
  late final TransactionRepository _ledger;
  String? _storeId;

  @override
  ReceiveState createInitialState() {
    _ledger = ref.read(transactionRepositoryProvider);
    _storeId = ref.read(activeStoreProvider);
    return const ReceiveState();
  }

  void open(ProductEntity product) => updateState(ReceiveState(product: product));

  void updateQuantity(String value) {
    final product = state.product;
    final parsed = Decimal.tryParse(value.trim());
    updateState(
      state.copyWith(
        quantity: value,
        status: StateLifeCycle.init,
        fractionRefused:
            product != null && parsed != null && !product.unit.acceptsQuantity(parsed),
      ),
    );
  }

  void updateUnitCost(String value) =>
      updateState(state.copyWith(unitCost: value, status: StateLifeCycle.init));

  void updateExpiry(DateTime? date) => updateState(
    date == null
        ? state.copyWith(clearExpiry: true)
        : state.copyWith(expiryDate: date),
  );

  void updateBatchCode(String value) => updateState(state.copyWith(batchCode: value));

  void updateSupplier(String value) => updateState(state.copyWith(supplier: value));

  void updateStorageLocation(String value) =>
      updateState(state.copyWith(storageLocation: value));

  void selectPaymentMethod(PaymentMethod method) =>
      updateState(state.copyWith(paymentMethod: method));

  void updateFees(List<Fee> fees) => updateState(state.copyWith(fees: fees));

  /// Writes a `receive` transaction that opens the lot. There is no other way
  /// into a lot's quantity — a delivery is a movement like any other.
  Future<void> commit() async {
    final product = state.product;
    final storeId = _storeId;
    if (product == null || storeId == null || !state.canCommit) return;

    try {
      showLoading();
      await _ledger.create(
        TransactionDraft(
          storeId: storeId,
          type: TransactionType.receive,
          paymentMethod: state.paymentMethod,
          counterparty: state.supplier.trim().isEmpty ? null : state.supplier.trim(),
          fees: state.fees,
          lines: [
            TransactionLineDraft(
              productId: product.id,
              quantity: state.parsedQuantity!,
              unitPrice: state.parsedUnitCost!,
              batch: TransactionBatchDraft(
                batchCode: state.batchCode.trim().isEmpty
                    ? null
                    : state.batchCode.trim(),
                expiryDate: state.expiryDate,
                supplier: state.supplier.trim().isEmpty ? null : state.supplier.trim(),
                storageLocation: state.storageLocation.trim().isEmpty
                    ? null
                    : state.storageLocation.trim(),
              ),
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
