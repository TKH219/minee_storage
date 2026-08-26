import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/sale_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

final allocationStateProvider =
    NotifierProvider<AllocationStateNotifier, AllocationState>(
      AllocationStateNotifier.new,
      isAutoDispose: true,
    );

class AllocationState extends BaseState with Equatable {
  const AllocationState({
    this.product,
    this.quantity = '1',
    this.sellPrice = '',
    this.allocations = const [],
    this.exceedsStock = false,
    this.fractionRefused = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final ProductEntity? product;
  final String quantity;
  final String sellPrice;

  /// Resolved through the repository, so the split shown is the split the
  /// confirm will draw from.
  final List<SaleAllocation> allocations;

  final bool exceedsStock;
  final bool fractionRefused;

  Decimal get totalRemaining => product?.totalRemaining ?? Decimal.zero;

  Decimal? get parsedQuantity => Decimal.tryParse(quantity.trim());

  Decimal? get parsedSellPrice => Decimal.tryParse(sellPrice.trim());

  Decimal get lineTotal {
    final quantity = parsedQuantity;
    final price = parsedSellPrice;
    if (quantity == null || price == null) return Decimal.zero;
    return quantity * price;
  }

  bool get isSplit => allocations.length > 1;

  bool get canAdd {
    final quantity = parsedQuantity;
    final price = parsedSellPrice;
    return quantity != null &&
        quantity > Decimal.zero &&
        price != null &&
        price > Decimal.zero &&
        !exceedsStock &&
        !fractionRefused &&
        allocations.isNotEmpty;
  }

  SaleDraftLine? toLine() {
    final product = this.product;
    if (product == null || !canAdd) return null;
    return SaleDraftLine(
      productId: product.id,
      productName: product.name,
      unit: product.unit,
      quantity: parsedQuantity!,
      unitSellPrice: parsedSellPrice!,
      allocations: allocations,
    );
  }

  @override
  AllocationState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    ProductEntity? product,
    String? quantity,
    String? sellPrice,
    List<SaleAllocation>? allocations,
    bool? exceedsStock,
    bool? fractionRefused,
  }) {
    return AllocationState(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      sellPrice: sellPrice ?? this.sellPrice,
      allocations: allocations ?? this.allocations,
      exceedsStock: exceedsStock ?? this.exceedsStock,
      fractionRefused: fractionRefused ?? this.fractionRefused,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    product,
    quantity,
    sellPrice,
    allocations,
    exceedsStock,
    fractionRefused,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class AllocationStateNotifier extends BaseStateNotifier<AllocationState> {
  late final SaleRepository _sales;

  @override
  AllocationState createInitialState() {
    _sales = ref.read(saleRepositoryProvider);
    return const AllocationState();
  }

  /// [quantity] and [sellPrice] are supplied when reopening an existing basket
  /// line, so the sheet returns to exactly what it produced last time.
  Future<void> open(
    ProductEntity product, {
    Decimal? quantity,
    Decimal? sellPrice,
  }) async {
    // Selling price is never derived from cost (§5.2.5) — the latest purchase
    // price is a starting point the seller can overwrite, not a markup rule.
    final price = sellPrice ?? product.latestUnitPrice;
    updateState(
      AllocationState(
        product: product,
        quantity: (quantity ?? Decimal.one).toString(),
        sellPrice: price?.toString() ?? '',
      ),
    );
    await _resolve(state.quantity);
  }

  Future<void> setQuantity(String value) => _resolve(value);

  Future<void> increment() => _stepBy(Decimal.one);

  Future<void> decrement() => _stepBy(-Decimal.one);

  Future<void> _stepBy(Decimal step) {
    final current = state.parsedQuantity ?? Decimal.one;
    final next = current + step;
    if (next < Decimal.one) return _resolve(state.quantity);
    return _resolve(next.toString());
  }

  void setSellPrice(String value) => updateState(state.copyWith(sellPrice: value));

  Future<void> _resolve(String value) async {
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
          exceedsStock: false,
          fractionRefused: true,
          status: StateLifeCycle.init,
        ),
      );
      return;
    }

    final storeId = ref.read(activeStoreProvider);
    if (storeId == null) {
      updateState(
        state.copyWith(
          status: StateLifeCycle.error,
          errorMessageKey: LocaleKeys.products_noActiveStore,
        ),
      );
      return;
    }

    try {
      final allocations = await _sales.previewAllocation(
        productId: product.id,
        storeId: storeId,
        quantity: parsed,
      );
      if (!ref.mounted) return;
      updateState(
        state.copyWith(
          quantity: value,
          allocations: allocations,
          exceedsStock: false,
          fractionRefused: false,
          status: StateLifeCycle.loaded,
        ),
      );
    } on InsufficientStockException {
      if (!ref.mounted) return;
      // Refused here rather than at confirm: an over-request never becomes a
      // request at all.
      updateState(
        state.copyWith(
          quantity: value,
          allocations: const [],
          exceedsStock: true,
          fractionRefused: false,
          status: StateLifeCycle.init,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }
}
