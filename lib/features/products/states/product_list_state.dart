import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/utils/logger.dart';

final productListStateProvider =
    NotifierProvider<ProductListStateNotifier, ProductListState>(
      ProductListStateNotifier.new,
      isAutoDispose: true,
    );

class ProductListState extends BaseState with Equatable {
  const ProductListState({
    this.products = const [],
    this.filter = const ProductFilter(),
    this.categories = const [],
    this.page = 1,
    this.hasReachedEnd = false,
    this.isLoadingMore = false,
    this.expiringSoonCount = 0,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final List<ProductEntity> products;
  final ProductFilter filter;
  final List<String> categories;
  final int page;
  final bool hasReachedEnd;
  final bool isLoadingMore;

  /// Drives the count line beside the Expiring soon chip.
  final int expiringSoonCount;

  bool get isEmpty => isLoaded && products.isEmpty;

  /// A failed *page* load keeps the list and surfaces a snack bar instead.
  bool get showFullScreenError => isError && products.isEmpty;

  @override
  ProductListState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    List<ProductEntity>? products,
    ProductFilter? filter,
    List<String>? categories,
    int? page,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    int? expiringSoonCount,
  }) {
    return ProductListState(
      products: products ?? this.products,
      filter: filter ?? this.filter,
      categories: categories ?? this.categories,
      page: page ?? this.page,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      expiringSoonCount: expiringSoonCount ?? this.expiringSoonCount,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    products,
    filter,
    categories,
    page,
    hasReachedEnd,
    isLoadingMore,
    expiringSoonCount,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class ProductListStateNotifier extends BaseStateNotifier<ProductListState> {
  late final ProductRepository _repository;
  String? _storeId;

  @override
  ProductListState createInitialState() {
    _repository = ref.read(productRepositoryProvider);
    _storeId = ref.read(activeStoreProvider);
    return const ProductListState();
  }

  /// Stock belongs to a store, so there is nothing truthful to show without
  /// one. Guessing a store would show the wrong shop's shelves.
  bool get _hasStore => _storeId != null;

  void _refuseWithoutStore() {
    updateState(
      state.copyWith(
        status: StateLifeCycle.error,
        errorMessageKey: LocaleKeys.products_noActiveStore,
      ),
    );
  }

  Future<void> loadInitial() async {
    showLoading();
    await _fetchFirstPage();
  }

  /// Pull-to-refresh must not flip to loading — that would swap the list for
  /// the blocking overlay.
  Future<void> refresh() => _fetchFirstPage();

  Future<void> search(String query) => _applyAndReload(state.filter.copyWith(query: query));

  Future<void> applyFilter(ProductFilter filter) => _applyAndReload(filter);

  Future<void> setQuickFilter(ProductQuickFilter quickFilter) =>
      _applyAndReload(state.filter.copyWith(quickFilter: quickFilter));

  Future<void> loadCategories() async {
    try {
      // `state` must be read AFTER the await: as an argument expression the
      // receiver is evaluated first, which would capture the pre-await state
      // and write it back over whatever landed meanwhile.
      final categories = await _repository.getCategories();
      updateState(state.copyWith(categories: categories));
    } on Object catch (e) {
      // A missing category list must not break the screen it decorates: log it
      // and leave the state alone, so the filter sheet simply offers no
      // categories.
      logger.e('Failed to load product categories', error: e);
    }
  }

  Future<void> _applyAndReload(ProductFilter filter) async {
    updateState(state.copyWith(filter: filter));
    await _fetchFirstPage();
  }

  Future<void> _fetchFirstPage() async {
    if (!_hasStore) return _refuseWithoutStore();
    try {
      final result = await _repository.getProducts(
        storeId: _storeId!,
        filter: state.filter,
        page: 1,
      );
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          products: result.items,
          page: 1,
          hasReachedEnd: !result.hasMore,
          expiringSoonCount: _countExpiringSoon(result.items),
        ),
      );
    } on Object catch (e) {
      onError(e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd || state.products.isEmpty) return;
    if (!_hasStore) return;

    final nextPage = state.page + 1;
    updateState(state.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.getProducts(
        storeId: _storeId!,
        filter: state.filter,
        page: nextPage,
        limit: Constants.defaultPageSize,
      );
      final products = [...state.products, ...result.items];
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          products: products,
          page: nextPage,
          hasReachedEnd: !result.hasMore,
          isLoadingMore: false,
          expiringSoonCount: _countExpiringSoon(products),
        ),
      );
    } on Object catch (e) {
      updateState(state.copyWith(isLoadingMore: false));
      onError(e);
    }
  }

  int _countExpiringSoon(List<ProductEntity> products) {
    final now = DateTime.now();
    return products.where((product) => product.statusOn(now).isExpiringSoon).length;
  }
}
