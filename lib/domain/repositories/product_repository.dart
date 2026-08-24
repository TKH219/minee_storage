import 'package:mine_storage/domain/entities/entities.dart';

abstract class ProductRepository {
  Future<PagedProducts> getProducts({
    required ProductFilter filter,
    required int page,
    int limit,
  });

  Future<ProductEntity> getProduct(String id);

  /// Null when no product of the caller's carries this barcode.
  Future<ProductEntity?> findByBarcode(String barcode);

  Future<List<String>> getCategories();

  Future<ProductEntity> createProduct(ProductDraft draft);

  Future<ProductEntity> updateProduct(String id, ProductDraft draft);

  Future<ProductEntity> archiveProduct(String id);

  Future<ProductEntity> restoreProduct(String id);

  Future<ProductEntity> addBatch(String productId, BatchDraft draft);

  Future<ProductEntity> updateBatch(String productId, String batchId, BatchDraft draft);

  Future<ProductEntity> archiveBatch(String productId, String batchId);

  /// Applies an allocation already resolved by `FefoAllocator`. All or nothing.
  Future<ProductEntity> consume(String productId, List<BatchAllocation> allocations);
}
