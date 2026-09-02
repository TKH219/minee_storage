import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:mine_storage/data/models/models.dart';

part 'transaction_api.g.dart';

@RestApi()
abstract class TransactionApi {
  factory TransactionApi(Dio dio, {String? baseUrl}) = _TransactionApi;

  @GET('/transactions')
  Future<BaseResponse<TransactionPageModel>> listTransactions(
    @Queries() Map<String, dynamic> filter, {
    @Query('storeId') required String storeId,
    @Query('page') required int page,
    @Query('limit') required int limit,
  });

  @GET('/transactions/{id}')
  Future<BaseResponse<TransactionModel>> getTransaction(@Path('id') String id);

  @POST('/transactions')
  Future<BaseResponse<TransactionModel>> createTransaction(
    @Body() TransactionRequest body,
  );

  @POST('/transactions/preview')
  Future<BaseResponse<TransactionPreviewModel>> previewTransaction(
    @Body() TransactionRequest body,
  );

  @PUT('/transactions/{id}')
  Future<BaseResponse<TransactionModel>> amendTransaction(
    @Path('id') String id,
    @Body() TransactionRequest body,
  );

  @DELETE('/transactions/{id}')
  Future<BaseResponse<TransactionModel>> removeTransaction(
    @Path('id') String id,
    @Body() RemoveTransactionRequest body,
  );

  @GET('/fee-presets')
  Future<BaseResponse<List<FeePresetModel>>> listFeePresets({
    @Query('storeId') required String storeId,
  });

  @POST('/fee-presets')
  Future<BaseResponse<FeePresetModel>> createFeePreset(
    @Body() FeePresetRequest body,
  );

  @PATCH('/fee-presets/{id}')
  Future<BaseResponse<FeePresetModel>> updateFeePreset(
    @Path('id') String id,
    @Body() FeePresetRequest body,
  );

  @DELETE('/fee-presets/{id}')
  Future<BaseResponse<FeePresetModel>> removeFeePreset(@Path('id') String id);
}
