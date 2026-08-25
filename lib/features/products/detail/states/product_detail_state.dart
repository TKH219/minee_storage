import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/utils/logger.dart';

final productDetailStateProvider =
    NotifierProvider<ProductDetailStateNotifier, ProductDetailState>(
      ProductDetailStateNotifier.new,
      isAutoDispose: true,
    );

class ProductDetailState extends BaseState with Equatable {
  const ProductDetailState({
    this.product,
    this.holdings = const [],
    this.storeId,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  /// Carries only the batches held in [storeId] — the API scopes it that way.
  final ProductEntity? product;

  /// Every store of the caller's holding this product, the viewed one included.
  final List<StoreHolding> holdings;
  final String? storeId;

  /// Expiry ascending, undated last, so the top lot is always the one the next
  /// Use will draw from — the ordering is the explanation.
  ///
  /// Depleted lots stay in the list: they are the price history.
  List<ProductBatchEntity> get orderedBatches {
    final live = (product?.batches ?? const <ProductBatchEntity>[])
        .where((batch) => !batch.archived)
        .toList();
    return live..sort(compareBatchesFefo);
  }

  /// The lot the next Use draws from, or null when nothing holds stock.
  ProductBatchEntity? get nextOut {
    final available = product?.availableBatches ?? const <ProductBatchEntity>[];
    return available.isEmpty ? null : available.first;
  }

  List<StoreHolding> get otherStores =>
      holdings.where((holding) => holding.storeId != storeId).toList();

  bool get canUseStock => (product?.hasStock ?? false) && !(product?.archived ?? false);

  @override
  ProductDetailState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    ProductEntity? product,
    List<StoreHolding>? holdings,
    String? storeId,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      holdings: holdings ?? this.holdings,
      storeId: storeId ?? this.storeId,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    product,
    holdings,
    storeId,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class ProductDetailStateNotifier extends BaseStateNotifier<ProductDetailState> {
  late final ProductRepository _repository;
  String? _storeId;

  @override
  ProductDetailState createInitialState() {
    _repository = ref.read(productRepositoryProvider);
    _storeId = ref.read(activeStoreProvider);
    return ProductDetailState(storeId: _storeId);
  }

  Future<void> load(String id) async {
    final storeId = _storeId;
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
      showLoading();
      final product = await _repository.getProduct(id, storeId: storeId);
      if (!ref.mounted) return;
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          product: product,
          storeId: storeId,
        ),
      );
      await _loadHoldings(id);
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  /// Decoration, not content: a product that will not say where else it is
  /// stocked is still perfectly readable here.
  Future<void> _loadHoldings(String id) async {
    try {
      final holdings = await _repository.getHoldings(id);
      if (!ref.mounted) return;
      updateState(state.copyWith(holdings: holdings));
    } on Object catch (e) {
      logger.e('Failed to load cross-store holdings', error: e);
    }
  }

  Future<void> archive() => _setArchived(archived: true);

  Future<void> restore() => _setArchived(archived: false);

  Future<void> _setArchived({required bool archived}) async {
    final storeId = _storeId;
    final id = state.product?.id;
    if (storeId == null || id == null) return;

    try {
      showLoading();
      final product = archived
          ? await _repository.archiveProduct(id, storeId: storeId)
          : await _repository.restoreProduct(id, storeId: storeId);
      if (!ref.mounted) return;
      updateState(state.copyWith(status: StateLifeCycle.loaded, product: product));
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }
}
