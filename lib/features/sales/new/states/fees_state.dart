import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/services/sale_money.dart';

final feesStateProvider = NotifierProvider<FeesStateNotifier, FeesState>(
  FeesStateNotifier.new,
  isAutoDispose: true,
);

class FeesState extends BaseState with Equatable {
  FeesState({
    Decimal? itemsSubtotal,
    this.fees = const [],
    this.decimals = 2,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  }) : itemsSubtotal = itemsSubtotal ?? Decimal.zero;

  final Decimal itemsSubtotal;
  final List<Fee> fees;
  final int decimals;

  /// The whole basket resolved, so the editor can name each fee's base and
  /// show what it did to the totals — the same call the sale itself makes.
  SaleTotals get totals => SaleMoney.compute(
    itemsSubtotal: itemsSubtotal,
    cogs: Decimal.zero,
    fees: fees,
    decimals: decimals,
  );

  List<ComputedFee> get computed => totals.fees;

  bool get hasDiscount =>
      fees.any((fee) => fee.direction == FeeDirection.discount);

  /// Signed the way the row reads it: a discount and a seller cost both take
  /// money away, so both come back negative.
  Decimal amountFor(String feeId) {
    final resolved = computed.where((each) => each.fee.id == feeId).firstOrNull;
    if (resolved == null) return Decimal.zero;
    final takesAway =
        resolved.fee.direction == FeeDirection.discount ||
        resolved.fee.direction == FeeDirection.sellerCost;
    return takesAway ? -resolved.amount : resolved.amount;
  }

  @override
  FeesState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    Decimal? itemsSubtotal,
    List<Fee>? fees,
    int? decimals,
  }) {
    return FeesState(
      itemsSubtotal: itemsSubtotal ?? this.itemsSubtotal,
      fees: fees ?? this.fees,
      decimals: decimals ?? this.decimals,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    itemsSubtotal,
    fees,
    decimals,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class FeesStateNotifier extends BaseStateNotifier<FeesState> {
  int _nextId = 1;

  @override
  FeesState createInitialState() => FeesState();

  void open({
    required Decimal itemsSubtotal,
    required List<Fee> fees,
    required int decimals,
  }) {
    updateState(
      FeesState(
        status: StateLifeCycle.loaded,
        itemsSubtotal: itemsSubtotal,
        fees: fees,
        decimals: decimals,
      ),
    );
  }

  void addFee(Fee fee) {
    final resolved = fee.id.isEmpty ? _withId(fee) : fee;
    updateState(state.copyWith(fees: [...state.fees, resolved]));
  }

  void removeFee(String feeId) => updateState(
    state.copyWith(
      fees: state.fees.where((fee) => fee.id != feeId).toList(),
    ),
  );

  Fee _withId(Fee fee) => Fee(
    id: 'fee-${_nextId++}',
    name: fee.name,
    kind: fee.kind,
    value: fee.value,
    direction: fee.direction,
  );
}
