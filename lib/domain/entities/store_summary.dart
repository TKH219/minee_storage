import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/currency.dart';
import 'package:mine_storage/domain/entities/store.dart';

/// One row of the store switcher: which shop, in what currency, holding how
/// much, and what the signed-in user is allowed to do there.
class StoreSummary extends Equatable {
  const StoreSummary({
    required this.store,
    required this.currency,
    required this.productCount,
  });

  final Store store;
  final Currency currency;
  final int productCount;

  StoreRole get role => store.role;

  @override
  List<Object?> get props => [store, currency, productCount];
}
