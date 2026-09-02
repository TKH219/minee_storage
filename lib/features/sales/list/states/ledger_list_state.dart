import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

final ledgerListStateProvider =
    NotifierProvider<LedgerListStateNotifier, LedgerListState>(
      LedgerListStateNotifier.new,
      isAutoDispose: true,
    );

class LedgerListState extends BaseState with Equatable {
  const LedgerListState({
    this.days = const [],
    this.filter = const LedgerFilter(),
    this.page = 1,
    this.total = 0,
    this.hasReachedEnd = false,
    this.isLoadingMore = false,
    this.nextPageFailed = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final List<TransactionDay> days;
  final LedgerFilter filter;
  final int page;
  final int total;
  final bool hasReachedEnd;
  final bool isLoadingMore;

  /// A later page failed. The rows already fetched keep their place and a retry
  /// sits where the missing page would have been.
  final bool nextPageFailed;

  int get loadedCount =>
      days.fold(0, (sum, day) => sum + day.transactions.length);

  /// Nothing has ever been recorded — the first-run state, not an error.
  bool get isEmpty => isLoaded && days.isEmpty && filter.isEmpty;

  /// The filters matched nothing. Distinct from [isEmpty]: the filters that
  /// caused it stay on screen and stay removable.
  bool get hasNoResults => isLoaded && days.isEmpty && filter.isActive;

  /// A failed *page* load keeps the list; only a failed first page takes over
  /// the screen.
  bool get showFullScreenError => isError && days.isEmpty;

  @override
  LedgerListState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    List<TransactionDay>? days,
    LedgerFilter? filter,
    int? page,
    int? total,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    bool? nextPageFailed,
  }) {
    return LedgerListState(
      days: days ?? this.days,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      total: total ?? this.total,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextPageFailed: nextPageFailed ?? this.nextPageFailed,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    days,
    filter,
    page,
    total,
    hasReachedEnd,
    isLoadingMore,
    nextPageFailed,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class LedgerListStateNotifier extends BaseStateNotifier<LedgerListState> {
  late final TransactionRepository _repository;
  String? _storeId;

  @override
  LedgerListState createInitialState() {
    _repository = ref.read(transactionRepositoryProvider);
    _storeId = ref.read(activeStoreProvider);
    return const LedgerListState();
  }

  /// A movement belongs to a store, so there is nothing truthful to show
  /// without one. Guessing would show the wrong shop's ledger.
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

  Future<void> search(String query) =>
      _applyAndReload(state.filter.copyWith(query: query));

  Future<void> setType(TransactionType? type) => _applyAndReload(
    type == null
        ? state.filter.copyWith(clearType: true)
        : state.filter.copyWith(type: type),
  );

  Future<void> setPaymentMethod(PaymentMethod? method) => _applyAndReload(
    method == null
        ? state.filter.copyWith(clearPaymentMethod: true)
        : state.filter.copyWith(paymentMethod: method),
  );

  Future<void> setDateRange(DateTime? from, DateTime? to) => _applyAndReload(
    from == null && to == null
        ? state.filter.copyWith(clearDates: true)
        : state.filter.copyWith(from: from, to: to),
  );

  Future<void> setProduct(String? productId) => _applyAndReload(
    productId == null
        ? state.filter.copyWith(clearProduct: true)
        : state.filter.copyWith(productId: productId),
  );

  Future<void> applyFilter(LedgerFilter filter) => _applyAndReload(filter);

  Future<void> clearFilters() => _applyAndReload(const LedgerFilter());

  Future<void> _applyAndReload(LedgerFilter filter) async {
    updateState(state.copyWith(filter: filter));
    await _fetchFirstPage();
  }

  Future<void> _fetchFirstPage() async {
    if (_storeId == null) return _refuseWithoutStore();
    try {
      final result = await _repository.list(
        storeId: _storeId!,
        type: state.filter.type,
        from: state.filter.from,
        to: state.filter.to,
        productId: state.filter.productId,
        paymentMethod: state.filter.paymentMethod,
        query: state.filter.query,
        page: 1,
      );
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          days: result.days,
          page: 1,
          total: result.total,
          hasReachedEnd: !result.hasMore,
          isLoadingMore: false,
          nextPageFailed: false,
        ),
      );
    } on Object catch (e) {
      onError(e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd || state.days.isEmpty) return;
    if (_storeId == null) return;

    final nextPage = state.page + 1;
    updateState(state.copyWith(isLoadingMore: true, nextPageFailed: false));
    try {
      final result = await _repository.list(
        storeId: _storeId!,
        type: state.filter.type,
        from: state.filter.from,
        to: state.filter.to,
        productId: state.filter.productId,
        paymentMethod: state.filter.paymentMethod,
        query: state.filter.query,
        page: nextPage,
        limit: Constants.defaultPageSize,
      );
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          days: _merge(state.days, result.days),
          page: nextPage,
          total: result.total,
          hasReachedEnd: !result.hasMore,
          isLoadingMore: false,
        ),
      );
    } on Object catch (e) {
      // The rows already fetched keep their place; only the missing page is
      // flagged, so a retry lands where the gap is rather than reloading all.
      final exception = resolveException(e);
      updateState(
        state.copyWith(
          isLoadingMore: false,
          nextPageFailed: true,
          errorMessageKey: exception.messageKey,
          errorMessage: exception.message,
        ),
      );
    }
  }

  Future<void> retryNextPage() => loadMore();

  /// A busy day spans pages, so the tail of a day already on screen arrives
  /// under a header that is already there. It joins that header rather than
  /// opening a second one with the same date and the same subtotal.
  static List<TransactionDay> _merge(
    List<TransactionDay> loaded,
    List<TransactionDay> incoming,
  ) {
    final merged = [...loaded];
    for (final day in incoming) {
      final at = merged.indexWhere((existing) => existing.date == day.date);
      if (at == -1) {
        merged.add(day);
      } else {
        merged[at] = TransactionDay(
          date: day.date,
          subtotal: day.subtotal,
          transactionCount: day.transactionCount,
          transactions: [...merged[at].transactions, ...day.transactions],
        );
      }
    }
    return merged;
  }
}
