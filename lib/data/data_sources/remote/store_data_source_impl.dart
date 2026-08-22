import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/data_sources/remote/store_api.dart';
import 'package:mine_storage/data/data_sources/remote/store_data_source.dart';
import 'package:mine_storage/data/models/models.dart';

class StoreDataSourceImpl implements StoreDataSource {
  StoreDataSourceImpl(this._api, {required String? Function() currentUserId})
    : _currentUserId = currentUserId;

  final StoreApi _api;
  final String? Function() _currentUserId;

  @override
  String? get currentUserId => _currentUserId();

  @override
  Future<List<StoreModel>> fetchMine(String ownerId) {
    return _api.fetchStores(ownerId: 'eq.$ownerId', deletedAt: 'is.null');
  }

  @override
  Future<List<StoreCategoryModel>> fetchCategories() => _api.fetchCategories();

  @override
  Future<List<CurrencyModel>> fetchCurrencies() => _api.fetchCurrencies();

  @override
  Future<StoreModel> insertStore(CreateStoreRequest request) async {
    // `Prefer: return=representation` makes PostgREST echo the created rows.
    final rows = await _api.insertStore(request);
    if (rows.isEmpty) {
      throw const ServerException(message: 'The shop could not be created. Please try again.');
    }
    return rows.first;
  }
}
