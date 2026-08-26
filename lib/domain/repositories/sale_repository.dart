import 'package:decimal/decimal.dart';

import 'package:mine_storage/domain/entities/entities.dart';

/// The seam the Supabase spec replaces.
///
/// Every rule the UI must not own is stated here rather than in a widget: the
/// FEFO split, §5.3's money, and §5.4's rule that stock moves only on confirm.
/// A server implementation inherits all three by contract.
abstract class SaleRepository {
  /// Resolves the split for [quantity] without touching stock, so the seller
  /// sees the same lots the confirm will draw from.
  Future<List<SaleAllocation>> previewAllocation({
    required String productId,
    required String storeId,
    required Decimal quantity,
  });

  /// Revalidates every lot, deducts, and records the sale as one operation.
  ///
  /// Throws [InsufficientStockException] and deducts nothing at all if any lot
  /// in the draft no longer holds what it was allocated — a partial deduction
  /// would leave stock the sale never paid for.
  Future<Sale> confirm(SaleDraft draft, {required String storeId});

  /// Recorded sales for one store, newest first.
  Future<List<Sale>> salesFor({required String storeId});

  /// Distinct product ids from the most recent sales, newest first.
  Future<List<String>> recentlySoldProductIds({
    required String storeId,
    int limit = 5,
  });

  /// Every figure the dashboard shows, derived from the sales actually
  /// recorded — so an empty shop and a busy one fall out of the same data.
  Future<SalesDashboardSummary> dashboardSummary({
    required String storeId,
    required DateTime today,
  });
}
