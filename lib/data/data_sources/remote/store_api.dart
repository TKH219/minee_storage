import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

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
  Future<dynamic> fetchStores({
    @Query('owner_id') required String ownerId,
    @Query('deleted_at') required String deletedAt,
    @Query('select') String select = '*',
    @Query('order') String order = 'created_at.asc',
  });

  @POST('/rest/v1/stores')
  @Headers({'Prefer': 'return=representation'})
  Future<dynamic> insertStore(@Body() Map<String, dynamic> values);

  @GET('/rest/v1/store_categories')
  Future<dynamic> fetchCategories({
    @Query('deleted_at') String deletedAt = 'is.null',
    @Query('select') String select = '*',
    @Query('order') String order = 'sort_order.asc',
  });

  @GET('/rest/v1/currencies')
  Future<dynamic> fetchCurrencies({
    @Query('deleted_at') String deletedAt = 'is.null',
    @Query('select') String select = '*',
    @Query('order') String order = 'sort_order.asc',
  });
}
