import 'package:decimal/decimal.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/batch_allocation.dart';
import 'package:mine_storage/domain/entities/product_batch_entity.dart';

/// First-expire-first-out allocation.
///
/// Pure by design: no clock, no network, no Flutter. Expired batches are still
/// allocated first — the caller warns the user, the rule itself does not change.
abstract class FefoAllocator {
  static List<BatchAllocation> allocate({
    required Decimal quantity,
    required List<ProductBatchEntity> batches,
  }) {
    if (quantity <= Decimal.zero) {
      throw ArgumentError.value(quantity, 'quantity', 'must be greater than zero');
    }

    final available = batches.where((batch) => !batch.archived && batch.hasStock).toList()
      ..sort(compareBatchesFefo);

    final total = available.fold(
      Decimal.zero,
      (sum, batch) => sum + batch.remainingQuantity,
    );
    if (total < quantity) {
      throw InsufficientStockException(requested: quantity, available: total);
    }

    final allocations = <BatchAllocation>[];
    var outstanding = quantity;
    for (final batch in available) {
      if (outstanding <= Decimal.zero) break;
      final take =
          outstanding < batch.remainingQuantity ? outstanding : batch.remainingQuantity;
      allocations.add(BatchAllocation(batchId: batch.id, quantity: take));
      outstanding -= take;
    }
    return allocations;
  }
}
