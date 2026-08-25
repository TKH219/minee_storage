import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

enum ScanOutcome { none, hit, miss }

final scanStateProvider = NotifierProvider<ScanStateNotifier, ScanState>(
  ScanStateNotifier.new,
  isAutoDispose: true,
);

class ScanState extends BaseState with Equatable {
  const ScanState({
    this.barcode,
    this.product,
    this.outcome = ScanOutcome.none,
    this.permissionDenied = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  /// Kept on a miss too — it is the one thing already known about the product
  /// the user is about to create.
  final String? barcode;
  final ProductEntity? product;
  final ScanOutcome outcome;
  final bool permissionDenied;

  @override
  ScanState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    String? barcode,
    ProductEntity? product,
    ScanOutcome? outcome,
    bool? permissionDenied,
  }) {
    return ScanState(
      barcode: barcode ?? this.barcode,
      product: product ?? this.product,
      outcome: outcome ?? this.outcome,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    barcode,
    product,
    outcome,
    permissionDenied,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class ScanStateNotifier extends BaseStateNotifier<ScanState> {
  late final ProductRepository _repository;
  String? _storeId;
  String? _lastLookedUp;

  @override
  ScanState createInitialState() {
    _repository = ref.read(productRepositoryProvider);
    _storeId = ref.read(activeStoreProvider);
    return const ScanState();
  }

  /// A camera fires the same code many times a second, so a barcode already
  /// resolved is ignored until [reset]. Debouncing in the widget would still
  /// let two different frames race.
  Future<void> decoded(String raw) async {
    final barcode = raw.trim();
    if (barcode.isEmpty || barcode == _lastLookedUp) return;

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

    _lastLookedUp = barcode;
    try {
      showLoading();
      final product = await _repository.findByBarcode(barcode, storeId: storeId);
      if (!ref.mounted) return;
      updateState(
        ScanState(
          status: StateLifeCycle.loaded,
          barcode: barcode,
          product: product,
          outcome: product == null ? ScanOutcome.miss : ScanOutcome.hit,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      // Deliberately not a miss: sending the user to create a product because
      // the network failed is how duplicates get made.
      _lastLookedUp = null;
      onError(e);
    }
  }

  void reset() {
    _lastLookedUp = null;
    updateState(const ScanState());
  }

  void cameraDenied() => updateState(state.copyWith(permissionDenied: true));
}
