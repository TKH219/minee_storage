import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:mine_storage/data/models/models.dart';

part 'product_api.g.dart';

@RestApi()
abstract class ProductApi {
  factory ProductApi(Dio dio, {String? baseUrl}) = _ProductApi;

  @GET('/products')
  Future<BaseResponse<PagedProductsModel>> getProducts(
    @Queries() Map<String, dynamic> filter, {
    @Query('storeId') required String storeId,
    @Query('page') required int page,
    @Query('limit') required int limit,
  });

  @GET('/products/{id}')
  Future<BaseResponse<ProductModel>> getProduct(
    @Path('id') String id, {
    @Query('storeId') required String storeId,
  });

  @GET('/products/barcode/{barcode}')
  Future<BaseResponse<ProductModel>> getProductByBarcode(
    @Path('barcode') String barcode, {
    @Query('storeId') required String storeId,
  });

  @GET('/products/{id}/holdings')
  Future<BaseResponse<List<StoreHoldingModel>>> getHoldings(@Path('id') String id);

  @GET('/products/categories')
  Future<BaseResponse<List<String>>> getCategories();

  @POST('/products')
  Future<BaseResponse<ProductModel>> createProduct(@Body() ProductRequest body);

  @PATCH('/products/{id}')
  Future<BaseResponse<ProductModel>> updateProduct(
    @Path('id') String id,
    @Body() ProductRequest body,
  );

  @POST('/products/{id}/archive')
  Future<BaseResponse<ProductModel>> archiveProduct(
    @Path('id') String id, {
    @Query('storeId') required String storeId,
  });

  @POST('/products/{id}/restore')
  Future<BaseResponse<ProductModel>> restoreProduct(
    @Path('id') String id, {
    @Query('storeId') required String storeId,
  });

  @POST('/products/{id}/batches')
  Future<BaseResponse<ProductModel>> addBatch(
    @Path('id') String id,
    @Body() BatchRequest body,
  );

  @PATCH('/products/{id}/batches/{batchId}')
  Future<BaseResponse<ProductModel>> updateBatch(
    @Path('id') String id,
    @Path('batchId') String batchId,
    @Body() BatchRequest body,
  );

  @POST('/products/{id}/batches/{batchId}/archive')
  Future<BaseResponse<ProductModel>> archiveBatch(
    @Path('id') String id,
    @Path('batchId') String batchId, {
    @Query('storeId') required String storeId,
  });
}
