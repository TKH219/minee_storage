import 'package:mine_storage/data/data_sources/remote/store_api.dart';

class FakeStoreApi implements StoreApi {
  FakeStoreApi({
    this.storeRows = const [],
    this.categoryRows = const [],
    this.currencyRows = const [],
  });

  List<Map<String, dynamic>> storeRows;
  List<Map<String, dynamic>> categoryRows;
  List<Map<String, dynamic>> currencyRows;

  final Map<String, String> lastQuery = {};
  Map<String, dynamic> inserted = {};

  @override
  Future<dynamic> fetchStores({
    required String ownerId,
    required String isArchived,
    String select = '*',
    String order = 'created_at.asc',
  }) async {
    lastQuery
      ..['owner_id'] = ownerId
      ..['is_archived'] = isArchived
      ..['order'] = order;
    return storeRows;
  }

  @override
  Future<dynamic> insertStore(Map<String, dynamic> values) async {
    inserted = values;
    return [
      {'id': 's-new', ...values},
    ];
  }

  @override
  Future<dynamic> fetchCategories({
    String select = '*',
    String order = 'sort_order.asc',
  }) async {
    lastQuery['categories_order'] = order;
    return categoryRows;
  }

  @override
  Future<dynamic> fetchCurrencies({
    String select = '*',
    String order = 'sort_order.asc',
  }) async {
    lastQuery['currencies_order'] = order;
    return currencyRows;
  }
}
