import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

final lotFormStateProvider = NotifierProvider<LotFormStateNotifier, LotFormState>(
  LotFormStateNotifier.new,
  isAutoDispose: true,
);

class LotFormState extends BaseState with Equatable {
  const LotFormState({
    this.product,
    this.batchId,
    this.storeId,
    this.quantity = '',
    this.remaining = '',
    this.unitPrice = '',
    this.purchasedAt,
    this.expiryDate,
    this.storageLocation = '',
    this.supplier = '',
    this.note = '',
    this.didSave = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final ProductEntity? product;

  /// Null while receiving new stock; set when editing an existing lot.
  final String? batchId;

  /// Which shop the delivery landed at. Defaults to the active store; a
  /// deviation from the design, which draws no store control at all.
  final String? storeId;

  final String quantity;
  final String remaining;
  final String unitPrice;
  final DateTime? purchasedAt;
  final DateTime? expiryDate;

  /// Where this delivery physically sits — moved here from the product form,
  /// since the same goods stocked in three shops sit in three places.
  final String storageLocation;
  final String supplier;
  final String note;
  final bool didSave;

  Decimal? get _quantity => Decimal.tryParse(quantity.trim());
  Decimal? get _remaining => Decimal.tryParse(remaining.trim());
  Decimal? get _price => Decimal.tryParse(unitPrice.trim());

  bool get quantityIsInvalid {
    if (quantity.trim().isEmpty) return false;
    final value = _quantity;
    if (value == null || value <= Decimal.zero) return true;
    final unit = product?.unit;
    return unit != null && !unit.acceptsQuantity(value);
  }

  bool get remainingIsInvalid {
    final entered = _remaining;
    final bought = _quantity;
    if (entered == null || bought == null) return false;
    return entered > bought || entered < Decimal.zero;
  }

  bool get priceIsInvalid {
    if (unitPrice.trim().isEmpty) return false;
    final value = _price;
    return value == null || value < Decimal.zero;
  }

  bool get expiryIsInvalid {
    final expiry = expiryDate;
    final purchased = purchasedAt;
    if (expiry == null || purchased == null) return false;
    return !expiry.isAfter(purchased);
  }

  /// Displayed live and never stored — it is quantity × price, computed.
  Decimal? get lotTotal {
    final quantity = _quantity;
    final price = _price;
    if (quantity == null || price == null) return null;
    return quantity * price;
  }

  bool get canSubmit =>
      _quantity != null &&
      _price != null &&
      !quantityIsInvalid &&
      !remainingIsInvalid &&
      !priceIsInvalid &&
      !expiryIsInvalid &&
      storeId != null &&
      !isLoading;

  @override
  LotFormState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    ProductEntity? product,
    String? batchId,
    String? storeId,
    String? quantity,
    String? remaining,
    String? unitPrice,
    DateTime? purchasedAt,
    DateTime? expiryDate,
    String? storageLocation,
    String? supplier,
    String? note,
    bool? didSave,
    bool clearExpiryDate = false,
  }) {
    return LotFormState(
      product: product ?? this.product,
      batchId: batchId ?? this.batchId,
      storeId: storeId ?? this.storeId,
      quantity: quantity ?? this.quantity,
      remaining: remaining ?? this.remaining,
      unitPrice: unitPrice ?? this.unitPrice,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      storageLocation: storageLocation ?? this.storageLocation,
      supplier: supplier ?? this.supplier,
      note: note ?? this.note,
      didSave: didSave ?? this.didSave,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    product,
    batchId,
    storeId,
    quantity,
    remaining,
    unitPrice,
    purchasedAt,
    expiryDate,
    storageLocation,
    supplier,
    note,
    didSave,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class LotFormStateNotifier extends BaseStateNotifier<LotFormState> {
  late final ProductRepository _repository;
  String? _activeStore;

  @override
  LotFormState createInitialState() {
    _repository = ref.read(productRepositoryProvider);
    _activeStore = ref.read(activeStoreProvider);
    return const LotFormState();
  }

  void open(ProductEntity product, {ProductBatchEntity? batch, DateTime? today}) {
    updateState(
      LotFormState(
        product: product,
        batchId: batch?.id,
        storeId: batch?.storeId ?? _activeStore,
        quantity: batch?.initialQuantity.toString() ?? '',
        remaining: batch?.remainingQuantity.toString() ?? '',
        unitPrice: batch?.unitPrice.toString() ?? '',
        purchasedAt: batch?.purchasedAt ?? today ?? DateTime.now(),
        expiryDate: batch?.expiryDate,
        storageLocation: batch?.storageLocation ?? '',
        supplier: batch?.supplier ?? '',
        note: batch?.note ?? '',
      ),
    );
  }

  void updateStore(String value) => updateState(state.copyWith(storeId: value));

  void updateQuantity(String value) => updateState(state.copyWith(quantity: value));

  void updateRemaining(String value) => updateState(state.copyWith(remaining: value));

  void updateUnitPrice(String value) => updateState(state.copyWith(unitPrice: value));

  void updatePurchasedAt(DateTime value) =>
      updateState(state.copyWith(purchasedAt: value));

  /// Null clears the date rather than hiding the field — the design greys it.
  void updateExpiryDate(DateTime? value) => updateState(
    value == null
        ? state.copyWith(clearExpiryDate: true)
        : state.copyWith(expiryDate: value),
  );

  void updateStorageLocation(String value) =>
      updateState(state.copyWith(storageLocation: value));

  void updateSupplier(String value) => updateState(state.copyWith(supplier: value));

  void updateNote(String value) => updateState(state.copyWith(note: value));

  Future<void> submit() async {
    final product = state.product;
    if (product == null || !state.canSubmit) return;

    final draft = BatchDraft(
      storeId: state.storeId!,
      purchasedAt: state.purchasedAt ?? DateTime.now(),
      unitPrice: Decimal.parse(state.unitPrice.trim()),
      expiryDate: state.expiryDate,
      initialQuantity: Decimal.parse(state.quantity.trim()),
      remainingQuantity: Decimal.tryParse(state.remaining.trim()),
      supplier: _blankToNull(state.supplier),
      storageLocation: _blankToNull(state.storageLocation),
      note: _blankToNull(state.note),
    );

    try {
      showLoading();
      final batchId = state.batchId;
      final updated = batchId == null
          ? await _repository.addBatch(product.id, draft)
          : await _repository.updateBatch(product.id, batchId, draft);
      if (!ref.mounted) return;
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          product: updated,
          didSave: true,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
