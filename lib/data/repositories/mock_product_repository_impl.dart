import 'package:mine_storage/data/mock/mock_database.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';

class MockProductRepositoryImpl implements ProductRepository {
  MockProductRepositoryImpl(
    this._db, {
    this.latency = const Duration(milliseconds: 350),
  });

  final MockDatabase _db;

  /// Held deliberately so the skeleton and dots states are observable at
  /// runtime; tests pass [Duration.zero].
  final Duration latency;

  Future<void> get _wait => Future<void>.delayed(latency);

  @override
  Future<List<Product>> list({
    required String storeId,
    bool includeArchived = false,
    String? query,
  }) async {
    await _wait;
    final products = _db.productsFor(storeId, includeArchived: includeArchived);
    if (query == null || query.trim().isEmpty) return products;

    final needle = query.trim().toLowerCase();
    return products.where((p) => p.name.toLowerCase().contains(needle)).toList(growable: false);
  }

  @override
  Future<Product> byId(String id) async {
    await _wait;
    return _db.productById(id);
  }

  @override
  Future<List<Allocation>> previewConsumption(String productId, double quantity) async =>
      _db.previewConsumption(productId, quantity);

  @override
  Future<void> consume(String productId, double quantity) async {
    await _wait;
    _db.applyConsumption(productId, quantity);
  }

  @override
  Future<void> addLot(Lot lot) async {
    await _wait;
    _db.addLot(lot);
  }

  @override
  Future<void> archive(String id) async {
    await _wait;
    _db.archive(id);
  }

  @override
  Future<void> restore(String id) async {
    await _wait;
    _db.restore(id);
  }
}
