import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/domain/repositories/sale_repository.dart';
import 'package:mine_storage/domain/repositories/store_overview_repository.dart';
import 'package:mine_storage/domain/services/attention_alerts.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

final dashboardStateProvider =
    NotifierProvider<DashboardStateNotifier, DashboardState>(
      DashboardStateNotifier.new,
      isAutoDispose: true,
    );

class DashboardState extends BaseState with Equatable {
  DashboardState({
    this.storeName = '',
    this.role = StoreRole.owner,
    Currency? currency,
    DateTime? today,
    this.hasProducts = false,
    this.summary,
    this.alerts = const [],
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  }) : currency = currency ?? Currency.vnd,
       today = today ?? DateTime(1970);

  final String storeName;
  final StoreRole role;
  final Currency currency;
  final DateTime today;
  final bool hasProducts;

  /// Null until the store is known to hold stock — an empty shop gets an
  /// instruction, not six tiles reading zero.
  final SalesDashboardSummary? summary;

  final List<AttentionAlert> alerts;

  bool get isEmpty => isLoaded && !hasProducts;

  bool get showFullScreenError => isError && summary == null;

  bool get showsProfit => role != StoreRole.staff;

  @override
  DashboardState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    String? storeName,
    StoreRole? role,
    Currency? currency,
    DateTime? today,
    bool? hasProducts,
    SalesDashboardSummary? summary,
    List<AttentionAlert>? alerts,
  }) {
    return DashboardState(
      storeName: storeName ?? this.storeName,
      role: role ?? this.role,
      currency: currency ?? this.currency,
      today: today ?? this.today,
      hasProducts: hasProducts ?? this.hasProducts,
      summary: summary ?? this.summary,
      alerts: alerts ?? this.alerts,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    storeName,
    role,
    currency,
    today,
    hasProducts,
    summary,
    alerts,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class DashboardStateNotifier extends BaseStateNotifier<DashboardState> {
  late final ProductRepository _products;
  late final SaleRepository _sales;
  late final StoreOverviewRepository _stores;
  late final DateTime Function() _now;

  @override
  DashboardState createInitialState() {
    _products = ref.read(productRepositoryProvider);
    _sales = ref.read(saleRepositoryProvider);
    _stores = ref.read(storeOverviewRepositoryProvider);
    _now = ref.read(nowProvider);
    return DashboardState();
  }

  Future<void> load() async {
    showLoading();
    await _fetch();
  }

  /// Refresh keeps the figures on screen while it works — swapping them for a
  /// spinner would make a pull-to-refresh read as a failure.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    // Read fresh rather than cached: the store switcher changes this between
    // one load and the next, and a cached id would keep showing the old shop.
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
      final today = _now();
      final summaries = await _stores.summaries();
      final store = summaries
          .where((summary) => summary.store.id == storeId)
          .firstOrNull;

      final page = await _products.getProducts(
        storeId: storeId,
        filter: const ProductFilter(),
        page: 1,
        limit: Constants.defaultPageSize,
      );
      final stocked = page.items.where((product) => product.hasStock).toList();

      if (!ref.mounted) return;

      if (stocked.isEmpty) {
        updateState(
          DashboardState(
            status: StateLifeCycle.loaded,
            storeName: store?.store.name ?? '',
            role: store?.role ?? StoreRole.owner,
            currency: store?.currency,
            today: today,
            hasProducts: false,
          ),
        );
        return;
      }

      final summary = await _sales.dashboardSummary(storeId: storeId, today: today);
      if (!ref.mounted) return;

      updateState(
        DashboardState(
          status: StateLifeCycle.loaded,
          storeName: store?.store.name ?? '',
          role: store?.role ?? StoreRole.owner,
          currency: store?.currency,
          today: today,
          hasProducts: true,
          summary: summary,
          alerts: AttentionAlerts.from(page.items, today: today),
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }
}
