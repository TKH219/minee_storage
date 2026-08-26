import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/domain/repositories/sale_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

final productPickerStateProvider =
    NotifierProvider<ProductPickerStateNotifier, ProductPickerState>(
      ProductPickerStateNotifier.new,
      isAutoDispose: true,
    );

class ProductPickerState extends BaseState with Equatable {
  const ProductPickerState({
    this.allProducts = const [],
    this.recentlySold = const [],
    this.query = '',
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final List<ProductEntity> allProducts;

  /// Shown above the full list so the common case needs no typing. Suppressed
  /// while a search is running — the query is the ordering then.
  final List<ProductEntity> recentlySold;

  final String query;

  bool get hasQuery => query.trim().isNotEmpty;

  /// There is no negative stock, so a product holding nothing cannot join a
  /// sale by any path.
  bool canPick(ProductEntity product) => product.hasStock;

  @override
  ProductPickerState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    List<ProductEntity>? allProducts,
    List<ProductEntity>? recentlySold,
    String? query,
  }) {
    return ProductPickerState(
      allProducts: allProducts ?? this.allProducts,
      recentlySold: recentlySold ?? this.recentlySold,
      query: query ?? this.query,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    allProducts,
    recentlySold,
    query,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class ProductPickerStateNotifier extends BaseStateNotifier<ProductPickerState> {
  static const int _pageSize = 200;

  late final ProductRepository _products;
  late final SaleRepository _sales;

  @override
  ProductPickerState createInitialState() {
    _products = ref.read(productRepositoryProvider);
    _sales = ref.read(saleRepositoryProvider);
    return const ProductPickerState();
  }

  Future<void> load() => _fetch(state.query);

  Future<void> search(String query) => _fetch(query);

  Future<void> _fetch(String query) async {
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

    showLoading();
    try {
      final page = await _products.getProducts(
        storeId: storeId,
        filter: ProductFilter(query: query),
        page: 1,
        limit: _pageSize,
      );
      final recentIds = query.trim().isEmpty
          ? await _sales.recentlySoldProductIds(storeId: storeId)
          : const <String>[];
      if (!ref.mounted) return;

      final byId = {for (final product in page.items) product.id: product};

      updateState(
        ProductPickerState(
          status: StateLifeCycle.loaded,
          query: query,
          allProducts: page.items,
          recentlySold: [
            for (final id in recentIds)
              if (byId[id] != null) byId[id]!,
          ],
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }
}
