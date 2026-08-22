import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import 'package:mine_storage/data/models/models.dart';

part 'store_api.g.dart';

/// Supabase PostgREST. Returns bare JSON arrays, not the `{code, message,
/// data}` envelope, so these endpoints do not use `BaseResponse`.
///
/// Filter values carry their own operator (`eq.`, `is.`) because that is
/// PostgREST's query grammar; the data source builds them.
@RestApi()
abstract class StoreApi {
  factory StoreApi(Dio dio, {String? baseUrl}) = _StoreApi;

  @GET('/rest/v1/stores')
  Future<List<StoreModel>> fetchStores({
    @Query('owner_id') required String ownerId,
    @Query('deleted_at') required String deletedAt,
    @Query('select') String select = '*',
    @Query('order') String order = 'created_at.asc',
  });

  @POST('/rest/v1/stores')
  @Headers({'Prefer': 'return=representation'})
  Future<List<StoreModel>> insertStore(@Body() CreateStoreRequest request);

  @GET('/rest/v1/store_categories')
  Future<List<StoreCategoryModel>> fetchCategories({
    @Query('deleted_at') String deletedAt = 'is.null',
    @Query('select') String select = '*',
    @Query('order') String order = 'sort_order.asc',
  });

  @GET('/rest/v1/currencies')
  Future<List<CurrencyModel>> fetchCurrencies({
    @Query('deleted_at') String deletedAt = 'is.null',
    @Query('select') String select = '*',
    @Query('order') String order = 'sort_order.asc',
  });
}
