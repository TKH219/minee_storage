import 'package:mine_storage/data/models/models.dart';

abstract class StoreDataSource {
  Future<List<Map<String, dynamic>>> fetchMine(String ownerId);

  Future<List<Map<String, dynamic>>> fetchCategories();

  Future<List<Map<String, dynamic>>> fetchCurrencies();

  Future<Map<String, dynamic>> insertStore(CreateStoreRequest request);

  String? get currentUserId;
}
