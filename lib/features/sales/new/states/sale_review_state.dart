import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/sale_repository.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/providers.dart';

/// Deliberately not auto-disposed: the success screen reads the recorded sale
/// off this state after the review screen has been replaced.
final saleReviewStateProvider =
    NotifierProvider<SaleReviewStateNotifier, SaleReviewState>(
      SaleReviewStateNotifier.new,
    );

class SaleReviewState extends BaseState with Equatable {
  SaleReviewState({
    this.sale,
    SaleTotals? totals,
    Currency? currency,
    this.paymentMethod = PaymentMethod.cash,
    this.showsCostAndProfit = true,
    this.hasLines = false,
    this.lotCount = 0,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  }) : totals = totals ?? SaleTotals.zero,
       currency = currency ?? Currency.vnd;

  /// Set only once payment has landed and stock has actually moved.
  final Sale? sale;

  final SaleTotals totals;
  final Currency currency;
  final PaymentMethod paymentMethod;

  /// §F11 — for staff the cost and profit rows are absent, not masked.
  final bool showsCostAndProfit;

  final bool hasLines;
  final int lotCount;

  bool get isPaid => sale != null;

  bool get canConfirm => hasLines && !isLoading && !isPaid;

  @override
  SaleReviewState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    Sale? sale,
    SaleTotals? totals,
    Currency? currency,
    PaymentMethod? paymentMethod,
    bool? showsCostAndProfit,
    bool? hasLines,
    int? lotCount,
  }) {
    return SaleReviewState(
      sale: sale ?? this.sale,
      totals: totals ?? this.totals,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      showsCostAndProfit: showsCostAndProfit ?? this.showsCostAndProfit,
      hasLines: hasLines ?? this.hasLines,
      lotCount: lotCount ?? this.lotCount,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    sale,
    totals,
    currency,
    paymentMethod,
    showsCostAndProfit,
    hasLines,
    lotCount,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class SaleReviewStateNotifier extends BaseStateNotifier<SaleReviewState> {
  SaleRepository? _sales;

  /// Held on the notifier rather than only on the state: watching the basket
  /// re-runs the build, and a paid sale must survive that.
  Sale? _sale;

  @override
  SaleReviewState createInitialState() {
    _sales ??= ref.read(saleRepositoryProvider);
    final cart = ref.watch(saleCartStateProvider);

    return SaleReviewState(
      sale: _sale,
      status: _sale != null ? StateLifeCycle.loaded : StateLifeCycle.init,
      totals: cart.draft.totals,
      currency: cart.currency,
      paymentMethod: cart.draft.paymentMethod,
      showsCostAndProfit: cart.showsCostAndProfit,
      hasLines: !cart.draft.isEmpty,
      lotCount: cart.draft.lotCount,
    );
  }

  Future<void> confirm() async {
    if (!state.canConfirm) return;

    final cart = ref.read(saleCartStateProvider);
    final storeId = cart.storeId;
    if (storeId == null) return;

    showLoading();
    try {
      // §5.4.2 — one operation: revalidate every lot, deduct, record. Nothing
      // before this point has moved a single unit.
      final sale = await _sales!.confirm(cart.draft, storeId: storeId);
      if (!ref.mounted) return;
      _sale = sale;
      updateState(state.copyWith(status: StateLifeCycle.loaded, sale: sale));
    } on Object catch (e) {
      if (!ref.mounted) return;
      // The basket is left intact: the seller goes back to the allocation and
      // fixes whichever lot ran short.
      onError(e);
    }
  }

  void reset() {
    _sale = null;
    updateState(SaleReviewState());
  }
}
