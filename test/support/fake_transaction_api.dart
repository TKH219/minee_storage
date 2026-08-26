import 'package:dio/dio.dart';

import 'package:mine_storage/data/data_sources/remote/transaction_api.dart';
import 'package:mine_storage/data/models/models.dart';

/// Stands in for the Edge Function. Records what was sent so a test can assert
/// on the wire shape, and can be told to fail with a given business code.
class FakeTransactionApi implements TransactionApi {
  TransactionModel? transaction;
  TransactionPageModel? page;
  TransactionPreviewModel? previewModel;
  List<FeePresetModel> presets = const [];

  DioException? failWith;

  TransactionRequest? lastCreate;
  TransactionRequest? lastAmend;
  TransactionRequest? lastPreview;
  RemoveTransactionRequest? lastRemove;
  Map<String, dynamic>? lastFilter;
  String? lastId;

  void _maybeFail() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<BaseResponse<TransactionPageModel>> listTransactions(
    Map<String, dynamic> filter, {
    required String storeId,
    required int page,
    required int limit,
  }) async {
    _maybeFail();
    lastFilter = {...filter, 'storeId': storeId, 'page': page, 'limit': limit};
    return BaseResponse(code: 'OK', data: this.page);
  }

  @override
  Future<BaseResponse<TransactionModel>> getTransaction(String id) async {
    _maybeFail();
    lastId = id;
    return BaseResponse(code: 'OK', data: transaction);
  }

  @override
  Future<BaseResponse<TransactionModel>> createTransaction(
    TransactionRequest body,
  ) async {
    _maybeFail();
    lastCreate = body;
    return BaseResponse(code: 'OK', data: transaction);
  }

  @override
  Future<BaseResponse<TransactionPreviewModel>> previewTransaction(
    TransactionRequest body,
  ) async {
    _maybeFail();
    lastPreview = body;
    return BaseResponse(code: 'OK', data: previewModel);
  }

  @override
  Future<BaseResponse<TransactionModel>> amendTransaction(
    String id,
    TransactionRequest body,
  ) async {
    _maybeFail();
    lastId = id;
    lastAmend = body;
    return BaseResponse(code: 'OK', data: transaction);
  }

  @override
  Future<BaseResponse<TransactionModel>> removeTransaction(
    String id,
    RemoveTransactionRequest body,
  ) async {
    _maybeFail();
    lastId = id;
    lastRemove = body;
    return BaseResponse(code: 'OK', data: transaction);
  }

  @override
  Future<BaseResponse<List<FeePresetModel>>> listFeePresets({
    required String storeId,
  }) async {
    _maybeFail();
    return BaseResponse(code: 'OK', data: presets);
  }

  @override
  Future<BaseResponse<FeePresetModel>> createFeePreset(
    FeePresetRequest body,
  ) async {
    _maybeFail();
    return BaseResponse(code: 'OK', data: presets.first);
  }

  @override
  Future<BaseResponse<FeePresetModel>> updateFeePreset(
    String id,
    FeePresetRequest body,
  ) async {
    _maybeFail();
    return BaseResponse(code: 'OK', data: presets.first);
  }

  @override
  Future<BaseResponse<FeePresetModel>> removeFeePreset(String id) async {
    _maybeFail();
    return BaseResponse(code: 'OK', data: presets.first);
  }
}
