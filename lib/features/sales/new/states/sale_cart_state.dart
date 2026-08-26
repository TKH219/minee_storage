import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/store_overview_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

/// Kept alive for the whole sale flow — the cart, the review and the success
/// screen all read the same draft.
final saleCartStateProvider =
    NotifierProvider<SaleCartStateNotifier, SaleCartState>(
      SaleCartStateNotifier.new,
    );

class SaleCartState extends BaseState with Equatable {
  SaleCartState({
    this.draft = const SaleDraft(),
    Currency? currency,
    this.role = StoreRole.owner,
    this.storeId,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  }) : currency = currency ?? Currency.vnd;

  final SaleDraft draft;
  final Currency currency;
  final StoreRole role;
  final String? storeId;

  bool get isEmpty => draft.isEmpty;

  /// §F11 — cost and profit are the owner's business, and staff never see them.
  bool get showsCostAndProfit => role != StoreRole.staff;

  @override
  SaleCartState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    SaleDraft? draft,
    Currency? currency,
    StoreRole? role,
    String? storeId,
  }) {
    return SaleCartState(
      draft: draft ?? this.draft,
      currency: currency ?? this.currency,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    currency,
    role,
    storeId,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class SaleCartStateNotifier extends BaseStateNotifier<SaleCartState> {
  late final StoreOverviewRepository _stores;

  @override
  SaleCartState createInitialState() {
    _stores = ref.read(storeOverviewRepositoryProvider);
    return SaleCartState();
  }

  Future<void> load() async {
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
      final summaries = await _stores.summaries();
      if (!ref.mounted) return;
      final store = summaries
          .where((summary) => summary.store.id == storeId)
          .firstOrNull;
      final currency = store?.currency ?? Currency.vnd;

      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          storeId: storeId,
          currency: currency,
          role: store?.role ?? StoreRole.owner,
          draft: state.draft.copyWith(decimals: currency.decimals),
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  void addLine(SaleDraftLine line) =>
      _withLines([...state.draft.lines, line]);

  void replaceLine(int index, SaleDraftLine line) {
    final lines = [...state.draft.lines];
    if (index < 0 || index >= lines.length) return;
    lines[index] = line;
    _withLines(lines);
  }

  void removeLine(int index) {
    final lines = [...state.draft.lines];
    if (index < 0 || index >= lines.length) return;
    lines.removeAt(index);
    _withLines(lines);
  }

  void setFees(List<Fee> fees) =>
      updateState(state.copyWith(draft: state.draft.copyWith(fees: fees)));

  void setPaymentMethod(PaymentMethod method) => updateState(
    state.copyWith(draft: state.draft.copyWith(paymentMethod: method)),
  );

  /// The store survives, so the next sale does not have to reload it.
  void reset() => updateState(
    state.copyWith(draft: SaleDraft(decimals: state.currency.decimals)),
  );

  void _withLines(List<SaleDraftLine> lines) =>
      updateState(state.copyWith(draft: state.draft.copyWith(lines: lines)));
}
