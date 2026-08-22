import 'package:mine_storage/data/data_sources/remote/store_data_source.dart';
import 'package:mine_storage/data/models/models.dart';

import 'model_fixtures.dart';

class FakeStoreDataSource implements StoreDataSource {
  FakeStoreDataSource({
    this.currentId = 'uid-1',
    this.categoryRows = const [],
    this.currencyRows = const [],
    this.storeRows = const [],
    this.error,
  });

  String? currentId;
  List<StoreCategoryModel> categoryRows;
  List<CurrencyModel> currencyRows;
  List<StoreModel> storeRows;
  Object? error;

  final List<String> calls = [];
  Map<String, dynamic> inserted = {};

  void _maybeThrow() {
    if (error != null) throw error!;
  }

  @override
  String? get currentUserId => currentId;

  @override
  Future<List<StoreModel>> fetchMine(String ownerId) async {
    calls.add('fetchMine:$ownerId');
    _maybeThrow();
    return storeRows;
  }

  @override
  Future<List<StoreCategoryModel>> fetchCategories() async {
    calls.add('fetchCategories');
    _maybeThrow();
    return categoryRows;
  }

  @override
  Future<List<CurrencyModel>> fetchCurrencies() async {
    calls.add('fetchCurrencies');
    _maybeThrow();
    return currencyRows;
  }

  @override
  Future<StoreModel> insertStore(CreateStoreRequest request) async {
    calls.add('insertStore:${request.name}');
    _maybeThrow();
    inserted = request.toJson();
    return storeModelFixture(id: 's-new', name: request.name);
  }
}
