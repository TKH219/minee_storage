import 'package:decimal/decimal.dart';

import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';

/// In-memory stand-in used by the tests and, until the products tables carry
/// real rows, by the app behind `AppFeatures.fakeProductsEnabled`.
class FakeProductRepository implements ProductRepository {
  /// [latency] fakes network delay so loading states are visible on device.
  /// Widget tests pass [Duration.zero] — an indeterminate progress indicator
  /// schedules frames forever, so `pumpAndSettle` never returns while one is
  /// on screen.
  FakeProductRepository({
    this.latency = const Duration(milliseconds: 250),
    this.seedStoreId = 'store-a',
  }) {
    _products.addAll(_seed());
  }

  final Duration latency;
  final String seedStoreId;

  final List<ProductEntity> _products = [];
  int _nextId = 100;

  List<ProductEntity> _seed() {
    final now = DateTime.now();

    ProductBatchEntity batch(
      String id,
      String productId,
      String code,
      String price,
      String quantity,
      String remaining,
      DateTime purchased,
      DateTime? expiry, {
      String? storageLocation,
    }) {
      return ProductBatchEntity(
        id: id,
        productId: productId,
        storeId: seedStoreId,
        batchCode: code,
        purchasedAt: purchased,
        unitPrice: Decimal.parse(price),
        expiryDate: expiry,
        initialQuantity: Decimal.parse(quantity),
        remainingQuantity: Decimal.parse(remaining),
        storageLocation: storageLocation,
        createdAt: purchased,
        updatedAt: purchased,
      );
    }

    return [
      ProductEntity(
        id: 'p1',
        name: 'Olive oil 1L',
        unit: ProductUnit.litre,
        barcode: '8934567890123',
        brand: 'Basso',
        category: 'Pantry',
        notes: 'Cold pressed',
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 2)),
        batches: [
          batch('b1', 'p1', '#B-0001', '11.50', '6', '2',
              now.subtract(const Duration(days: 40)), now.add(const Duration(days: 12)),
              storageLocation: 'Shelf A'),
          batch('b2', 'p1', '#B-0002', '12.75', '6', '6',
              now.subtract(const Duration(days: 5)), now.add(const Duration(days: 200)),
              storageLocation: 'Shelf A'),
        ],
      ),
      ProductEntity(
        id: 'p2',
        name: 'Whole milk 1L',
        unit: ProductUnit.litre,
        barcode: '8931112223334',
        brand: 'Vinamilk',
        category: 'Fridge',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 1)),
        batches: [
          batch('b3', 'p2', '#B-0001', '1.20', '12', '9',
              now.subtract(const Duration(days: 6)), now.subtract(const Duration(days: 1)),
              storageLocation: 'Fridge door'),
        ],
      ),
      ProductEntity(
        id: 'p3',
        name: 'Basmati rice 5kg',
        unit: ProductUnit.kg,
        category: 'Pantry',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 120)),
        batches: [
          batch('b4', 'p3', '#B-0001', '9.00', '2', '2',
              now.subtract(const Duration(days: 120)), now.add(const Duration(days: 400)),
              storageLocation: 'Floor bin'),
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

  /// The API answers with only the viewed store's batches, so the fake has to
  /// do the same or every derived figure would span stores.
  ProductEntity _scopedTo(String storeId, ProductEntity product) => product.copyWith(
    batches: product.batches.where((batch) => batch.storeId == storeId).toList(),
  );

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
      ProductQuickFilter.archived => product.archived,
      ProductQuickFilter.all => !product.archived,
      ProductQuickFilter.expiringSoon =>
        !product.archived && product.statusOn(now).isExpiringSoon,
      ProductQuickFilter.expired =>
        !product.archived && product.statusOn(now) == ExpiryStatus.expired,
    };
  }

  @override
  Future<PagedProducts> getProducts({
    required String storeId,
    required ProductFilter filter,
    required int page,
    int limit = Constants.defaultPageSize,
  }) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    final matched = _products
        .map((product) => _scopedTo(storeId, product))
        .where((product) => _matches(product, filter, now))
        .toList();
    final start = (page - 1) * limit;
    if (start >= matched.length) return const PagedProducts(items: [], hasMore: false);
    final end = (start + limit).clamp(0, matched.length);
    return PagedProducts(items: matched.sublist(start, end), hasMore: end < matched.length);
  }

  @override
  Future<ProductEntity> getProduct(String id, {required String storeId}) async {
    await Future<void>.delayed(latency);
    return _scopedTo(storeId, _require(id));
  }

  @override
  Future<ProductEntity?> findByBarcode(String barcode, {required String storeId}) async {
    await Future<void>.delayed(latency);
    final index = _products.indexWhere(
      (product) => product.barcode == barcode && !product.archived,
    );
    return index == -1 ? null : _scopedTo(storeId, _products[index]);
  }

  @override
  Future<List<String>> getCategories() async {
    await Future<void>.delayed(latency);
    return _products.map((product) => product.category).whereType<String>().toSet().toList()
      ..sort();
  }

  @override
  Future<ProductEntity> createProduct(
    ProductDraft draft, {
    required String storeId,
  }) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    final product = ProductEntity(
      id: 'p${_nextId++}',
      name: draft.name,
      unit: draft.unit,
      createdAt: now,
      updatedAt: now,
      barcode: draft.barcode,
      brand: draft.brand,
      category: draft.category,
      notes: draft.notes,
      photoUrl: draft.photoUrl,
    );
    _products.insert(0, product);
    return product;
  }

  @override
  Future<ProductEntity> updateProduct(
    String id,
    ProductDraft draft, {
    required String storeId,
  }) async {
    await Future<void>.delayed(latency);
    return _scopedTo(
      storeId,
      _replace(
        _require(id).copyWith(
          name: draft.name,
          unit: draft.unit,
          barcode: draft.barcode,
          brand: draft.brand,
          category: draft.category,
          notes: draft.notes,
          photoUrl: draft.photoUrl,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Future<ProductEntity> archiveProduct(String id, {required String storeId}) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    return _scopedTo(
      storeId,
      _replace(_require(id).copyWith(deletedAt: now, updatedAt: now)),
    );
  }

  @override
  Future<ProductEntity> restoreProduct(String id, {required String storeId}) async {
    await Future<void>.delayed(latency);
    return _scopedTo(
      storeId,
      _replace(
        _require(id).copyWith(clearDeletedAt: true, updatedAt: DateTime.now()),
      ),
    );
  }

  @override
  Future<ProductEntity> addBatch(String productId, BatchDraft draft) async {
    await Future<void>.delayed(latency);
    final product = _require(productId);
    final now = DateTime.now();
    final batch = ProductBatchEntity(
      id: 'b${_nextId++}',
      productId: productId,
      storeId: draft.storeId,
      batchCode: '#B-${(product.batches.length + 1).toString().padLeft(4, '0')}',
      purchasedAt: draft.purchasedAt,
      unitPrice: draft.unitPrice,
      expiryDate: draft.expiryDate,
      initialQuantity: draft.initialQuantity,
      remainingQuantity: draft.remainingQuantity ?? draft.initialQuantity,
      supplier: draft.supplier,
      storageLocation: draft.storageLocation,
      note: draft.note,
      createdAt: now,
      updatedAt: now,
    );
    return _scopedTo(
      draft.storeId,
      _replace(product.copyWith(batches: [...product.batches, batch])),
    );
  }

  @override
  Future<ProductEntity> updateBatch(
    String productId,
    String batchId,
    BatchDraft draft,
  ) async {
    await Future<void>.delayed(latency);
    final product = _require(productId);
    return _scopedTo(
      draft.storeId,
      _replace(
        product.copyWith(
          batches: product.batches.map((batch) {
            if (batch.id != batchId) return batch;
            return batch.copyWith(
              purchasedAt: draft.purchasedAt,
              unitPrice: draft.unitPrice,
              expiryDate: draft.expiryDate,
              clearExpiryDate: draft.expiryDate == null,
              initialQuantity: draft.initialQuantity,
              remainingQuantity: draft.remainingQuantity ?? batch.remainingQuantity,
              supplier: draft.supplier,
              storageLocation: draft.storageLocation,
              note: draft.note,
              updatedAt: DateTime.now(),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Future<ProductEntity> archiveBatch(
    String productId,
    String batchId, {
    required String storeId,
  }) async {
    await Future<void>.delayed(latency);
    final product = _require(productId);
    return _scopedTo(
      storeId,
      _replace(
        product.copyWith(
          batches: product.batches
              .map((batch) => batch.id == batchId
                  ? batch.copyWith(deletedAt: DateTime.now())
                  : batch)
              .toList(),
        ),
      ),
    );
  }

  @override
  Future<ProductEntity> consume(
    String productId,
    List<BatchAllocation> allocations, {
    required String storeId,
  }) async {
    await Future<void>.delayed(latency);
    final product = _require(productId);
    final byId = {for (final a in allocations) a.batchId: a.quantity};

    // Mirrors the RPC's all-or-nothing rule: validate every allocation before
    // mutating anything.
    for (final batch in product.batches) {
      final take = byId[batch.id];
      if (take == null) continue;
      if (batch.storeId != storeId) {
        throw const BadRequestException(message: 'That batch is held in another store.');
      }
      if (take > batch.remainingQuantity) {
        throw InsufficientStockException(
          requested: take,
          available: batch.remainingQuantity,
        );
      }
    }

    return _scopedTo(
      storeId,
      _replace(
        product.copyWith(
          batches: product.batches.map((batch) {
            final take = byId[batch.id];
            return take == null
                ? batch
                : batch.copyWith(remainingQuantity: batch.remainingQuantity - take);
          }).toList(),
        ),
      ),
    );
  }
}
