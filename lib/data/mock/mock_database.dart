import 'package:mine_storage/domain/entities/lot.dart';
import 'package:mine_storage/domain/entities/product.dart';
import 'package:mine_storage/domain/entities/store.dart';

import 'mock_seed.dart';

export 'package:mine_storage/domain/entities/lot.dart';
export 'package:mine_storage/domain/entities/product.dart';
export 'package:mine_storage/domain/entities/store.dart';

class Allocation {
  const Allocation({required this.lot, required this.quantity});

  final Lot lot;
  final double quantity;

  bool get emptiesLot => lot.remainingQuantity - quantity <= 0;

  double get remainingAfter => lot.remainingQuantity - quantity;
}

class InsufficientStockException implements Exception {
  const InsufficientStockException(this.requested, this.available);

  final double requested;
  final double available;
}

/// The single mutable source of truth standing in for the backend. It owns the
/// rules the UI must not re-implement: FEFO allocation, archive-not-delete, and
/// the refusal of partial fulfilment.
class MockDatabase {
  MockDatabase({DateTime? today}) : today = today ?? DateTime.now() {
    final seed = mockSeed();
    _stores.addAll(seed.stores);
    _products.addAll(seed.products);
  }

  final DateTime today;
  final List<Store> _stores = [];
  final List<Product> _products = [];

  List<Store> get stores => List.unmodifiable(_stores);

  List<Product> productsFor(String storeId, {bool includeArchived = false}) => _products
      .where((p) => p.storeId == storeId && (includeArchived || !p.archived))
      .toList(growable: false);

  Product productById(String id) => _products.firstWhere((p) => p.id == id);

  List<Allocation> previewConsumption(String productId, double quantity) {
    final product = productById(productId);
    if (quantity > product.totalRemaining) {
      throw InsufficientStockException(quantity, product.totalRemaining);
    }

    final allocations = <Allocation>[];
    var outstanding = quantity;
    for (final lot in product.lotsFefo.where((l) => l.hasStock)) {
      if (outstanding <= 0) break;
      final take = outstanding < lot.remainingQuantity ? outstanding : lot.remainingQuantity;
      allocations.add(Allocation(lot: lot, quantity: take));
      outstanding -= take;
    }
    return allocations;
  }

  void applyConsumption(String productId, double quantity) {
    final allocations = previewConsumption(productId, quantity);
    final product = productById(productId);
    final updated = [
      for (final lot in product.lots)
        lot.copyWith(
          remainingQuantity: lot.remainingQuantity -
              allocations
                  .where((a) => a.lot.id == lot.id)
                  .fold<double>(0, (sum, a) => sum + a.quantity),
        ),
    ];
    _replace(product.copyWith(lots: updated));
  }

  void addLot(Lot lot) {
    final product = productById(lot.productId);
    _replace(product.copyWith(lots: [...product.lots, lot]));
  }

  void archive(String productId) => _replace(productById(productId).copyWith(archived: true));

  void restore(String productId) => _replace(productById(productId).copyWith(archived: false));

  void _replace(Product product) {
    _products[_products.indexWhere((p) => p.id == product.id)] = product;
  }
}
