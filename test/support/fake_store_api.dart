import 'package:mine_storage/data/data_sources/remote/store_api.dart';
import 'package:mine_storage/data/models/models.dart';

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
  Future<dynamic> insertStore(CreateStoreRequest request) async {
    inserted = request.toJson();
    return [
      {'id': 's-new', ...inserted},
    ];
  }

  @override
  Future<dynamic> fetchCategories({
    String deletedAt = 'is.null',
    String select = '*',
    String order = 'sort_order.asc',
  }) async {
    lastQuery['categories_order'] = order;
    return categoryRows;
  }

  @override
  Future<dynamic> fetchCurrencies({
    String deletedAt = 'is.null',
    String select = '*',
    String order = 'sort_order.asc',
  }) async {
    lastQuery['currencies_order'] = order;
    return currencyRows;
  }
}
