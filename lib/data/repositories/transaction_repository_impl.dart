import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/data/data_sources/remote/transaction_api.dart';
import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({required this.transactionApi});

  final TransactionApi transactionApi;

  @override
  Future<TransactionPage> list({
    required String storeId,
    TransactionType? type,
    DateTime? from,
    DateTime? to,
    String? productId,
    PaymentMethod? paymentMethod,
    String? query,
    int page = 1,
    int limit = Constants.defaultPageSize,
  }) async {
    final response = await transactionApi.listTransactions(
      {
        if (type != null) 'type': type.wireValue,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        'productId': ?productId,
        if (paymentMethod != null) 'paymentMethod': paymentMethod.wireValue,
        if (query != null && query.isNotEmpty) 'q': query,
      },
      storeId: storeId,
      page: page,
      limit: limit,
    );
    return response.data?.toEntity() ?? TransactionPage.empty;
  }

  @override
  Future<Transaction> byId(String id) async {
    final response = await transactionApi.getTransaction(id);
    return response.data!.toEntity();
  }

  @override
  Future<Transaction> create(TransactionDraft draft) async {
    final response = await transactionApi.createTransaction(
      TransactionRequest.fromDraft(draft),
    );
    return response.data!.toEntity();
  }

  @override
  Future<Transaction> amend(
    String id,
    TransactionDraft draft, {
    required DateTime expectedUpdatedAt,
  }) async {
    final response = await transactionApi.amendTransaction(
      id,
      TransactionRequest.fromDraft(draft, expectedUpdatedAt: expectedUpdatedAt),
    );
    return response.data!.toEntity();
  }

  @override
  Future<Transaction> remove(
    String id, {
    required DateTime expectedUpdatedAt,
  }) async {
    final response = await transactionApi.removeTransaction(
      id,
      RemoveTransactionRequest.at(expectedUpdatedAt),
    );
    return response.data!.toEntity();
  }

  @override
  Future<TransactionPreview> preview(TransactionDraft draft) async {
    final response = await transactionApi.previewTransaction(
      TransactionRequest.fromDraft(draft),
    );
    return response.data!.toEntity();
  }
}

class FeePresetRepositoryImpl implements FeePresetRepository {
  FeePresetRepositoryImpl({required this.transactionApi});

  final TransactionApi transactionApi;

  @override
  Future<List<FeePreset>> presetsFor(String storeId) async {
    final response = await transactionApi.listFeePresets(storeId: storeId);
    return (response.data ?? const []).map((row) => row.toEntity()).toList();
  }

  @override
  Future<FeePreset> create(FeePreset preset) async {
    final response = await transactionApi.createFeePreset(
      FeePresetRequest.fromPreset(preset),
    );
    return response.data!.toEntity();
  }

  @override
  Future<FeePreset> update(FeePreset preset) async {
    final response = await transactionApi.updateFeePreset(
      preset.id,
      FeePresetRequest.fromPreset(preset),
    );
    return response.data!.toEntity();
  }

  @override
  Future<void> remove(String id) => transactionApi.removeFeePreset(id);
}
