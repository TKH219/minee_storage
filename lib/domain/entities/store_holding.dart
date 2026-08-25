import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// What one product holds in one of the caller's stores.
///
/// Cross-store by design: every other read is scoped to a single store, so this
/// is the only thing that can answer "where else is this?".
class StoreHolding extends Equatable {
  const StoreHolding({
    required this.storeId,
    required this.storeName,
    required this.remaining,
    this.latestUnitPrice,
  });

  final String storeId;
  final String storeName;
  final Decimal remaining;
  final Decimal? latestUnitPrice;

  @override
  List<Object?> get props => [storeId, storeName, remaining, latestUnitPrice];
}
