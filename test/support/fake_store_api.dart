import 'package:mine_storage/data/data_sources/remote/store_api.dart';
import 'package:mine_storage/data/models/models.dart';

import 'model_fixtures.dart';

class FakeStoreApi implements StoreApi {
  FakeStoreApi({
    this.storeRows = const [],
    this.categoryRows = const [],
    this.currencyRows = const [],
  });

  List<StoreModel> storeRows;
  List<StoreCategoryModel> categoryRows;
  List<CurrencyModel> currencyRows;

  final Map<String, String> lastQuery = {};
  Map<String, dynamic> inserted = {};
  StoreModel? insertResult;

  @override
  Future<List<StoreModel>> fetchStores({
    required String ownerId,
    required String deletedAt,
    String select = '*',
    String order = 'created_at.asc',
  }) async {
    lastQuery
      ..['owner_id'] = ownerId
      ..['deleted_at'] = deletedAt
      ..['order'] = order;
    return storeRows;
  }

  @override
  Future<List<StoreModel>> insertStore(CreateStoreRequest request) async {
    inserted = request.toJson();
    return [insertResult ?? storeModelFixture(id: 's-new', name: request.name)];
  }

  @override
  Future<List<StoreCategoryModel>> fetchCategories({
    String deletedAt = 'is.null',
    String select = '*',
    String order = 'sort_order.asc',
  }) async {
    lastQuery['categories_order'] = order;
    return categoryRows;
  }

  @override
  Future<List<CurrencyModel>> fetchCurrencies({
    String deletedAt = 'is.null',
    String select = '*',
    String order = 'sort_order.asc',
  }) async {
    lastQuery['currencies_order'] = order;
    return currencyRows;
  }
}
