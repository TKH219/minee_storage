import 'package:mine_storage/data/data_sources/remote/store_data_source.dart';
import 'package:mine_storage/data/models/models.dart';

class FakeStoreDataSource implements StoreDataSource {
  FakeStoreDataSource({
    this.currentId = 'uid-1',
    this.categoryRows = const [],
    this.currencyRows = const [],
    this.storeRows = const [],
    this.error,
  });

  String? currentId;
  List<Map<String, dynamic>> categoryRows;
  List<Map<String, dynamic>> currencyRows;
  List<Map<String, dynamic>> storeRows;
  Object? error;

  final List<String> calls = [];
  Map<String, dynamic> inserted = {};

  void _maybeThrow() {
    if (error != null) throw error!;
  }

  @override
  String? get currentUserId => currentId;

  @override
  Future<List<Map<String, dynamic>>> fetchMine(String ownerId) async {
    calls.add('fetchMine:$ownerId');
    _maybeThrow();
    return storeRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    calls.add('fetchCategories');
    _maybeThrow();
    return categoryRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCurrencies() async {
    calls.add('fetchCurrencies');
    _maybeThrow();
    return currencyRows;
  }

  @override
  Future<Map<String, dynamic>> insertStore(CreateStoreRequest request) async {
    calls.add('insertStore:${request.name}');
    _maybeThrow();
    inserted = request.toJson();
    return {'id': 's-new', ...inserted};
  }
}
