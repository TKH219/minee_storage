import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/store_overview_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

final storeSwitcherStateProvider =
    NotifierProvider<StoreSwitcherStateNotifier, StoreSwitcherState>(
      StoreSwitcherStateNotifier.new,
      isAutoDispose: true,
    );

class StoreSwitcherState extends BaseState with Equatable {
  const StoreSwitcherState({
    this.summaries = const [],
    this.activeStoreId,
    this.allStores = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final List<StoreSummary> summaries;
  final String? activeStoreId;
  final bool allStores;

  /// The aggregate answers across shops, which only an owner is entitled to
  /// see — and it is meaningless with a single store.
  bool get canSeeAllStores =>
      summaries.length > 1 &&
      summaries.any((summary) => summary.role == StoreRole.owner);

  /// Sorted and deduplicated, so the notice reads the same every time.
  List<String> get mixedCurrencyCodes {
    final codes = summaries.map((summary) => summary.currency.code).toSet();
    if (codes.length < 2) return const [];
    return codes.toList()..sort();
  }

  @override
  StoreSwitcherState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    List<StoreSummary>? summaries,
    String? activeStoreId,
    bool? allStores,
  }) {
    return StoreSwitcherState(
      summaries: summaries ?? this.summaries,
      activeStoreId: activeStoreId ?? this.activeStoreId,
      allStores: allStores ?? this.allStores,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    summaries,
    activeStoreId,
    allStores,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class StoreSwitcherStateNotifier extends BaseStateNotifier<StoreSwitcherState> {
  late final StoreOverviewRepository _stores;

  @override
  StoreSwitcherState createInitialState() {
    _stores = ref.read(storeOverviewRepositoryProvider);
    return const StoreSwitcherState();
  }

  Future<void> load() async {
    showLoading();
    try {
      final summaries = await _stores.summaries();
      if (!ref.mounted) return;
      updateState(
        StoreSwitcherState(
          status: StateLifeCycle.loaded,
          summaries: summaries,
          activeStoreId: ref.read(activeStoreProvider),
          allStores: ref.read(allStoresScopeProvider),
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  Future<void> select(String storeId) async {
    await ref.read(activeStoreProvider.notifier).select(storeId);
    if (!ref.mounted) return;
    updateState(state.copyWith(activeStoreId: storeId, allStores: false));
  }

  /// Refused outright for a non-owner rather than merely hidden: the sheet is
  /// not the only thing that could call this.
  void selectAllStores() {
    if (!state.canSeeAllStores) return;
    ref.read(allStoresScopeProvider.notifier).set(true);
    updateState(state.copyWith(allStores: true));
  }
}
