import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/data_sources/remote/product_api.dart';
import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({required this.productApi});

  final ProductApi productApi;

  @override
  Future<PagedProducts> getProducts({
    required String storeId,
    required ProductFilter filter,
    required int page,
    int limit = Constants.defaultPageSize,
  }) async {
    final response = await productApi.getProducts(
      filter.toQueryParameters(),
      storeId: storeId,
      page: page,
      limit: limit,
    );
    return response.data!.toEntity();
  }

  @override
  Future<ProductEntity> getProduct(String id, {required String storeId}) async {
    final response = await productApi.getProduct(id, storeId: storeId);
    return response.data!.toEntity();
  }

  /// The only try/catch in the data layer, and deliberately narrow: a 404 here
  /// is not a failure, it is the "no such barcode" answer the scanner needs.
  @override
  Future<ProductEntity?> findByBarcode(String barcode, {required String storeId}) async {
    try {
      final response = await productApi.getProductByBarcode(barcode, storeId: storeId);
      return response.data!.toEntity();
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<String>> getCategories() async {
    final response = await productApi.getCategories();
    return response.data ?? const [];
  }

  @override
  Future<ProductEntity> createProduct(
    ProductDraft draft, {
    required String storeId,
  }) async {
    final response = await productApi.createProduct(
      ProductRequest.fromDraft(draft, storeId: storeId),
    );
    return response.data!.toEntity();
  }

  @override
  Future<ProductEntity> updateProduct(
    String id,
    ProductDraft draft, {
    required String storeId,
  }) async {
    final response = await productApi.updateProduct(
      id,
      ProductRequest.fromDraft(draft, storeId: storeId),
    );
    return response.data!.toEntity();
  }

  @override
  Future<ProductEntity> archiveProduct(String id, {required String storeId}) async {
    final response = await productApi.archiveProduct(id, storeId: storeId);
    return response.data!.toEntity();
  }

  @override
  Future<ProductEntity> restoreProduct(String id, {required String storeId}) async {
    final response = await productApi.restoreProduct(id, storeId: storeId);
    return response.data!.toEntity();
  }

  @override
  Future<ProductEntity> addBatch(String productId, BatchDraft draft) async {
    final response = await productApi.addBatch(productId, BatchRequest.fromDraft(draft));
    return response.data!.toEntity();
  }

  @override
  Future<ProductEntity> updateBatch(
    String productId,
    String batchId,
    BatchDraft draft,
  ) async {
    final response = await productApi.updateBatch(
      productId,
      batchId,
      BatchRequest.fromDraft(draft),
    );
    return response.data!.toEntity();
  }

  @override
  Future<ProductEntity> archiveBatch(
    String productId,
    String batchId, {
    required String storeId,
  }) async {
    final response = await productApi.archiveBatch(productId, batchId, storeId: storeId);
    return response.data!.toEntity();
  }

  @override
  Future<ProductEntity> consume(
    String productId,
    List<BatchAllocation> allocations, {
    required String storeId,
  }) async {
    final response = await productApi.consume(
      productId,
      ConsumeRequest.fromAllocations(allocations, storeId: storeId),
    );
    return response.data!.toEntity();
  }
}
