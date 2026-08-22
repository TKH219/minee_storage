import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/data_sources/remote/store_api.dart';
import 'package:mine_storage/data/data_sources/remote/store_data_source.dart';

class StoreDataSourceImpl implements StoreDataSource {
  StoreDataSourceImpl(this._api, {required String? Function() currentUserId})
    : _currentUserId = currentUserId;

  final StoreApi _api;
  final String? Function() _currentUserId;

  @override
  String? get currentUserId => _currentUserId();

  @override
  Future<List<Map<String, dynamic>>> fetchMine(String ownerId) async {
    return _rows(await _api.fetchStores(ownerId: 'eq.$ownerId', deletedAt: 'is.null'));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async =>
      _rows(await _api.fetchCategories());

  @override
  Future<List<Map<String, dynamic>>> fetchCurrencies() async =>
      _rows(await _api.fetchCurrencies());

  @override
  Future<Map<String, dynamic>> insertStore(Map<String, dynamic> values) async {
    // `Prefer: return=representation` makes PostgREST echo the created rows.
    final rows = _rows(await _api.insertStore(values));
    if (rows.isEmpty) {
      throw const ServerException(message: 'The shop could not be created. Please try again.');
    }
    return rows.first;
  }

  List<Map<String, dynamic>> _rows(dynamic body) {
    if (body is! List) return const [];
    return body.cast<Map<String, dynamic>>();
  }
}
