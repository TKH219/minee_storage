import 'package:decimal/decimal.dart';

import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';

/// In-memory stand-in used until the backend exists. Selected by
/// `Env.useFakeData`; delete once `API_URL` points at a real service.
class FakeProductRepository implements ProductRepository {
  /// [latency] fakes network delay so loading states are visible on device.
  /// Widget tests pass [Duration.zero] — an indeterminate progress indicator
  /// schedules frames forever, so `pumpAndSettle` never returns while one is
  /// on screen.
  FakeProductRepository({this.latency = const Duration(milliseconds: 250)}) {
    _products.addAll(_seed());
  }

  final Duration latency;

  final List<ProductEntity> _products = [];
  int _nextId = 100;

  List<ProductEntity> _seed() {
    ProductBatchEntity batch(
      String id,
      String productId,
      String price,
      String quantity,
      String remaining,
      DateTime purchased,
      DateTime? expiry,
    ) {
      return ProductBatchEntity(
        id: id,
        productId: productId,
        purchasedAt: purchased,
        unitPrice: Decimal.parse(price),
        expiryDate: expiry,
        initialQuantity: Decimal.parse(quantity),
        remainingQuantity: Decimal.parse(remaining),
        createdAt: purchased,
      );
    }

    final now = DateTime.now();
    return [
      ProductEntity(
        id: 'p1',
        name: 'Olive oil 1L',
        barcode: '8934567890123',
        brand: 'Basso',
        category: 'Pantry',
        storageLocation: 'Shelf A',
        notes: 'Cold pressed',
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 2)),
        batches: [
          batch(
            'b1',
            'p1',
            '11.50',
            '6',
            '2',
            now.subtract(const Duration(days: 40)),
            now.add(const Duration(days: 12)),
          ),
          batch(
            'b2',
            'p1',
            '12.75',
            '6',
            '6',
            now.subtract(const Duration(days: 5)),
            now.add(const Duration(days: 200)),
          ),
        ],
      ),
      ProductEntity(
        id: 'p2',
        name: 'Whole milk 1L',
        barcode: '8931112223334',
        brand: 'Vinamilk',
        category: 'Fridge',
        storageLocation: 'Fridge door',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 1)),
        batches: [
          batch(
            'b3',
            'p2',
            '1.20',
            '12',
            '9',
            now.subtract(const Duration(days: 6)),
            now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      ProductEntity(
        id: 'p3',
        name: 'Basmati rice 5kg',
        category: 'Pantry',
        storageLocation: 'Floor bin',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 120)),
        batches: [
          batch(
            'b4',
            'p3',
            '9.00',
            '2',
            '2',
            now.subtract(const Duration(days: 120)),
            now.add(const Duration(days: 400)),
          ),
        ],
      ),
    ];
  }

  ProductEntity _require(String id) {
    final index = _products.indexWhere((product) => product.id == id);
    if (index == -1) throw const NotFoundException(message: 'Product not found.');
    return _products[index];
  }

  ProductEntity _replace(ProductEntity updated) {
    _products[_products.indexWhere((product) => product.id == updated.id)] = updated;
    return updated;
  }

  bool _matches(ProductEntity product, ProductFilter filter, DateTime now) {
    final query = filter.query.trim().toLowerCase();
    if (query.isNotEmpty && !product.name.toLowerCase().contains(query)) return false;
    if (filter.category != null && product.category != filter.category) return false;
    if (filter.createdFrom != null && product.createdAt.isBefore(filter.createdFrom!)) {
      return false;
    }
    if (filter.createdTo != null && product.createdAt.isAfter(filter.createdTo!)) {
      return false;
    }

    final expiry = product.nearestExpiry;
    if (filter.expiryFrom != null && (expiry == null || expiry.isBefore(filter.expiryFrom!))) {
      return false;
    }
    if (filter.expiryTo != null && (expiry == null || expiry.isAfter(filter.expiryTo!))) {
      return false;
    }

    return switch (filter.quickFilter) {
      ProductQuickFilter.archived => product.isArchived,
      ProductQuickFilter.all => !product.isArchived,
      ProductQuickFilter.expiringSoon =>
        !product.isArchived && product.statusOn(now).isExpiringSoon,
      ProductQuickFilter.expired =>
        !product.isArchived && product.statusOn(now) == ExpiryStatus.expired,
    };
  }

  @override
  Future<PagedProducts> getProducts({
    required ProductFilter filter,
    required int page,
    int limit = Constants.defaultPageSize,
  }) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    final matched = _products.where((p) => _matches(p, filter, now)).toList();
    final start = (page - 1) * limit;
    if (start >= matched.length) return const PagedProducts(items: [], hasMore: false);
    final end = (start + limit).clamp(0, matched.length);
    return PagedProducts(items: matched.sublist(start, end), hasMore: end < matched.length);
  }

  @override
  Future<ProductEntity> getProduct(String id) async {
    await Future<void>.delayed(latency);
    return _require(id);
  }

  @override
  Future<ProductEntity?> findByBarcode(String barcode) async {
    await Future<void>.delayed(latency);
    final index = _products.indexWhere(
      (product) => product.barcode == barcode && !product.isArchived,
    );
    return index == -1 ? null : _products[index];
  }

  @override
  Future<List<String>> getCategories() async {
    await Future<void>.delayed(latency);
    return _products.map((product) => product.category).whereType<String>().toSet().toList()
      ..sort();
  }

  @override
  Future<ProductEntity> createProduct(ProductDraft draft) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    final product = ProductEntity(
      id: 'p${_nextId++}',
      name: draft.name,
      createdAt: now,
      updatedAt: now,
      barcode: draft.barcode,
      brand: draft.brand,
      category: draft.category,
      storageLocation: draft.storageLocation,
      notes: draft.notes,
      photoUrl: draft.photoUrl,
    );
    _products.insert(0, product);
    return product;
  }

  @override
  Future<ProductEntity> updateProduct(String id, ProductDraft draft) async {
    await Future<void>.delayed(latency);
    return _replace(
      _require(id).copyWith(
        name: draft.name,
        barcode: draft.barcode,
        brand: draft.brand,
        category: draft.category,
        storageLocation: draft.storageLocation,
        notes: draft.notes,
        photoUrl: draft.photoUrl,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ProductEntity> archiveProduct(String id) async {
    await Future<void>.delayed(latency);
    return _replace(_require(id).copyWith(isArchived: true, updatedAt: DateTime.now()));
  }

  @override
  Future<ProductEntity> restoreProduct(String id) async {
    await Future<void>.delayed(latency);
    return _replace(_require(id).copyWith(isArchived: false, updatedAt: DateTime.now()));
  }

  @override
  Future<ProductEntity> addBatch(String productId, BatchDraft draft) async {
    await Future<void>.delayed(latency);
    final product = _require(productId);
    final batch = ProductBatchEntity(
      id: 'b${_nextId++}',
      productId: productId,
      purchasedAt: draft.purchasedAt,
      unitPrice: draft.unitPrice,
      expiryDate: draft.expiryDate,
      initialQuantity: draft.initialQuantity,
      remainingQuantity: draft.remainingQuantity ?? draft.initialQuantity,
      createdAt: DateTime.now(),
    );
    return _replace(product.copyWith(batches: [...product.batches, batch]));
  }

  @override
  Future<ProductEntity> updateBatch(
    String productId,
    String batchId,
    BatchDraft draft,
  ) async {
    await Future<void>.delayed(latency);
    final product = _require(productId);
    return _replace(
      product.copyWith(
        batches: product.batches.map((batch) {
          if (batch.id != batchId) return batch;
          return batch.copyWith(
            purchasedAt: draft.purchasedAt,
            unitPrice: draft.unitPrice,
            expiryDate: draft.expiryDate,
            initialQuantity: draft.initialQuantity,
            remainingQuantity: draft.remainingQuantity ?? batch.remainingQuantity,
          );
        }).toList(),
      ),
    );
  }

  @override
  Future<ProductEntity> archiveBatch(String productId, String batchId) async {
    await Future<void>.delayed(latency);
    final product = _require(productId);
    return _replace(
      product.copyWith(
        batches: product.batches
            .map((batch) => batch.id == batchId ? batch.copyWith(isArchived: true) : batch)
            .toList(),
      ),
    );
  }

  @override
  Future<ProductEntity> consume(
    String productId,
    List<BatchAllocation> allocations,
  ) async {
    await Future<void>.delayed(latency);
    final product = _require(productId);
    final byId = {for (final a in allocations) a.batchId: a.quantity};

    // Mirrors the contract's all-or-nothing rule: validate every allocation
    // before mutating anything.
    for (final batch in product.batches) {
      final take = byId[batch.id];
      if (take != null && take > batch.remainingQuantity) {
        throw InsufficientStockException(
          requested: take,
          available: batch.remainingQuantity,
        );
      }
    }

    return _replace(
      product.copyWith(
        batches: product.batches.map((batch) {
          final take = byId[batch.id];
          return take == null
              ? batch
              : batch.copyWith(remainingQuantity: batch.remainingQuantity - take);
        }).toList(),
      ),
    );
  }
}
