import 'package:mine_storage/domain/entities/entities.dart';

/// A product belongs to a user, but its stock belongs to a store — so every
/// call names the store whose batches and derived figures it wants back.
abstract class ProductRepository {
  Future<PagedProducts> getProducts({
    required String storeId,
    required ProductFilter filter,
    required int page,
    int limit,
  });

  Future<ProductEntity> getProduct(String id, {required String storeId});

  /// Null when no product of the caller's carries this barcode.
  Future<ProductEntity?> findByBarcode(String barcode, {required String storeId});

  /// Distinct values the caller has already used, for the form's autocomplete.
  Future<List<String>> getCategories();

  Future<ProductEntity> createProduct(ProductDraft draft, {required String storeId});

  Future<ProductEntity> updateProduct(
    String id,
    ProductDraft draft, {
    required String storeId,
  });

  Future<ProductEntity> archiveProduct(String id, {required String storeId});

  Future<ProductEntity> restoreProduct(String id, {required String storeId});

  Future<ProductEntity> addBatch(String productId, BatchDraft draft);

  Future<ProductEntity> updateBatch(String productId, String batchId, BatchDraft draft);

  Future<ProductEntity> archiveBatch(
    String productId,
    String batchId, {
    required String storeId,
  });

  /// Applies an allocation already resolved by `FefoAllocator`. All or nothing.
  Future<ProductEntity> consume(
    String productId,
    List<BatchAllocation> allocations, {
    required String storeId,
  });
}
