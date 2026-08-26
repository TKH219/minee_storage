import 'package:decimal/decimal.dart';

import 'package:mine_storage/domain/entities/attention_alert.dart';
import 'package:mine_storage/domain/entities/expiry_status.dart';
import 'package:mine_storage/domain/entities/product_entity.dart';

/// Turns a catalogue into the alerts the dashboard names.
///
/// Pure: no clock of its own, no repository. The caller supplies [today] so a
/// test and the screen can agree on what "expiring soon" means.
abstract class AttentionAlerts {
  static List<AttentionAlert> from(
    List<ProductEntity> products,
    {required DateTime today}
  ) {
    final expired = <ProductEntity>[];
    final expiringSoon = <ProductEntity>[];
    final outOfStock = <ProductEntity>[];

    for (final product in products.where((product) => !product.archived)) {
      switch (product.statusOn(today)) {
        case ExpiryStatus.expired:
          expired.add(product);
        case ExpiryStatus.critical:
        case ExpiryStatus.warning:
          expiringSoon.add(product);
        case ExpiryStatus.none:
          outOfStock.add(product);
        case ExpiryStatus.ok:
          break;
      }
    }

    return [
      if (expired.isNotEmpty)
        AttentionAlert(
          kind: AttentionAlertKind.expired,
          productNames: [for (final product in expired) product.name],
          count: expired.length,
        ),
      if (expiringSoon.isNotEmpty)
        AttentionAlert(
          kind: AttentionAlertKind.expiringSoon,
          productNames: [for (final product in expiringSoon) product.name],
          count: expiringSoon.length,
          valueAtCost: _costOfExpiringStock(expiringSoon, today),
        ),
      if (outOfStock.isNotEmpty)
        AttentionAlert(
          kind: AttentionAlertKind.outOfStock,
          productNames: [for (final product in outOfStock) product.name],
          count: outOfStock.length,
        ),
    ];
  }

  /// Counted over lots, not products: only the lots actually inside the window
  /// are at risk, and a product may hold others that are not.
  static Decimal _costOfExpiringStock(List<ProductEntity> products, DateTime today) {
    final start = DateTime(today.year, today.month, today.day);
    final limit = start.add(expiringSoonWindow);

    var total = Decimal.zero;
    for (final product in products) {
      for (final batch in product.availableBatches) {
        final expiry = batch.expiryDate;
        if (expiry == null) continue;
        final day = DateTime(expiry.year, expiry.month, expiry.day);
        if (day.isAfter(limit)) continue;
        total += batch.unitPrice * batch.remainingQuantity;
      }
    }
    return total;
  }
}
