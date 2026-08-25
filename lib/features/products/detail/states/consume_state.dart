import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/domain/services/fefo_allocator.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

final consumeStateProvider = NotifierProvider<ConsumeStateNotifier, ConsumeState>(
  ConsumeStateNotifier.new,
  isAutoDispose: true,
);

class ConsumeState extends BaseState with Equatable {
  const ConsumeState({
    this.product,
    this.quantity = '',
    this.allocations = const [],
    this.exceedsStock = false,
    this.fractionRefused = false,
    this.drawsFromExpired = false,
    this.didCommit = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final ProductEntity? product;
  final String quantity;

  /// Resolved before anything is sent, so the split is visible up front and the
  /// server is never asked for something that cannot be satisfied.
  final List<BatchAllocation> allocations;

  /// More than the store holds. A refusal, not a warning.
  final bool exceedsStock;

  /// A fraction against a count unit. Refused at input, never at save.
  final bool fractionRefused;

  /// The allocation draws from a lot that has already expired. A warning the
  /// user may proceed past — FEFO does not change because stock went off.
  final bool drawsFromExpired;

  final bool didCommit;

  Decimal get totalRemaining => product?.totalRemaining ?? Decimal.zero;

  Decimal? get parsedQuantity => Decimal.tryParse(quantity.trim());

  bool get canCommit {
    final parsed = parsedQuantity;
    return parsed != null &&
        parsed > Decimal.zero &&
        !exceedsStock &&
        !fractionRefused &&
        !isLoading &&
        allocations.isNotEmpty;
  }

  @override
  ConsumeState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    ProductEntity? product,
    String? quantity,
    List<BatchAllocation>? allocations,
    bool? exceedsStock,
    bool? fractionRefused,
    bool? drawsFromExpired,
    bool? didCommit,
  }) {
    return ConsumeState(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      allocations: allocations ?? this.allocations,
      exceedsStock: exceedsStock ?? this.exceedsStock,
      fractionRefused: fractionRefused ?? this.fractionRefused,
      drawsFromExpired: drawsFromExpired ?? this.drawsFromExpired,
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
    allocations,
    exceedsStock,
    fractionRefused,
    drawsFromExpired,
    didCommit,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class ConsumeStateNotifier extends BaseStateNotifier<ConsumeState> {
  late final ProductRepository _repository;
  String? _storeId;
  DateTime _now = DateTime.now();

  @override
  ConsumeState createInitialState() {
    _repository = ref.read(productRepositoryProvider);
    _storeId = ref.read(activeStoreProvider);
    return const ConsumeState();
  }

  void open(ProductEntity product, {DateTime? now}) {
    _now = now ?? DateTime.now();
    updateState(ConsumeState(product: product));
  }

  void updateQuantity(String value) {
    final product = state.product;
    if (product == null) return;

    final parsed = Decimal.tryParse(value.trim());
    if (parsed == null || parsed <= Decimal.zero) {
      updateState(
        state.copyWith(
          quantity: value,
          allocations: const [],
          exceedsStock: false,
          fractionRefused: false,
          drawsFromExpired: false,
          status: StateLifeCycle.init,
        ),
      );
      return;
    }

    if (!product.unit.acceptsQuantity(parsed)) {
      updateState(
        state.copyWith(
          quantity: value,
          allocations: const [],
          fractionRefused: true,
          exceedsStock: false,
          drawsFromExpired: false,
          status: StateLifeCycle.init,
        ),
      );
      return;
    }

    // Resolving here is what makes the refusal client-side: an over-request
    // never becomes a request at all.
    try {
      final allocations = FefoAllocator.allocate(
        quantity: parsed,
        batches: product.batches,
      );
      updateState(
        state.copyWith(
          quantity: value,
          allocations: allocations,
          exceedsStock: false,
          fractionRefused: false,
          drawsFromExpired: _drawsFromExpired(product, allocations),
          status: StateLifeCycle.init,
        ),
      );
    } on InsufficientStockException {
      updateState(
        state.copyWith(
          quantity: value,
          allocations: const [],
          exceedsStock: true,
          fractionRefused: false,
          drawsFromExpired: false,
          status: StateLifeCycle.init,
        ),
      );
    }
  }

  bool _drawsFromExpired(ProductEntity product, List<BatchAllocation> allocations) {
    final drawn = allocations.map((allocation) => allocation.batchId).toSet();
    return product.batches
        .where((batch) => drawn.contains(batch.id))
        .any((batch) => batch.isExpiredAt(_now));
  }

  Future<void> commit() async {
    final product = state.product;
    final storeId = _storeId;
    if (product == null || storeId == null || !state.canCommit) return;

    try {
      showLoading();
      final updated = await _repository.consume(
        product.id,
        state.allocations,
        storeId: storeId,
      );
      if (!ref.mounted) return;
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          product: updated,
          didCommit: true,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }
}
